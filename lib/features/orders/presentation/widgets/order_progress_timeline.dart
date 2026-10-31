import 'package:flutter/material.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class OrderProgressTimeline extends StatefulWidget {
  const OrderProgressTimeline({
    super.key,
    required this.status,
    this.onStatusSelected,
    this.onResumeOrder,
    this.showStatusDropdown = true,
    this.compact = false,
  });

  final Status status;
  final ValueChanged<Status>? onStatusSelected;
  final VoidCallback? onResumeOrder;
  final bool showStatusDropdown;
  final bool compact;

  @override
  State<OrderProgressTimeline> createState() => _OrderProgressTimelineState();
}

class _OrderProgressTimelineState extends State<OrderProgressTimeline>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<Status> _productionStages = [
    Status.pending,
    Status.confirmed,
    Status.editingProgress,
    Status.dispatchForPrinting,
    Status.printReceived,
    Status.framingProcess,
    Status.completed,
  ];

  static const Map<Status, IconData> _stageIcons = {
    Status.pending: Icons.hourglass_top_rounded,
    Status.confirmed: Icons.verified_outlined,
    Status.editingProgress: Icons.brush_outlined,
    Status.dispatchForPrinting: Icons.local_shipping_outlined,
    Status.printReceived: Icons.inventory_2_outlined,
    Status.framingProcess: Icons.crop_square_outlined,
    Status.completed: Icons.check_circle_outline,
  };

  static int _productionIndexFor(Status s) {
    switch (s) {
      case Status.pending:
        return 0;
      case Status.confirmed:
        return 1;
      case Status.editingProgress:
      case Status.inProgress:
        return 2;
      case Status.dispatchForPrinting:
        return 3;
      case Status.printReceived:
        return 4;
      case Status.framingProcess:
        return 5;
      case Status.completed:
        return 6;
      case Status.onHold:
      case Status.cancelled:
        return -1;
    }
  }

  int get _currentProductionIndex => _productionIndexFor(widget.status);

  double _progressFractionFor(Status s) {
    final idx = _productionIndexFor(s);
    if (idx <= 0) return 0.0;
    return (idx / (_productionStages.length - 1)).clamp(0.0, 1.0);
  }

  static bool get _isTesting =>
      const bool.fromEnvironment('flutter.test') ||
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (!_isTesting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    final initialProgress = _progressFractionFor(widget.status);
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: initialProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _progressController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant OrderProgressTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      final oldProg = _progressAnimation.value;
      final newProg = _progressFractionFor(widget.status);

      _progressAnimation = Tween<double>(
        begin: oldProg,
        end: newProg,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ));

      _progressController.forward(from: 0.0);

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoScrollToCurrent(),
      );
    }
  }

  void _autoScrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final idx = _currentProductionIndex;
    if (idx > 1) {
      final target = (idx - 1) * 105.0;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = p.isDark;
    final isOnHold = widget.status == Status.onHold;
    final isCancelled = widget.status == Status.cancelled;
    final currentIdx = _currentProductionIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Workflow Header Bar
        _buildHeaderBar(context, p, currentIdx),

        const SizedBox(height: 14),

        // 1. Prominent alert banner if ON HOLD
        if (isOnHold) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33EA580C) : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0x66EA580C)
                    : const Color(0xFFFED7AA),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  color: Color(0xFFEA580C),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order is On Hold',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Workshop production is paused. Resume to continue the workflow.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onStatusSelected != null ||
                    widget.onResumeOrder != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onResumeOrder != null) {
                        widget.onResumeOrder!();
                      } else {
                        widget.onStatusSelected?.call(Status.confirmed);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Resume Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 2. Alert banner if CANCELLED
        if (isCancelled) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33DC2626) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0x66DC2626)
                    : const Color(0xFFFCA5A5),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Cancelled',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'This order was cancelled and is excluded from active production.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Ultra-Smooth Animated Production Timeline Track
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF221E1A),
                      const Color(0xFF1B1815),
                    ]
                  : [
                      const Color(0xFFFAFAFB),
                      const Color(0xFFF1F5F9),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3B352D)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const nodeSize = 38.0;
              final isWide = constraints.maxWidth >= 680 && !widget.compact;

              if (isWide) {
                // Wide flex layout with mathematical alignment
                final totalWidth = constraints.maxWidth;
                final stepWidth = totalWidth / _productionStages.length;
                final trackLeft = stepWidth * 0.5;
                final trackWidth = stepWidth * (_productionStages.length - 1);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Continuous Connecting Animated Line behind nodes
                    _buildContinuousTrack(
                      trackLeft: trackLeft,
                      trackWidth: trackWidth,
                      nodeSize: nodeSize,
                      isDark: isDark,
                    ),

                    // Stage Nodes in Front
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _productionStages.length; i++)
                          Expanded(
                            child: _buildStageNode(
                              stage: _productionStages[i],
                              index: i,
                              p: p,
                              isDark: isDark,
                              nodeSize: nodeSize,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              } else {
                // Scrollable horizontal timeline for compact & mobile devices
                const stepWidth = 105.0;
                final totalWidth = stepWidth * _productionStages.length;
                const trackLeft = stepWidth * 0.5;
                final trackWidth = stepWidth * (_productionStages.length - 1);

                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Continuous Connecting Animated Line behind nodes
                        _buildContinuousTrack(
                          trackLeft: trackLeft,
                          trackWidth: trackWidth,
                          nodeSize: nodeSize,
                          isDark: isDark,
                        ),

                        // Stage Nodes in Front
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _productionStages.length; i++)
                              SizedBox(
                                width: stepWidth,
                                child: _buildStageNode(
                                  stage: _productionStages[i],
                                  index: i,
                                  p: p,
                                  isDark: isDark,
                                  nodeSize: nodeSize,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBar(BuildContext context, AppPalette p, int currentIdx) {
    final statusColor = widget.status.color;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            _getOverallStatusIcon(widget.status),
            size: 18,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT STATUS: ${widget.status.label.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusSubtitle(widget.status),
                style: TextStyle(
                  fontSize: 11.5,
                  color: p.textMuted,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (widget.showStatusDropdown && widget.onStatusSelected != null) ...[
          const SizedBox(width: 8),
          _buildStatusMenu(context, p),
        ],
      ],
    );
  }

  Widget _buildContinuousTrack({
    required double trackLeft,
    required double trackWidth,
    required double nodeSize,
    required bool isDark,
  }) {
    const trackHeight = 6.0;
    final topOffset = (nodeSize - trackHeight) / 2;

    return Positioned(
      left: trackLeft,
      top: topOffset,
      width: trackWidth,
      height: trackHeight,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          final progress = _progressAnimation.value.clamp(0.0, 1.0);
          final filledWidth = trackWidth * progress;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Sleek Background Track
              Container(
                width: trackWidth,
                height: trackHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF332D26)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                ),
              ),

              // 2. Continuous Animated Gradient Progress Fill
              if (filledWidth > 0)
                Container(
                  width: filledWidth,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF10B981), // Emerald Green
                        Color(0xFF059669), // Deep Green
                        Color(0xFFF59E0B), // Radiant Amber / Gold tip
                      ],
                      stops: [0.0, 0.75, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),

              // 3. Glowing Pulse Bead at the Leading Tip
              if (filledWidth > 0 && progress < 1.0)
                Positioned(
                  left: (filledWidth - 5).clamp(0.0, trackWidth - 10),
                  top: -2.5,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFEF08A),
                          Color(0xFFF59E0B),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStageNode({
    required Status stage,
    required int index,
    required AppPalette p,
    required bool isDark,
    required double nodeSize,
  }) {
    final currentIdx = _currentProductionIndex;
    final isCompleted = currentIdx >= 0 && index < currentIdx;
    final isCurrent = currentIdx == index;

    Color textColor;
    FontWeight textWeight;

    if (isCompleted) {
      textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      textWeight = FontWeight.w600;
    } else if (isCurrent) {
      textColor = isDark ? AppColors.gold : const Color(0xFFB45309);
      textWeight = FontWeight.w800;
    } else {
      textColor = p.textMuted;
      textWeight = FontWeight.w500;
    }

    final isInteractive = widget.onStatusSelected != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Node circle container with consistent height
        SizedBox(
          height: nodeSize,
          child: Center(
            child: _buildCircle(
              stage: stage,
              index: index,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isDark: isDark,
              p: p,
              nodeSize: nodeSize,
            ),
          ),
        ),

        const SizedBox(height: 9),

        // Step indicator tag: "STEP 1", "STEP 2", etc.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.gold.withValues(alpha: 0.2)
                : (isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : (isDark
                        ? const Color(0xFF2C2824)
                        : const Color(0xFFE2E8F0))),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'STEP ${index + 1}',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isCurrent
                  ? AppColors.gold
                  : (isCompleted
                      ? const Color(0xFF10B981)
                      : p.textMuted),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Stage Name Label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            stage.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: textWeight,
              color: textColor,
              height: 1.15,
            ),
          ),
        ),

        // ACTIVE Badge indicator
        if (isCurrent) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );

    if (isInteractive) {
      return Tooltip(
        message: '${stage.label} (Step ${index + 1} of 7) • Tap to set status',
        child: InkWell(
          onTap: () => widget.onStatusSelected!(stage),
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.gold.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildCircle({
    required Status stage,
    required int index,
    required bool isCompleted,
    required bool isCurrent,
    required bool isDark,
    required AppPalette p,
    required double nodeSize,
  }) {
    if (isCompleted) {
      // 1. Completed Stage Node
      return Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF34D399), Color(0xFF059669)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      );
    } else if (isCurrent) {
      // 2. Active Pulsing Stage Node
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          final pulse = _pulseAnimation.value;

          return Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
              ),
              border: Border.all(
                color: Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(
                    alpha: 0.35 + 0.35 * pulse,
                  ),
                  blurRadius: 8 + 8 * pulse,
                  spreadRadius: 1 + 2.5 * pulse,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _stageIcons[stage] ?? Icons.circle,
                size: 19,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      // 3. Upcoming Stage Node
      return Container(
        width: nodeSize - 4,
        height: nodeSize - 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF221E1B) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isDark ? const Color(0xFF453F36) : const Color(0xFFCBD5E1),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _stageIcons[stage] ?? Icons.circle,
            size: 16,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
      );
    }
  }

  Widget _buildStatusMenu(BuildContext context, AppPalette p) {
    return PopupMenuButton<Status>(
      onSelected: (newStatus) => widget.onStatusSelected?.call(newStatus),
      offset: const Offset(0, 36),
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: p.border),
      ),
      itemBuilder: (_) => [
        for (final s in Status.standardStatuses)
          PopupMenuItem<Status>(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: s == widget.status
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: s == widget.status ? s.color : p.textPrimary,
                    ),
                  ),
                ),
                if (s == widget.status)
                  Icon(Icons.check, size: 16, color: s.color),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.chipFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Status',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: p.textPrimary),
          ],
        ),
      ),
    );
  }

  static IconData _getOverallStatusIcon(Status s) {
    switch (s) {
      case Status.pending:
        return Icons.hourglass_empty_rounded;
      case Status.confirmed:
        return Icons.verified_rounded;
      case Status.onHold:
        return Icons.pause_circle_rounded;
      case Status.cancelled:
        return Icons.cancel_rounded;
      case Status.editingProgress:
        return Icons.brush_rounded;
      case Status.dispatchForPrinting:
        return Icons.local_shipping_rounded;
      case Status.printReceived:
        return Icons.inventory_2_rounded;
      case Status.framingProcess:
        return Icons.crop_square_rounded;
      case Status.completed:
        return Icons.check_circle_rounded;
      case Status.inProgress:
        return Icons.autorenew_rounded;
    }
  }

  static String _getStatusSubtitle(Status s) {
    switch (s) {
      case Status.pending:
        return 'Order received. Awaiting confirmation & review.';
      case Status.confirmed:
        return 'Customer order verified. Ready for editing pipeline.';
      case Status.onHold:
        return 'Order is on hold. Workshop operations paused.';
      case Status.cancelled:
        return 'Order has been cancelled.';
      case Status.editingProgress:
        return 'Artwork & photo retouching in progress.';
      case Status.dispatchForPrinting:
        return 'Artwork dispatched to high-resolution print studio.';
      case Status.printReceived:
        return 'Prints received at workshop. Prepping frame mounts.';
      case Status.framingProcess:
        return 'Custom artisan framing, matting & glass fitting.';
      case Status.completed:
        return 'Framing completed, QA passed & delivered.';
      case Status.inProgress:
        return 'Order is currently in workshop production.';
    }
  }
}
