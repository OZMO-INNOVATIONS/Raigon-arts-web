import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:remixicon/remixicon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 1: PULSING RED RECORDING DOT
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(
      begin: 0.65,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: _opacityAnim.value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 2: LIVE RECORDING EQUALIZER WAVEFORM
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedRecordingWaveform extends StatefulWidget {
  const _AnimatedRecordingWaveform({this.barCount = 14});
  final int barCount;

  @override
  State<_AnimatedRecordingWaveform> createState() =>
      _AnimatedRecordingWaveformState();
}

class _AnimatedRecordingWaveformState extends State<_AnimatedRecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const List<double> _baseHeights = [
    0.35,
    0.70,
    0.45,
    0.90,
    0.60,
    0.85,
    0.40,
    0.95,
    0.50,
    0.80,
    0.65,
    0.40,
    0.75,
    0.30,
    0.85,
    0.55,
    0.90,
    0.45,
    0.70,
    0.35,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress = _ctrl.value;
        final count = widget.barCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(count, (i) {
            final base = _baseHeights[i % _baseHeights.length];
            final wave =
                (math.sin((progress * 2 * math.pi) + (i * 0.7)) + 1) / 2;
            final heightFactor = (base * 0.5 + wave * 0.5).clamp(0.2, 1.0);
            final barHeight = 6.0 + (heightFactor * 18.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.0,
              height: barHeight,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFEF4444),
                  const Color(0xFFF59E0B),
                  wave,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 3: SCRUBBABLE / ANIMATED PLAYBACK AUDIO WAVEFORM
// ─────────────────────────────────────────────────────────────────────────────
class ScrubbableAudioWaveform extends StatelessWidget {
  const ScrubbableAudioWaveform({
    super.key,
    required this.progress, // 0.0 to 1.0
    required this.onSeek,
    this.barCount = 28,
    this.height = 28,
  });

  final double progress;
  final ValueChanged<double>? onSeek;
  final int barCount;
  final double height;

  static const List<double> _waveformPattern = [
    0.30,
    0.45,
    0.75,
    0.55,
    0.90,
    0.40,
    0.85,
    0.65,
    0.95,
    0.50,
    0.80,
    0.60,
    0.70,
    0.90,
    0.45,
    0.75,
    0.85,
    0.35,
    0.95,
    0.60,
    0.80,
    0.50,
    0.70,
    0.40,
    0.85,
    0.55,
    0.65,
    0.30,
    0.75,
    0.40,
    0.90,
    0.50,
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Dynamically compute bar count based on available width
        final targetBars = math.min(
          barCount,
          math.max(12, (availableWidth / 7).floor()),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (details) {
                  final localX = details.localPosition.dx.clamp(
                    0.0,
                    availableWidth,
                  );
                  onSeek!(localX / availableWidth);
                },
          onTapDown: onSeek == null
              ? null
              : (details) {
                  final localX = details.localPosition.dx.clamp(
                    0.0,
                    availableWidth,
                  );
                  onSeek!(localX / availableWidth);
                },
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(targetBars, (i) {
                final barRatio = (i + 1) / targetBars;
                final isPlayed = barRatio <= clampedProgress;
                final rawHeight = _waveformPattern[i % _waveformPattern.length];
                final barH = 5.0 + (rawHeight * (height - 8));

                return Container(
                  width: 3.0,
                  height: barH,
                  decoration: BoxDecoration(
                    color: isPlayed
                        ? AppColors.gold
                        : (p.isDark
                              ? const Color(0xFF454760)
                              : const Color(0xFFDDD9CD)),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 4: ADAPTIVE ACTION SELECTOR (RECORD VOICE + UPLOAD AUDIO TILES)
// ─────────────────────────────────────────────────────────────────────────────
class AppAudioActionSelector extends StatefulWidget {
  const AppAudioActionSelector({
    super.key,
    required this.onRecordVoice,
    required this.onUploadAudio,
    this.recordLabel = 'Record Voice',
    this.recordSubtitle = 'Tap to start live memo',
    this.uploadLabel = 'Upload Audio',
    this.uploadSubtitle = 'MP3, WAV, AAC, M4A',
  });

  final VoidCallback onRecordVoice;
  final VoidCallback onUploadAudio;
  final String recordLabel;
  final String recordSubtitle;
  final String uploadLabel;
  final String uploadSubtitle;

  @override
  State<AppAudioActionSelector> createState() => _AppAudioActionSelectorState();
}

class _AppAudioActionSelectorState extends State<AppAudioActionSelector> {
  bool _recordHovered = false;
  bool _uploadHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow screens (mobile): stacked vertically with full tap targets
        // Wide screens (web / desktop): side-by-side balanced tiles
        final isCompact = constraints.maxWidth < 440;

        final recordTile = MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _recordHovered = true),
          onExit: (_) => setState(() => _recordHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _recordHovered
                  ? AppColors.gold.withValues(alpha: p.isDark ? 0.16 : 0.12)
                  : (p.isDark
                        ? const Color(0xFF26242E)
                        : const Color(0xFFFDFBF7)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _recordHovered
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: p.isDark ? 0.45 : 0.35),
                width: _recordHovered ? 1.5 : 1.2,
              ),
              boxShadow: _recordHovered
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onRecordVoice,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      // Glowing Mic Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          RemixIcons.mic_line,
                          size: 19,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.recordLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'MIC',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.gold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.recordSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        RemixIcons.arrow_right_s_line,
                        size: 18,
                        color: _recordHovered ? AppColors.gold : p.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final uploadTile = MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _uploadHovered = true),
          onExit: (_) => setState(() => _uploadHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _uploadHovered
                  ? (p.isDark
                        ? const Color(0xFF2C2F48)
                        : const Color(0xFFF7F5EE))
                  : (p.isDark
                        ? const Color(0xFF222438)
                        : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _uploadHovered
                    ? p.textPrimary.withValues(alpha: 0.5)
                    : p.border,
                width: _uploadHovered ? 1.5 : 1.2,
              ),
              boxShadow: _uploadHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: p.isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onUploadAudio,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      // Upload Cloud Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: p.chipFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.border, width: 1),
                        ),
                        child: Icon(
                          RemixIcons.upload_cloud_2_line,
                          size: 19,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.uploadLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.chipFill,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: p.border,
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    'FILE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: p.textMuted,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.uploadSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        RemixIcons.arrow_right_s_line,
                        size: 18,
                        color: _uploadHovered ? p.textPrimary : p.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (isCompact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [recordTile, const SizedBox(height: 10), uploadTile],
          );
        }

        return Row(
          children: [
            Expanded(child: recordTile),
            const SizedBox(width: 12),
            Expanded(child: uploadTile),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 5: LIVE RECORDING STUDIO (PULSING RED + EQUALIZER + DONE + CANCEL)
// ─────────────────────────────────────────────────────────────────────────────
class AppLiveRecordingStudio extends StatelessWidget {
  const AppLiveRecordingStudio({
    super.key,
    required this.recordingSeconds,
    required this.onStopAndAttach,
    required this.onCancel,
  });

  final int recordingSeconds;
  final VoidCallback onStopAndAttach;
  final VoidCallback onCancel;

  static String formatSeconds(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.isDark ? const Color(0xFF2E1C22) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing Dot & REC badge
              const _PulsingRedDot(),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'REC',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Timer
              Text(
                formatSeconds(recordingSeconds),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 10),

              // Animated Soundwave
              Expanded(
                child: Center(
                  child: _AnimatedRecordingWaveform(
                    barCount: isNarrow ? 10 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Done / Attach Button
              InkWell(
                onTap: onStopAndAttach,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Discard / Cancel Button
              Tooltip(
                message: 'Cancel recording',
                child: InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: p.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 6: ATTACHED AUDIO PLAYBACK DECK (PLAYER + WAVEFORM + ACTIONS)
// ─────────────────────────────────────────────────────────────────────────────
class AppAudioPlayerDeck extends StatelessWidget {
  const AppAudioPlayerDeck({
    super.key,
    required this.isPlaying,
    required this.durationSeconds,
    required this.onTogglePlay,
    required this.onDelete,
    this.onReplace,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.onSeek,
    this.title = 'Voice Message Attached',
    this.sourceTag = 'AUDIO MEMO',
  });

  final bool isPlaying;
  final int durationSeconds;
  final VoidCallback onTogglePlay;
  final VoidCallback onDelete;
  final VoidCallback? onReplace;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration>? onSeek;
  final String title;
  final String sourceTag;

  static String formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    // Compute progress (0.0 to 1.0)
    final effectiveTotalSec = totalDuration.inSeconds > 0
        ? totalDuration.inSeconds
        : (durationSeconds > 0 ? durationSeconds : 1);
    final progress =
        (currentPosition.inMilliseconds / (effectiveTotalSec * 1000)).clamp(
          0.0,
          1.0,
        );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.gold.withValues(alpha: p.isDark ? 0.12 : 0.07)
            : (p.isDark ? const Color(0xFF22243A) : const Color(0xFFFCFBF7)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: p.isDark ? 0.45 : 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Info Line
          Row(
            children: [
              // Source Tag Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  sourceTag,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              // Duration Info
              Text(
                isPlaying && currentPosition.inSeconds > 0
                    ? '${formatSeconds(currentPosition.inSeconds)} / ${formatSeconds(effectiveTotalSec)}'
                    : formatSeconds(effectiveTotalSec),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isPlaying ? AppColors.gold : p.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Audio Controls + Waveform Row
          Row(
            children: [
              // Play / Pause Circle Button
              InkWell(
                onTap: onTogglePlay,
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(
                          alpha: isPlaying ? 0.45 : 0.25,
                        ),
                        blurRadius: isPlaying ? 10 : 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.black,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Interactive Scrubbable Waveform
              Expanded(
                child: ScrubbableAudioWaveform(
                  progress: progress,
                  onSeek: onSeek == null
                      ? null
                      : (ratio) {
                          final targetMs = (ratio * effectiveTotalSec * 1000)
                              .toInt();
                          onSeek!(Duration(milliseconds: targetMs));
                        },
                ),
              ),
              const SizedBox(width: 10),

              // Replace / Re-record Button
              if (onReplace != null) ...[
                Tooltip(
                  message: 'Replace audio note',
                  child: InkWell(
                    onTap: onReplace,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: p.chipFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.border, width: 0.8),
                      ),
                      child: Icon(
                        RemixIcons.refresh_line,
                        size: 15,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Delete Button
              Tooltip(
                message: 'Remove audio',
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 7: UNIFIED SINGLE VOICE ATTACHMENT SECTION (READY FOR ANY DIALOG)
// ─────────────────────────────────────────────────────────────────────────────
class AppSingleVoiceAttachmentSection extends StatelessWidget {
  const AppSingleVoiceAttachmentSection({
    super.key,
    required this.isRecording,
    required this.recordingSeconds,
    required this.hasVoice,
    required this.isPlaying,
    required this.voiceDurationSeconds,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onPickAudioFile,
    required this.onTogglePlayback,
    required this.onClearVoice,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.onSeek,
    this.sectionTitle = 'VOICE REMINDER (AUDIO MESSAGE)',
    this.sectionSubtitle = 'Record memo or upload audio file · MP3, WAV, M4A',
  });

  final bool isRecording;
  final int recordingSeconds;
  final bool hasVoice;
  final bool isPlaying;
  final int voiceDurationSeconds;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onPickAudioFile;
  final VoidCallback onTogglePlayback;
  final VoidCallback onClearVoice;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration>? onSeek;
  final String sectionTitle;
  final String sectionSubtitle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  RemixIcons.mic_line,
                  size: 14,
                  color: hasVoice ? AppColors.gold : p.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: hasVoice ? AppColors.gold : p.textMuted,
                  ),
                ),
              ],
            ),
            Text(
              hasVoice ? '1 audio attached' : 'Optional',
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasVoice ? FontWeight.w700 : FontWeight.w500,
                color: hasVoice ? AppColors.gold : p.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Body Switcher
        if (isRecording) ...[
          AppLiveRecordingStudio(
            recordingSeconds: recordingSeconds,
            onStopAndAttach: onStopRecording,
            onCancel: onCancelRecording,
          ),
        ] else if (hasVoice) ...[
          AppAudioPlayerDeck(
            isPlaying: isPlaying,
            durationSeconds: voiceDurationSeconds,
            currentPosition: currentPosition,
            totalDuration: totalDuration,
            onSeek: onSeek,
            onTogglePlay: onTogglePlayback,
            onDelete: onClearVoice,
            onReplace: onPickAudioFile,
            title: 'Voice Reminder Attached',
            sourceTag: 'REMINDER NOTE',
          ),
        ] else ...[
          AppAudioActionSelector(
            onRecordVoice: onStartRecording,
            onUploadAudio: onPickAudioFile,
            recordLabel: 'Record Voice',
            recordSubtitle: 'Tap to record live memo',
            uploadLabel: 'Upload Audio',
            uploadSubtitle: 'MP3, WAV, AAC, M4A',
          ),
        ],
      ],
    );
  }
}
