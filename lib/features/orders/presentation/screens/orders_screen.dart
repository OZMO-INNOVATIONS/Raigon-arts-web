import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_pagination_footer.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customer_view_dialog.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/widgets/app_confirmation_dialog.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customers_table.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Status? _filter;
  String _query = '';
  static const int _pageSize = 10;
  static const double _minPageHeight = 560;
  static const double _tableHPadding = 20;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerAndOrderProvider>().init();
      }
    });
  }

  int _page = 1;

  final Map<String, Status> _statusOverride = {};

  // Column widths in logical pixels. Used both as the minimum width of each
  // column and as the flex proportion when the screen is wider than the table.
  static const _colWidths = <double>[
    110, // Order ID
    170, // Customer
    150, // Phone
    130, // Photos
    150, // Frame Specs
    70, // Qty
    120, // Total
    140, // Payment
    170, // Status
    140, // Delivery
    160, // Actions
  ];

  static final double _minTableWidth =
      _colWidths.fold<double>(0, (a, b) => a + b) + (_tableHPadding * 2);

  // Flex values derived from the pixel widths.
  static final List<int> _flex = _colWidths.map((w) => w.round()).toList();

  static const _headers = [
    'ORDER ID',
    'CUSTOMER',
    'PHONE NO',
    'PHOTOS',
    'FRAME SPECS',
    'QTY',
    'TOTAL AMOUNT',
    'PAYMENT',
    'ORDER STATUS',
    'DELIVERY DATE',
    'ACTIONS',
  ];

  Status _statusOf(Customer c) => _statusOverride[c.id] ?? c.status;

  Future<void> _delete(Customer customer) async {
    final ok = await showDeleteOrderConfirmationDialog(context, customer);
    if (!ok || !mounted) return;
    try {
      await context.read<CustomerAndOrderProvider>().remove(customer.id);
      if (mounted) {
        AppSnackBar.success(context, 'Order ${customer.id} deleted successfully.');
      }
    } catch (error) {
      if (mounted) {
        final msg = error is ApiException
            ? error.userFriendlyMessage
            : 'Could not delete order. Try again.';
        AppSnackBar.error(context, msg);
      }
    }
  }

  Future<void> _sendWhatsApp(Customer customer) async {
    try {
      final opened = await CustomerWhatsAppService.openOrderConfirmation(customer);
      if (!mounted) return;
      if (opened) {
        AppSnackBar.success(context, 'WhatsApp opened with order confirmation.');
      } else {
        AppSnackBar.error(context, 'Could not open WhatsApp. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not open WhatsApp. Check customer phone number.');
    }
  }

  static const _months = [
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
  ];

  String _date(DateTime? d) => d == null
      ? 'N/A'
      : '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

  Color _statusColor(Status s) => switch (s) {
    Status.inProgress => AppPalette.statusGold,
    Status.pending => AppPalette.orange,
    Status.completed => AppPalette.statusGreen,
    Status.cancelled => AppPalette.statusRed,
  };

  String _statusLabel(Status s) => switch (s) {
    Status.inProgress => 'In Progress',
    Status.pending => 'Pending',
    Status.completed => 'Completed',
    Status.cancelled => 'Cancelled',
  };

  String _paymentOf(Customer c) {
    if (c.advance <= 0) return 'Unpaid';
    if (c.advance >= c.total) return 'Paid';
    return 'Partial';
  }

  Color _paymentColor(String s) => switch (s) {
    'Paid' => AppPalette.statusGreen,
    'Partial' => AppPalette.statusGold,
    _ => AppPalette.statusRed,
  };

  String _money(int v) {
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

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final customerProvider = context.watch<CustomerAndOrderProvider>();

    if (customerProvider.isLoading && !customerProvider.initialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Loading orders...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final all = List<Customer>.of(customerProvider.customers)
      ..sort(CustomerAndOrderProvider.compareLatestFirst);
    final q = _query.trim().toLowerCase();
    final rows = all.where((c) {
      if (_filter != null && _statusOf(c) != _filter) {
        return false;
      }

      if (q.isEmpty) return true;

      return c.id.toLowerCase().contains(q) || c.name.toLowerCase().contains(q);
    }).toList();
    final totalPages = math.max(1, (rows.length / _pageSize).ceil());
    final currentPage = _page.clamp(1, totalPages);
    final pageRows = rows
        .skip((currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    int count(Status? s) =>
        s == null ? all.length : all.where((c) => _statusOf(c) == s).length;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleRow(p),
          const SizedBox(height: 24),
          _tabs(p, count),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: p.card(radius: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (customerProvider.isLoading)
                    const LinearProgressIndicator(
                      color: AppColors.gold,
                      backgroundColor: Colors.transparent,
                      minHeight: 3,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _searchField(p),
                  ),
                  Expanded(child: _table(p, pageRows)),
                  AppPaginationFooter(
                    totalItems: rows.length,
                    page: currentPage,
                    pageSize: _pageSize,
                    itemLabel: 'orders',
                    onPageChanged: (newPage) {
                      setState(() => _page = newPage);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // If the available height is too small, let the whole page scroll
    // vertically instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight >= _minPageHeight) {
          return content;
        }
        return SingleChildScrollView(
          child: SizedBox(
            height: _minPageHeight,
            width: constraints.maxWidth,
            child: content,
          ),
        );
      },
    );
  }

  Widget _titleRow(AppPalette p) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Management',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track, update and manage wholesale & retail custom frame orders',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.5, color: p.textMuted),
        ),
      ],
    );

    final addButton = AppPrimaryButton(
      label: 'Add New Customer',
      icon: RemixIcons.user_add_line,
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

  Widget _tabs(AppPalette p, int Function(Status?) count) {
    final items = <(String, Status?)>[
      ('All', null),
      ('Pending', Status.pending),
      ('In Progress', Status.inProgress),
      ('Completed', Status.completed),
      ('Cancelled', Status.cancelled),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (label, status) in items)
              InkWell(
                onTap: () {
                  setState(() {
                    _filter = status;
                    _page = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _filter == status
                            ? AppColors.gold
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    '$label (${count(status)})',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: _filter == status ? AppColors.gold : p.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchField(AppPalette p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SizedBox(
          height: 44,
          child: TextField(
            onChanged: (v) {
              setState(() {
                _query = v;
                _page = 1;
              });
            },
            cursorColor: p.textPrimary,
            style: TextStyle(fontSize: 14.5, color: p.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search order ID, customer name...',
              hintMaxLines: 1,
              hintStyle: TextStyle(
                fontSize: 14.5,
                color: p.textMuted,
                overflow: TextOverflow.ellipsis,
              ),
              prefixIcon: Icon(
                RemixIcons.search_line,
                size: 22,
                color: p.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _table(AppPalette p, List<Customer> rows) {
    return LayoutBuilder(
      builder: (context, c) {
        final tableWidth = math.max(c.maxWidth, _minTableWidth);

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
                height: c.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _headerRow(p),

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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (rows.isEmpty)
                                SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: Text(
                                      'No orders found',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: p.textMuted,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                for (var i = 0; i < rows.length; i++)
                                  _OrderRow(
                                    p: p,
                                    customer: rows[i],
                                    isLast: i == rows.length - 1,
                                    flex: _flex,
                                    status: _statusOf(rows[i]),
                                    statusColor: _statusColor,
                                    statusLabel: _statusLabel,
                                    payment: _paymentOf(rows[i]),
                                    paymentColor: _paymentColor,
                                    totalLabel: _money(rows[i].total),
                                    deliveryLabel:
                                        _statusOf(rows[i]) == Status.cancelled
                                        ? 'N/A'
                                        : _date(rows[i].expectedDelivery),
                                    onStatus: (s) async {
                                      final oldStatus = _statusOf(rows[i]);
                                      setState(
                                        () => _statusOverride[rows[i].id] = s,
                                      );
                                      try {
                                        await context
                                            .read<CustomerAndOrderProvider>()
                                            .setOrderStatus(rows[i], s);
                                        if (context.mounted) {
                                          AppSnackBar.success(
                                            context,
                                            'Order ${rows[i].id} status updated to ${s.label}.',
                                          );
                                        }
                                      } catch (error) {
                                        if (context.mounted) {
                                          setState(
                                            () => _statusOverride[rows[i].id] =
                                                oldStatus,
                                          );
                                          final msg = error is ApiException
                                              ? error.userFriendlyMessage
                                              : 'Could not update order status. Try again.';
                                          AppSnackBar.error(context, msg);
                                        }
                                      }
                                    },
                                    onView: () => showViewCustomerDialog(
                                      context,
                                      rows[i],
                                    ),
                                    onWhatsApp: () => _sendWhatsApp(rows[i]),
                                    onEdit: () => showEditCustomerDialog(
                                      context,
                                      rows[i],
                                    ),
                                    onDelete: () => _delete(rows[i]),
                                  ),
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
    );
  }

  Widget _headerRow(AppPalette p) {
    return Container(
      height: 50,
      color: p.tableHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: _tableHPadding),
      child: Row(
        children: [
          for (var i = 0; i < _headers.length; i++)
            Expanded(
              flex: _flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _headers[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: p.headerText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  const _OrderRow({
    required this.p,
    required this.customer,
    required this.isLast,
    required this.flex,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    required this.payment,
    required this.paymentColor,
    required this.totalLabel,
    required this.deliveryLabel,
    required this.onStatus,
    required this.onView,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onDelete,
  });

  final AppPalette p;
  final Customer customer;
  final bool isLast;
  final List<int> flex;
  final Status status;
  final Color Function(Status) statusColor;
  final String Function(Status) statusLabel;
  final String payment;
  final Color Function(String) paymentColor;
  final String totalLabel;
  final String deliveryLabel;
  final ValueChanged<Status> onStatus;
  final VoidCallback onView;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final c = widget.customer;
    final f = widget.flex;

    Widget cell(int i, Widget child) => Expanded(
      flex: f[i],
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );

    Widget txt(String s, TextStyle style) => Text(
      s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: style,
    );

    TextStyle body({FontWeight w = FontWeight.w500}) =>
        TextStyle(fontSize: 15, fontWeight: w, color: p.textPrimary);

    final spec = c.effectiveFrames.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _hover
              ? (p.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFFCFBF8))
              : Colors.transparent,
          border: widget.isLast
              ? null
              : Border(top: BorderSide(color: p.rowDivider)),
        ),
        child: Row(
          children: [
            cell(0, txt(c.id, body(w: FontWeight.w700))),
            cell(1, txt(c.name, body(w: FontWeight.w600))),
            cell(2, txt(c.phone, body())),

            cell(
              3,
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PhotoStrip(
                    customer: c,
                    count: c.photoCount,
                    urls: c.photoUrls.isNotEmpty
                        ? c.photoUrls
                        : [
                            for (final f in c.frames)
                              if (f.photoUrl != null && f.photoUrl!.isNotEmpty)
                                f.photoUrl!,
                          ],
                    bytes: c.photoBytes,
                    seed: c.id.hashCode,
                    onTap: widget.onView,
                  ),
                ),
              ),
            ),

            cell(
              4,
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  txt(c.frameSize, body()),
                  const SizedBox(height: 2),
                  txt(
                    c.frameType.isNotEmpty ? c.frameType : spec.frameType,
                    TextStyle(fontSize: 12.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            cell(5, txt('${c.qty}', body(w: FontWeight.w700))),
            cell(6, txt(widget.totalLabel, body(w: FontWeight.w700))),
            cell(7, _paymentChip()),
            cell(8, _statusDropdown()),
            cell(9, txt(widget.deliveryLabel, body())),
            cell(10, _actions()),
          ],
        ),
      ),
    );
  }

  Widget _paymentChip() {
    final color = widget.paymentColor(widget.payment);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        width: 120,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.payment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    final color = widget.statusColor(widget.status);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 138),
      child: PopupMenuButton<Status>(
        tooltip: '',
        onSelected: widget.onStatus,
        offset: const Offset(0, 38),
        color: widget.p.surface,
        itemBuilder: (_) => [
          for (final s in Status.values)
            PopupMenuItem(
              value: s,
              child: Text(
                widget.statusLabel(s),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.statusColor(s),
                ),
              ),
            ),
        ],
        child: Container(
          width: 138,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.statusLabel(widget.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(RemixIcons.arrow_down_s_line, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    final p = widget.p;
    const green = Color(0xFF25D366);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(
          icon: RemixIcons.eye_line,
          color: p.textPrimary,
          onTap: widget.onView,
        ),
        const SizedBox(width: 6),
        _iconBtn(
          icon: RemixIcons.whatsapp_fill,
          color: green,
          fill: green.withValues(alpha: p.isDark ? 0.22 : 0.18),
          size: 18,
          onTap: widget.onWhatsApp,
        ),
        const SizedBox(width: 6),
        _iconBtn(
          icon: RemixIcons.edit_line,
          color: p.textPrimary,
          onTap: widget.onEdit,
        ),
        const SizedBox(width: 6),
        _iconBtn(
          icon: RemixIcons.delete_bin_line,
          color: const Color(0xFFE05C58),
          onTap: widget.onDelete,
        ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color? fill,
    double size = 20,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
