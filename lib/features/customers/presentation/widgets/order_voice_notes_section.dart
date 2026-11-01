import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_audio_recorder_section.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/services/reminder_audio_service.dart';

class OrderVoiceNotesSection extends StatefulWidget {
  const OrderVoiceNotesSection({
    super.key,
    required this.voiceNotes,
    required this.onChanged,
    this.isEditable = true,
    this.title = 'Order Voice Instructions',
  });

  final List<OrderVoiceNote> voiceNotes;
  final ValueChanged<List<OrderVoiceNote>> onChanged;
  final bool isEditable;
  final String title;

  @override
  State<OrderVoiceNotesSection> createState() => _OrderVoiceNotesSectionState();
}

class _OrderVoiceNotesSectionState extends State<OrderVoiceNotesSection> {
  final ReminderAudioService _audioService = ReminderAudioService();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  String? _playingNoteId;
  Duration _currentPos = Duration.zero;
  Duration _totalDur = Duration.zero;
  StreamSubscription? _recSub;
  StreamSubscription? _playerSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _recSub = _audioService.onRecordSecondsChanged.listen((sec) {
      if (mounted) setState(() => _recordingSeconds = sec);
    });
    _playerSub = _audioService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          if (state != PlayerState.playing) {
            _playingNoteId = null;
            _currentPos = Duration.zero;
          }
        });
      }
    });
    _posSub = _audioService.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPos = pos);
    });
    _durSub = _audioService.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDur = dur);
    });
  }

  @override
  void dispose() {
    _recSub?.cancel();
    _playerSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    final ok = await _audioService.startRecording();
    if (ok) {
      setState(() => _isRecording = true);
    } else {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Microphone permission denied or recording unavailable.',
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final result = await _audioService.stopRecording();
    setState(() => _isRecording = false);
    if (result != null && result.bytes.isNotEmpty) {
      final newNotes = List<OrderVoiceNote>.of(widget.voiceNotes);
      final index = newNotes.length + 1;
      newNotes.add(
        OrderVoiceNote(
          id: 'voice_${DateTime.now().millisecondsSinceEpoch}_$index',
          url: '',
          name: 'Voice Note #$index',
          durationSeconds: result.durationSeconds,
          createdAt: DateTime.now(),
          localBytes: result.bytes,
        ),
      );
      widget.onChanged(newNotes);
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    setState(() => _isRecording = false);
  }

  Future<void> _pickAudioFile() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'webm'],
      );
      if (res.isNotEmpty) {
        final file = res.first;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final newNotes = List<OrderVoiceNote>.of(widget.voiceNotes);
          final rawName = file.name.isNotEmpty
              ? file.name.split('.').first
              : 'Audio Note';
          newNotes.add(
            OrderVoiceNote(
              id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
              url: '',
              name: rawName,
              durationSeconds: 15,
              createdAt: DateTime.now(),
              localBytes: bytes,
            ),
          );
          widget.onChanged(newNotes);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick audio file: $e');
      }
    }
  }

  Future<void> _togglePlay(OrderVoiceNote note) async {
    if (_playingNoteId == note.id && _audioService.isPlaying) {
      await _audioService.stop();
      if (mounted) setState(() => _playingNoteId = null);
    } else {
      if (note.localBytes != null && note.localBytes!.isNotEmpty) {
        await _audioService.playBytes(note.localBytes!, mediaId: note.id);
      } else if (note.url.isNotEmpty) {
        await _audioService.playUrl(note.url, mediaId: note.id);
      } else {
        AppSnackBar.error(context, 'Audio note data unavailable.');
        return;
      }
      if (mounted) setState(() => _playingNoteId = note.id);
    }
  }

  void _removeNote(int index) {
    final note = widget.voiceNotes[index];
    if (_playingNoteId == note.id) {
      _audioService.stop();
      _playingNoteId = null;
    }
    final newNotes = List<OrderVoiceNote>.of(widget.voiceNotes)
      ..removeAt(index);
    widget.onChanged(newNotes);
  }

  void _renameNote(int index, String newName) {
    final newNotes = List<OrderVoiceNote>.of(widget.voiceNotes);
    newNotes[index] = newNotes[index].copyWith(name: newName.trim());
    widget.onChanged(newNotes);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = FormColors.of(context);

    final hasNotes = widget.voiceNotes.isNotEmpty;

    if (!widget.isEditable && !hasNotes) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.textBorder, width: 1.2),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      hasNotes
                          ? '${widget.voiceNotes.length} voice instruction${widget.voiceNotes.length > 1 ? 's' : ''} attached'
                          : 'Record voice instructions or customer audio notes',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.isEditable && !_isRecording) ...[
            const SizedBox(height: 14),
            AppAudioActionSelector(
              onRecordVoice: _startRecording,
              onUploadAudio: _pickAudioFile,
              recordLabel: 'Record Voice Note',
              recordSubtitle: 'Tap to record audio instructions',
              uploadLabel: 'Upload Audio File',
              uploadSubtitle: 'MP3, WAV, AAC, M4A',
            ),
          ],

          // Live Recording Studio
          if (_isRecording) ...[
            const SizedBox(height: 14),
            AppLiveRecordingStudio(
              recordingSeconds: _recordingSeconds,
              onStopAndAttach: _stopRecording,
              onCancel: _cancelRecording,
            ),
          ],

          // List of Notes
          if (hasNotes) ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.voiceNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final note = widget.voiceNotes[idx];
                final isPlayingThis =
                    _playingNoteId == note.id && _audioService.isPlaying;

                final effectiveTotalSec = _totalDur.inSeconds > 0
                    ? _totalDur.inSeconds
                    : (note.durationSeconds > 0 ? note.durationSeconds : 1);
                final progress =
                    (_currentPos.inMilliseconds / (effectiveTotalSec * 1000))
                        .clamp(0.0, 1.0);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isPlayingThis
                        ? AppColors.gold.withValues(
                            alpha: p.isDark ? 0.14 : 0.08,
                          )
                        : (p.isDark
                              ? const Color(0xFF1E2036)
                              : const Color(0xFFFFFFFF)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlayingThis ? AppColors.gold : p.border,
                      width: isPlayingThis ? 1.3 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: p.isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          // Play / Pause Circle Button
                          InkWell(
                            onTap: () => _togglePlay(note),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isPlayingThis
                                    ? AppColors.gold
                                    : p.chipFill,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlayingThis
                                      ? AppColors.gold
                                      : p.border,
                                  width: 1,
                                ),
                                boxShadow: isPlayingThis
                                    ? [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isPlayingThis
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 20,
                                color: isPlayingThis
                                    ? AppColors.black
                                    : p.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title & duration
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        note.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: p.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        note.url.isNotEmpty ? 'SAVED' : 'LOCAL',
                                        style: const TextStyle(
                                          fontSize: 8.5,
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
                                  isPlayingThis
                                      ? '${_formatDuration(_currentPos.inSeconds)} / ${_formatDuration(effectiveTotalSec)}'
                                      : (note.durationSeconds > 0
                                            ? '${_formatDuration(note.durationSeconds)} audio note'
                                            : 'Audio recording ready'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPlayingThis
                                        ? AppColors.gold
                                        : p.textMuted,
                                    fontWeight: isPlayingThis
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rename button
                          if (widget.isEditable) ...[
                            Tooltip(
                              message: 'Rename voice note',
                              child: InkWell(
                                onTap: () async {
                                  final ctrl = TextEditingController(
                                    text: note.name,
                                  );
                                  final confirmed = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: p.surface,
                                      title: const Text('Rename Voice Note'),
                                      content: TextField(
                                        controller: ctrl,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Voice Note Name',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(ctrl.text),
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != null &&
                                      confirmed.isNotEmpty) {
                                    _renameNote(idx, confirmed);
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: p.chipFill,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: p.border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                    color: p.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Delete Button
                            Tooltip(
                              message: 'Delete voice note',
                              child: InkWell(
                                onTap: () => _removeNote(idx),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3),
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
                        ],
                      ),
                      if (isPlayingThis) ...[
                        const SizedBox(height: 8),
                        ScrubbableAudioWaveform(
                          progress: progress,
                          onSeek: (r) async {
                            final targetMs = (r * effectiveTotalSec * 1000)
                                .toInt();
                            await _audioService.seek(
                              Duration(milliseconds: targetMs),
                            );
                          },
                          height: 20,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
