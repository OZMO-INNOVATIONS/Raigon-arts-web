import 'package:flutter/material.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

class OrderProgressTimeline extends StatefulWidget {
  const OrderProgressTimeline({
    super.key,
    required this.status,
    this.customer,
    this.statusHistory = const [],
    this.onStatusSelected,
    this.onResumeOrder,
    this.showStatusDropdown = true,
    this.compact = false,
  });

  final Status status;
  final Customer? customer;
  final List<OrderStatusHistoryItem> statusHistory;
  final ValueChanged<Status>? onStatusSelected;
  final VoidCallback? onResumeOrder;
  final bool showStatusDropdown;
  final bool compact;

  @override
  State<OrderProgressTimeline> createState() => _OrderProgressTimelineState();
}

class _OrderProgressTimelineState extends State<OrderProgressTimeline>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static bool get _isTesting =>
      const bool.fromEnvironment('flutter.test') ||
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

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
    Status.pending: Icons.hourglass_empty_rounded,
    Status.confirmed: Icons.verified_rounded,
    Status.editingProgress: Icons.brush_rounded,
    Status.dispatchForPrinting: Icons.local_shipping_rounded,
    Status.printReceived: Icons.inventory_2_rounded,
    Status.framingProcess: Icons.crop_square_rounded,
    Status.completed: Icons.check_circle_rounded,
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
    if (idx < 0) return 0.0;
    return (idx / (_productionStages.length - 1)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!_isTesting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final initialProgress = _progressFractionFor(widget.status);
    _progressAnimation = Tween<double>(begin: 0.0, end: initialProgress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant OrderProgressTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      final oldProg = _progressAnimation.value;
      final newProg = _progressFractionFor(widget.status);

      _progressAnimation = Tween<double>(begin: oldProg, end: newProg).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeInOutCubic,
        ),
      );

      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = p.isDark;
    final isOnHold = widget.status == Status.onHold;
    final isCancelled = widget.status == Status.cancelled;
    final currentIdx = _currentProductionIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Section Header (Web horizontal layout)
            _buildTopHeader(context, p, isDark, currentIdx),

            const SizedBox(height: 14),

            // 2. Prominent Alert Banner if ON HOLD
            if (isOnHold) ...[
              _buildOnHoldBanner(isDark),
              const SizedBox(height: 12),
            ],

            // 3. Alert Banner if CANCELLED
            if (isCancelled) ...[
              _buildCancelledBanner(isDark),
              const SizedBox(height: 12),
            ],

            // 4. Current Status Banner (iOS HIG / Material Design 3 Card)
            _buildCurrentStatusBanner(context, p, isDark, currentIdx),

            const SizedBox(height: 20),

            // 5. Horizontal Timeline with Connected Animated Fill Line
            _buildHorizontalTimeline(p, isDark, currentIdx),
          ],
        );

        if (constraints.hasBoundedHeight) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: content,
          );
        }

        return content;
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP SECTION HEADER (WEB HORIZONTAL)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    AppPalette p,
    bool isDark,
    int currentIdx,
  ) {
    final stepText = currentIdx >= 0
        ? 'Step ${currentIdx + 1} of ${_productionStages.length} Active'
        : widget.status.label;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.3)
                  : const Color(0xFFA7F3D0),
            ),
          ),

          child: const Icon(
            Icons.tune_rounded,
            size: 18,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ORDER PROGRESS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white : const Color(0xFF064E3B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stepText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CURRENT STATUS BANNER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentStatusBanner(
    BuildContext context,
    AppPalette p,
    bool isDark,
    int currentIdx,
  ) {
    final isCompletedOverall = widget.status == Status.completed;

    final Color bg = isCompletedOverall
        ? (isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.3)
              : const Color(0xFFECFDF5))
        : (isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.22)
              : const Color(0xFFF0FDF4));
    final Color border = isCompletedOverall
        ? (isDark
              ? const Color(0xFF059669).withValues(alpha: 0.4)
              : const Color(0xFFA7F3D0))
        : (isDark
              ? const Color(0xFF047857).withValues(alpha: 0.35)
              : const Color(0xFFBBF7D0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STATUS: ${widget.status.label.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusSubtitle(widget.status),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF047857),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLastUpdated(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showStatusDropdown && widget.onStatusSelected != null) ...[
            const SizedBox(width: 10),
            _buildUpdateDropdownPill(context, p, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdateDropdownPill(
    BuildContext context,
    AppPalette p,
    bool isDark,
  ) {
    return PopupMenuButton<Status>(
      onSelected: (newStatus) => widget.onStatusSelected?.call(newStatus),
      offset: const Offset(0, 36),
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF38322A) : const Color(0xFFE2E8F0),
        ),
      ),
      itemBuilder: (context) => [
        for (final s in Status.values)
          PopupMenuItem<Status>(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
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
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: s == widget.status ? s.color : p.textPrimary,
                    ),
                  ),
                ),
                if (s == widget.status)
                  Icon(Icons.check_rounded, size: 16, color: s.color),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF059669).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF059669),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HORIZONTAL TIMELINE WITH CONNECTED ANIMATED FILL LINE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHorizontalTimeline(AppPalette p, bool isDark, int currentIdx) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final timelineWidth = availableWidth < 720.0 ? 720.0 : availableWidth;

        final timelineWidget = SizedBox(
          width: timelineWidth,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Precise Custom-Painted Connecting Line with Animated Fill
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HorizontalTimelineLinePainter(
                        stageCount: _productionStages.length,
                        progress: _progressAnimation.value,
                        isDark: isDark,
                        nodeSize: 38.0,
                      ),
                    ),
                  ),

                  // 2. The 7 Stage Node Columns
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _productionStages.length; i++)
                        Expanded(
                          child: _buildHorizontalStageColumn(
                            stage: _productionStages[i],
                            index: i,
                            currentIdx: currentIdx,
                            p: p,
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );

        if (availableWidth < 720.0) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: timelineWidget,
          );
        }

        return timelineWidget;
      },
    );
  }

  Widget _buildHorizontalStageColumn({
    required Status stage,
    required int index,
    required int currentIdx,
    required AppPalette p,
    required bool isDark,
  }) {
    final isCompleted = currentIdx >= 0 && index < currentIdx;
    final isCurrent = currentIdx == index;
    final timestamp = _timestampForStage(stage, index, currentIdx);

    // Timeline stages are display-only. Status changes happen through
    // the Update dropdown in the current-status header.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Node
          _buildNodeCircle(
            stage: stage,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isDark: isDark,
          ),

          const SizedBox(height: 10),

          // Step Badge + Active Badge
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFFEF3C7)
                      : (isCompleted
                            ? const Color(0xFFECFDF5)
                            : (isDark
                                  ? const Color(0xFF26221E)
                                  : const Color(0xFFF1F5F9))),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'STEP ${index + 1}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isCurrent
                        ? const Color(0xFFD97706)
                        : (isCompleted
                              ? const Color(0xFF059669)
                              : (isDark
                                    ? Colors.white38
                                    : const Color(0xFF64748B))),
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Stage Title
          Text(
            stage.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isCurrent
                  ? FontWeight.w800
                  : (isCompleted ? FontWeight.w700 : FontWeight.w600),
              color: isCurrent
                  ? (isDark ? AppColors.gold : const Color(0xFF92400E))
                  : (isCompleted
                        ? (isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF065F46))
                        : (isDark ? Colors.white70 : const Color(0xFF475569))),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 4),

          // Timestamp
          Text(
            timestamp,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? const Color(0xFFD97706)
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCircle({
    required Status stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isDark,
  }) {
    const double size = 38.0;

    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E1B16) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (isCurrent) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          final pulse = _pulseAnimation.value;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1B16) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: 0.25 + 0.3 * pulse),
                  blurRadius: 6 + 6 * pulse,
                  spreadRadius: 1 + 2 * pulse,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  ),
                ),
                child: Icon(
                  _stageIcons[stage] ?? Icons.autorenew_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    }

    // Upcoming stage node
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1E1B16) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3B352D) : const Color(0xFFCBD5E1),
          width: 2.0,
        ),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF474036) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ON HOLD & CANCELLED BANNERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOnHoldBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33EA580C) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x66EA580C) : const Color(0xFFFED7AA),
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
                  style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33DC2626) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x66DC2626) : const Color(0xFFFCA5A5),
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
                  style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIMESTAMPS & DESCRIPTIONS HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  String _timestampForStage(Status stage, int index, int currentIdx) {
    for (final h in widget.statusHistory) {
      if (h.newStatus == stage) {
        return _formatTimelineTime(h.updatedAt);
      }
    }

    if (index == currentIdx) {
      return 'In Progress';
    }

    if (index < currentIdx) {
      if (index == 0 && widget.customer?.orderDate != null) {
        return _formatTimelineTime(widget.customer!.orderDate);
      }
      if (widget.customer?.createdAt != null) {
        final approx = widget.customer!.createdAt!.add(
          Duration(hours: index * 6),
        );
        return _formatTimelineTime(approx);
      }
      return 'Done';
    }

    return 'Upcoming';
  }

  String _formatTimelineTime(DateTime dt) {
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $ampm';
  }

  String _formatLastUpdated() {
    final DateTime lastDt;
    if (widget.statusHistory.isNotEmpty) {
      lastDt = widget.statusHistory.last.updatedAt;
    } else if (widget.customer?.createdAt != null) {
      lastDt = widget.customer!.createdAt!;
    } else {
      lastDt = DateTime.now();
    }

    final now = DateTime.now();
    final isToday =
        lastDt.year == now.year &&
        lastDt.month == now.month &&
        lastDt.day == now.day;
    final hour = lastDt.hour % 12 == 0 ? 12 : lastDt.hour % 12;
    final minute = lastDt.minute.toString().padLeft(2, '0');
    final ampm = lastDt.hour >= 12 ? 'PM' : 'AM';

    if (isToday) {
      return 'Last updated today at $hour:$minute $ampm';
    }
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][lastDt.month - 1];
    return 'Last updated $month ${lastDt.day} at $hour:$minute $ampm';
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
      case Status.inProgress:
        return 'Artwork & photo retouching in progress.';
      case Status.dispatchForPrinting:
        return 'Artwork dispatched to high-resolution print studio.';
      case Status.printReceived:
        return 'Prints received at workshop. Prepping frame mounts.';
      case Status.framingProcess:
        return 'Custom wooden moulding cut, mounted, and glazing fitted.';
      case Status.completed:
        return 'Framing completed, QA passed & delivered.';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR CONTINUOUS CONNECTING LINE WITH ANIMATED PROGRESS FILL
