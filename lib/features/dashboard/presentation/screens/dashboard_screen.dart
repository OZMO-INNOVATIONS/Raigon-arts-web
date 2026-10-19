import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';
import 'package:raigon_art/core/widgets/status_pill.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customer_view_dialog.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _pagePadding = 24;
  static const double _tableHPadding = 28;
  static const double _statCardHeight = 150; // estimated, used for page height
  static const double _minRecentCardHeight = 360;

  // Column widths in logical pixels. Used as the minimum width of each column
  // and as the flex proportion when the screen is wider than the table.
  static const _cols = <({String label, double width})>[
    (label: 'CUSTOMER ID', width: 130),
    (label: 'CUSTOMER NAME', width: 230),
    (label: 'PHONE NO', width: 150),
    (label: 'FRAME SIZE', width: 130),
    (label: 'FRAME TYPE', width: 150),
    (label: 'QTY', width: 70),
    (label: 'TOTAL', width: 130),
    (label: 'STATUS', width: 150),
    (label: 'ACTIONS', width: 110),
  ];

  static final double _minTableWidth =
      _cols.fold<double>(0, (a, c) => a + c.width) + (_tableHPadding * 2);

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  static int _statColsFor(double width) => width >= 1100
      ? 5
      : width >= 700
      ? 3
      : width >= 440
      ? 2
      : 1;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final customerAndOrderProvider = context.watch<CustomerAndOrderProvider>();
    final customers = customerAndOrderProvider.customers;

    if (customerAndOrderProvider.isLoading &&
        !customerAndOrderProvider.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = math.max(
          constraints.maxWidth - (_pagePadding * 2),
          0.0,
        );

        // Estimate the minimum height the page needs so nothing overflows.
        const gap = 20.0;
        final statCols = _statColsFor(innerWidth);
        final statRows = (5 / statCols).ceil();
        final titleH = constraints.maxWidth < 640 ? 130.0 : 70.0;
        final statsH = statRows * _statCardHeight + (statRows - 1) * gap;
        final minPageHeight =
            (_pagePadding * 2) +
            titleH +
            24 +
            statsH +
            24 +
            _minRecentCardHeight;

        final content = Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleRow(context, p),

              const SizedBox(height: 24),

              _buildStatsGrid(context, width: innerWidth, customers: customers),

              const SizedBox(height: 24),

              Expanded(child: _buildRecentOrdersCard(context, customers)),
            ],
          ),
        );

        // If the available height is too small, let the whole page scroll
        // vertically instead of overflowing.
        if (constraints.maxHeight >= minPageHeight) {
          return content;
        }
        return SingleChildScrollView(
          child: SizedBox(
            height: minPageHeight,
            width: constraints.maxWidth,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildTitleRow(BuildContext context, AppPalette p) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back, Raigon Arts Workshop Manager',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15.5, color: p.textMuted),
        ),
      ],
    );

    final addButton = AppPrimaryButton(
      label: 'Add New Customer',
      icon: Icons.person_add,
      onPressed: () => ShellScope.of(context).openAddCustomer(),
    );

    return LayoutBuilder(
      builder: (context, c) {
        // Narrow screens: stack the button under the title.
        if (c.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 14), addButton],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            addButton,
          ],
        );
      },
    );
  }

  static String _inr(int v) {
    final s = v.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '₹${parts.join(',')},$last3';
  }

  static (IconData, String) _trend(num cur, num prev) {
    if (prev == 0) return (Icons.arrow_upward, cur > 0 ? 'New' : '0%');
    final pct = ((cur - prev) / prev * 100).round();
    return (
      pct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
      '${pct >= 0 ? '+' : ''}$pct%',
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required double width,
    required List<Customer> customers,
  }) {
    final p = AppPalette.of(context);
    int count(Status s) => customers.where((c) => c.status == s).length;
    final billable = customers
        .where((c) => c.status != Status.cancelled)
        .toList();
    final revenue = billable.fold<int>(0, (a, c) => a + c.total);

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    bool sameMonth(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month;

    final ordersNow = customers
        .where((c) => sameMonth(c.orderDate, now))
        .length;
    final ordersPrev = customers
        .where((c) => sameMonth(c.orderDate, lastMonth))
        .length;
    final revNow = billable
        .where((c) => sameMonth(c.orderDate, now))
        .fold<int>(0, (a, c) => a + c.total);
    final revPrev = billable
        .where((c) => sameMonth(c.orderDate, lastMonth))
        .fold<int>(0, (a, c) => a + c.total);
    final ordersTrend = _trend(ordersNow, ordersPrev);
    final revTrend = _trend(revNow, revPrev);

    final stats =
        <
          ({
            String title,
            String value,
            IconData icon,
            Color tileBg,
            Color tileIcon,
            IconData footIcon,
            String footStrong,
            String footLight,
            Color footColor,
          })
        >[
          (
            title: 'Total Frame Orders',
            value: '${customers.length}',
            icon: Icons.move_to_inbox,
            tileBg: p.tileNeutral,
            tileIcon: p.tileNeutralIcon,
            footIcon: ordersTrend.$1,
            footStrong: ordersTrend.$2,
            footLight: 'vs last month',
            footColor: p.textPrimary,
          ),
          (
            title: 'In Progress',
            value: '${count(Status.inProgress)}',
            icon: Icons.handyman,
            tileBg: p.tileTeal,
            tileIcon: AppPalette.teal,
            footIcon: Icons.sync,
            footStrong: 'Active',
            footLight: 'in workshop',
            footColor: AppPalette.teal,
          ),
          (
            title: 'Completed Orders',
            value: '${count(Status.completed)}',
            icon: Icons.check_circle,
            tileBg: p.tileGreen,
            tileIcon: AppColors.green,
            footIcon: Icons.check,
            footStrong: 'Ready',
            footLight: 'for delivery',
            footColor: AppColors.green,
          ),
          (
            title: 'Pending Orders',
            value: '${count(Status.pending)}',
            icon: Icons.watch_later,
            tileBg: p.tileOrange,
            tileIcon: AppPalette.orange,
            footIcon: Icons.warning,
            footStrong: 'Urgent',
            footLight: 'action needed',
            footColor: AppPalette.orange,
          ),
          (
            title: 'Total Revenue',
            value: _inr(revenue),
            icon: Icons.currency_rupee,
            tileBg: p.tileNeutral,
            tileIcon: p.tileNeutralIcon,
            footIcon: revTrend.$1,
            footStrong: revTrend.$2,
            footLight: 'vs last month',
            footColor: p.textPrimary,
          ),
        ];

    const gap = 20.0;
    final cols = _statColsFor(width);
    final cardWidth = (width - gap * (cols - 1)) / cols;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final s in stats)
          SizedBox(
            width: math.max(cardWidth, 0),
            child: _buildStatCard(
              context: context,
              title: s.title,
              value: s.value,
              icon: s.icon,
              tileBg: s.tileBg,
              tileIcon: s.tileIcon,
              footIcon: s.footIcon,
              footStrong: s.footStrong,
              footLight: s.footLight,
              footColor: s.footColor,
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color tileBg,
    required Color tileIcon,
    required IconData footIcon,
    required String footStrong,
    required String footLight,
    required Color footColor,
  }) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: p.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: tileIcon),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDashedLine(p.rowDivider),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(footIcon, size: 16, color: footColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  footStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: footColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  footLight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return ClipRect(
          child: SizedBox(
            height: 1,
            width: double.infinity,
            child: Row(
              children: [
                for (var i = 0; i < dashCount; i++) ...[
                  Container(width: 4, height: 1, color: color),
                  if (i != dashCount - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentOrdersCard(
    BuildContext context,
    List<Customer> customers,
  ) {
    final p = AppPalette.of(context);
    final sortedCustomers = [...customers]
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    const pageSize = 8;
    final recent = sortedCustomers.take(pageSize).toList();

    // Flex values derived from the pixel widths.
    final flex = _cols.map((c) => c.width.round()).toList();

    Widget headerRow() => Container(
      color: p.tableHeaderBg,
      padding: const EdgeInsets.symmetric(
        horizontal: _tableHPadding,
        vertical: 22,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _cols.length; i++)
            Expanded(
              flex: flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _cols[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: p.headerText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget orderRow(Customer o) {
      final cell = TextStyle(fontSize: 15, color: p.textPrimary);
      final bold = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      );

      Widget cellBox(int i, Widget child) => Expanded(
        flex: flex[i],
        child: Padding(padding: const EdgeInsets.only(right: 8), child: child),
      );

      Widget txt(String s, TextStyle style) => Text(
        s,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: style,
      );

      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.rowDivider)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _tableHPadding,
          vertical: 16,
        ),
        child: Row(
          children: [
            cellBox(0, txt(o.id, bold)),
            cellBox(
              1,
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      o.name.isEmpty ? '?' : o.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        txt(
                          o.name,
                          TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        txt(
                          o.city,
                          TextStyle(fontSize: 13, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            cellBox(2, txt(o.phone, cell)),
            cellBox(3, txt(o.frameSize, cell)),
            cellBox(4, txt(o.frameType, cell)),
            cellBox(5, txt('${o.qty}', bold)),
            cellBox(6, txt(_inr(o.total), bold)),
            cellBox(
              7,
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: StatusPill(status: o.status),
                ),
              ),
            ),
            cellBox(
              8,
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => showViewCustomerDialog(context, o),
                        child: Icon(
                          Icons.visibility,
                          size: 21,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: () => showEditCustomerDialog(context, o),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cardTitle = Text(
      'Recent Customer Frame Orders',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
    );

    final viewAllButton = InkWell(
      onTap: () => ShellScope.of(context).goTo(NavDestination.customers),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: p.chipFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All Customers',
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 17, color: p.textPrimary),
          ],
        ),
      ),
    );

    return Container(
      decoration: p.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
            child: LayoutBuilder(
              builder: (context, c) {
                // Narrow card: stack the button under the title.
                if (c.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cardTitle,
                      const SizedBox(height: 12),
                      viewAllButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cardTitle),
                    const SizedBox(width: 12),
                    viewAllButton,
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = math.max(
                  constraints.maxWidth,
                  _minTableWidth,
                );

                return ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: const WidgetStatePropertyAll(AppColors.gold),
                    trackColor: WidgetStatePropertyAll(
                      AppColors.gold.withValues(alpha: 0.12),
                    ),
                    thickness: const WidgetStatePropertyAll(6),
                    radius: const Radius.circular(3),
                  ),
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 0 &&
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headerRow(),
                            Expanded(
                              child: Scrollbar(
                                controller: _verticalController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0 &&
                                    notification.metrics.axis == Axis.vertical,
                                child: SingleChildScrollView(
                                  controller: _verticalController,
                                  primary: false,
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (recent.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 48,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'No orders yet',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: p.textMuted,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        for (final c in recent) orderRow(c),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