// ─────────────────────────────────────────────────────────────────────────
class _HorizontalTimelineLinePainter extends CustomPainter {
  final int stageCount;
  final double progress; // 0.0 to 1.0
  final bool isDark;
  final double nodeSize;

  _HorizontalTimelineLinePainter({
    required this.stageCount,
    required this.progress,
    required this.isDark,
    this.nodeSize = 38.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stageCount <= 1) return;

    final itemWidth = size.width / stageCount;
    final startX = itemWidth / 2;
    final totalTrackLength = itemWidth * (stageCount - 1);
    final endX = startX + totalTrackLength;
    final centerY = nodeSize / 2;

    // 1. Inactive background track line
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF332D26) : const Color(0xFFE2E8F0)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), trackPaint);

    // 2. Animated Progress fill line
    if (progress > 0.0) {
      final fillLength = totalTrackLength * progress.clamp(0.0, 1.0);
      final fillEndX = startX + fillLength;

      // Gradient shader for the filled line
      final gradient = LinearGradient(
        colors: [
          const Color(0xFF10B981), // Emerald green at start
          const Color(0xFF059669),
          if (progress > 0.4)
            const Color(0xFFF59E0B), // Warm amber near active node
        ],
      );

      final fillRect = Rect.fromPoints(
        Offset(startX, centerY - 2.5),
        Offset(fillEndX, centerY + 2.5),
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(fillRect)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw subtle glow shadow under filled line
      final glowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.2)
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(startX, centerY),
        Offset(fillEndX, centerY),
        glowPaint,
      );

      // Draw the actual filled line
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(fillEndX, centerY),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalTimelineLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.stageCount != stageCount;
  }
}
