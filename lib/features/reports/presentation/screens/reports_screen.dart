import 'dart:math' as math;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_dropdown.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/core/models/status.dart';

enum ReportPeriod { month1, month2, allTime }

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String _inr(int v) {
  final s = v.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return v < 0 ? '-$out' : out;
}

String _money(int v) => '₹${_inr(v)}';

const _months = [
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

String _date(DateTime d) =>
    '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

String _shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

DateTime _deliveryOf(Customer c) => c.expectedDelivery ?? c.orderDate;

String _materialOf(Customer c) {
  final frames = c.effectiveFrames;
  if (frames.isEmpty) return c.frameType.trim().isEmpty ? '—' : c.frameType;
  final first = frames.first.material.trim();
  final base = first.isEmpty ? '—' : first;
  return frames.length > 1 ? '$base +${frames.length - 1} more' : base;
}

// ---------------------------------------------------------------------------
// Report data (everything is computed from the real customer list)
// ---------------------------------------------------------------------------

class ShareItem {
  const ShareItem(this.label, this.count, this.fraction);

  final String label;
  final int count;
  final double fraction;

  int get percent => (fraction * 100).round();
}

class ChartSeries {
  const ChartSeries(this.labels, this.values);

  final List<String> labels;
  final List<double> values;
}

class ReportData {
  ReportData({
    required List<Customer> customers,
    required this.period,
    DateTime? now,
  }) : allCustomers = customers,
       now = now ?? DateTime.now();

  final List<Customer> allCustomers;
  final ReportPeriod period;
  final DateTime now;

  // ----- labels -----

  static String dropdownLabel(ReportPeriod period, DateTime now) {
    switch (period) {
      case ReportPeriod.month1:
        return 'Last 1 Month (${_rangeText(period, now)})';
      case ReportPeriod.month2:
        return 'Last 2 Months (${_rangeText(period, now)})';
      case ReportPeriod.allTime:
        return 'All-Time Historical (Includes Archived)';
    }
  }

  static String _rangeText(ReportPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final days = period == ReportPeriod.month1 ? 30 : 60;
    final start = DateTime(today.year, today.month, today.day - (days - 1));
    return '${_shortDate(start)} - ${_date(today)}';
  }

  String get rangeLabel {
    switch (period) {
      case ReportPeriod.month1:
        return 'Last 30 Days (${_rangeText(period, now)})';
      case ReportPeriod.month2:
        return 'Last 60 Days (${_rangeText(period, now)})';
      case ReportPeriod.allTime:
        return 'All-Time Historical (Includes Archived)';
    }
  }

  String get chartTitle => 'Sales Trajectory ($rangeLabel)';

  // ----- date window -----

  DateTime get today => DateTime(now.year, now.month, now.day);

  DateTime get endExclusive => DateTime(today.year, today.month, today.day + 1);

  DateTime get startDate {
    switch (period) {
      case ReportPeriod.month1:
        return DateTime(today.year, today.month, today.day - 29);
      case ReportPeriod.month2:
        return DateTime(today.year, today.month, today.day - 59);
      case ReportPeriod.allTime:
        return DateTime(2000);
    }
  }

  // Cancelled orders never count as business.
  late final List<Customer> _billable = allCustomers
      .where((c) => c.status != Status.cancelled)
      .toList();

  bool _inRange(Customer c, DateTime from, DateTime to) {
    final d = DateTime(c.orderDate.year, c.orderDate.month, c.orderDate.day);
    return !d.isBefore(from) && d.isBefore(to);
  }

  int _sumTotal(DateTime from, DateTime to) => _billable
      .where((c) => _inRange(c, from, to))
      .fold(0, (sum, c) => sum + c.total);

  late final List<Customer> periodCustomers = _billable
      .where((c) => _inRange(c, startDate, endExclusive))
      .toList();

  // ----- metrics -----

  int get billed => periodCustomers.fold(0, (sum, c) => sum + c.total);

  int get advance => periodCustomers.fold(0, (sum, c) => sum + c.advance);

  int get outstanding =>
      periodCustomers.fold(0, (sum, c) => sum + math.max(0, c.balance));

  int get orders => periodCustomers.length;

  int get aov => orders == 0 ? 0 : (billed / orders).round();

  double get collectionRatio => billed <= 0 ? 0 : (advance / billed) * 100;

  String get ratioLabel => '${collectionRatio.toStringAsFixed(1)}%';

  /// Revenue growth: current window vs the window of the same length before it.
  /// For "all time" the last 30 days are compared with the 30 days before.
  double? get growthPct {
    final n = period == ReportPeriod.month1
        ? 30
        : (period == ReportPeriod.month2 ? 60 : 30);
    final curFrom = DateTime(today.year, today.month, today.day - (n - 1));
    final prevFrom = DateTime(today.year, today.month, today.day - (2 * n - 1));
    final cur = _sumTotal(curFrom, endExclusive);
    final prev = _sumTotal(prevFrom, curFrom);
    if (prev == 0) return null;
    return (cur - prev) / prev * 100;
  }

  bool get growthPositive => (growthPct ?? 0) >= 0;

  String get growthLabel {
    final g = growthPct;
    if (g == null) return 'No prior period data';
    final sign = g >= 0 ? '+' : '';
    return '$sign${g.toStringAsFixed(1)}% growth';
  }

  // ----- active / archived -----

  List<Customer> get activeCustomers {
    final cutoff = now.subtract(const Duration(days: 7));

    return periodCustomers.where((c) {
      final isArchived =
          c.status == Status.completed && _deliveryOf(c).isBefore(cutoff);
      return !isArchived;
    }).toList()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  List<Customer> get archivedCustomers {
    final cutoff = now.subtract(const Duration(days: 7));

    return periodCustomers.where((c) {
      return c.status == Status.completed && _deliveryOf(c).isBefore(cutoff);
    }).toList()..sort((a, b) => _deliveryOf(b).compareTo(_deliveryOf(a)));
  }

  // ----- chart -----

  ChartSeries get chart {
    if (period == ReportPeriod.allTime) return _monthlyChart();

    final bucketDays = period == ReportPeriod.month1 ? 5 : 10;
    final start = startDate;
    final labels = <String>[];
    final values = <double>[];

    for (var i = 0; i < 6; i++) {
      final from = DateTime(start.year, start.month, start.day + i * bucketDays);
      final to = DateTime(
        start.year,
        start.month,
        start.day + (i + 1) * bucketDays,
      );
      labels.add(_shortDate(from));
      values.add(_sumTotal(from, to).toDouble());
    }
    return ChartSeries(labels, values);
  }

  ChartSeries _monthlyChart() {
    final cur = DateTime(now.year, now.month);
    var first = cur;

    for (final c in periodCustomers) {
      final m = DateTime(c.orderDate.year, c.orderDate.month);
      if (m.isBefore(first)) first = m;
    }

    var months = <DateTime>[];
    for (
      var m = first;
      !m.isAfter(cur);
      m = DateTime(m.year, m.month + 1)
    ) {
      months.add(m);
    }
    if (months.length > 12) months = months.sublist(months.length - 12);
    if (months.length < 2) {
      months.insert(0, DateTime(cur.year, cur.month - 1));
    }

    final labels = <String>[];
    final values = <double>[];
    for (final m in months) {
      final suffix = m.year != now.year
          ? " '${(m.year % 100).toString().padLeft(2, '0')}"
          : '';
      labels.add('${_months[m.month - 1]}$suffix');

      final sum = periodCustomers
          .where(
            (c) => c.orderDate.year == m.year && c.orderDate.month == m.month,
          )
          .fold<int>(0, (a, c) => a + c.total);
      values.add(sum.toDouble());
    }
    return ChartSeries(labels, values);
  }

  // ----- frame size / material share -----

  /// Quantity of a frame row. For single-frame orders the order-level qty is
  /// used (it already includes qty x number of photos).
  int _qtyOf(Customer c, int frameQty, int frameCount) =>
      frameCount == 1 ? c.qty : frameQty;

  Map<String, int> get frameSizeCounts {
    final counts = <String, int>{};
    for (final c in periodCustomers) {
      final frames = c.effectiveFrames;
      for (final f in frames) {
        final label = f.sizeLabel.trim();
        if (label.isEmpty) continue;
        counts[label] = (counts[label] ?? 0) + _qtyOf(c, f.qty, frames.length);
      }
    }
    return counts;
  }

  Map<String, int> get materialCounts {
    final counts = <String, int>{};
    for (final c in periodCustomers) {
      final frames = c.effectiveFrames;
      for (final f in frames) {
        final material = f.material.trim();
        if (material.isEmpty) continue;
        counts[material] =
            (counts[material] ?? 0) + _qtyOf(c, f.qty, frames.length);
      }
    }
    return counts;
  }

  List<ShareItem> _shares(Map<String, int> counts, int maxItems) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const [];

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    final items = <ShareItem>[];
    if (entries.length <= maxItems) {
      for (final e in entries) {
        items.add(ShareItem(e.key, e.value, e.value / total));
      }
    } else {
      for (final e in entries.take(maxItems - 1)) {
        items.add(ShareItem(e.key, e.value, e.value / total));
      }
      final rest = entries
          .skip(maxItems - 1)
          .fold<int>(0, (a, e) => a + e.value);
      items.add(ShareItem('Other', rest, rest / total));
    }
    return items;
  }

  List<ShareItem> get topFrameSizes => _shares(frameSizeCounts, 4);

  List<ShareItem> get topMaterials => _shares(materialCounts, 4);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.month1;
  bool _showArchived = false;

  static const _goldText = Color(0xFFB49A55);
  static const _red = Color(0xFFE0605E);

  Future<void> _exportPdf(
    ReportData d,
    List<Customer> active,
    List<Customer> archived,
  ) async {
    try {
      final sizes = d.topFrameSizes;
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(32),
          build: (_) => [
            pw.Text(
              'Raigon Arts - Reports & Business Analytics',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(d.rangeLabel, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            _pdfTable(
              ['Metric', 'Value'],
              [
                ['Total Billed Revenue', 'Rs. ${_inr(d.billed)}'],
                ['Advance Collected', 'Rs. ${_inr(d.advance)}'],
                ['Outstanding Balance Due', 'Rs. ${_inr(d.outstanding)}'],
                ['Average Order Value (AOV)', 'Rs. ${_inr(d.aov)}'],
                ['Orders Analyzed', '${d.orders}'],
                ['Growth', d.growthLabel],
                ['Collection Ratio', d.ratioLabel],
              ],
            ),
            if (sizes.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text(
                'Top Frame Sizes Sold',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _pdfTable(
                ['Frame Size', 'Quantity', 'Share'],
                [
                  for (final s in sizes)
                    [s.label, '${s.count}', '${s.percent}%'],
                ],
              ),
            ],
            pw.SizedBox(height: 18),
            pw.Text(
              'Active Customers (${active.length})',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              ['Customer', 'Phone', 'Frame', 'Billed', 'Advance', 'Balance'],
              [
                for (final c in active)
                  [
                    c.name,
                    c.phone,
                    c.frameSize,
                    'Rs. ${_inr(c.total)}',
                    'Rs. ${_inr(c.advance)}',
                    'Rs. ${_inr(math.max(0, c.balance))}',
                  ],
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Archived Completed >7 Days (${archived.length})',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfTable(
              ['Customer', 'Order', 'Frame', 'Delivery', 'Settled'],
              [
                for (final c in archived)
                  [
                    c.name,
                    c.id,
                    '${c.frameSize} - ${_materialOf(c)}',
                    _date(_deliveryOf(c)),
                    'Rs. ${_inr(c.advance)}',
                  ],
              ],
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      await FileSaver.instance.saveFile(
        name: 'Raigon_Report_${_period.name}',
        bytes: bytes,
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Report exported successfully.');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final customerProvider = context.watch<CustomerAndOrderProvider>();
    final report = ReportData(
      customers: customerProvider.customers,
      period: _period,
    );
    final active = report.activeCustomers;
    final archived = report.archivedCustomers;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(p, report, active, archived),
          const SizedBox(height: 24),
          _filterBar(p, report),
          const SizedBox(height: 24),
          _metricRow(p, report),
          const SizedBox(height: 26),
          _chartRow(p, report),
          const SizedBox(height: 26),
          _customerCard(p, active, archived),
        ],
      ),
    );
  }

  Widget _titleRow(
    AppPalette p,
    ReportData d,
    List<Customer> active,
    List<Customer> arch,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Business Analytics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track custom framing sales performance, revenue metrics, payment collections, and 7-day auto-archived order history',
          style: TextStyle(fontSize: 14.5, color: p.textMuted),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDropdown<ReportPeriod>(
          value: _period,
          items: ReportPeriod.values,
          labelOf: (x) => ReportData.dropdownLabel(x, d.now),
          onChanged: (v) => setState(() => _period = v),
          width: 233,
        ),
        const SizedBox(width: 10),
        _GradientButton(
          icon: Icons.picture_as_pdf,
          label: 'Export PDF Summary',
          onTap: () => _exportPdf(d, active, arch),
          fontSize: 15.5,
          vPad: 14,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 16), controls],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            controls,
          ],
        );
      },
    );
  }

  Widget _filterBar(AppPalette p, ReportData d) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 15, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Filter Mode',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    final policy = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info, size: 14, color: p.textMuted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Auto-Archive Policy: Orders completed & delivered >7 days ago are stored permanently in Reports',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: p.card(radius: 16),
      child: Row(
        children: [
          pill,
          const SizedBox(width: 12),
          Text(
            d.rangeLabel,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: policy),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(AppPalette p, ReportData d) {
    final growthColor = d.growthPositive ? AppPalette.statusGreen : _red;
    final cards = <Widget>[
      _MetricCard(
        label: 'TOTAL BILLED REVENUE',
        value: _money(d.billed),
        tile: _tile(
          const Color(0xFFDDF6E7),
          Icons.show_chart,
          AppPalette.statusGreen,
        ),
        badge: _badge(
          p,
          d.growthLabel,
          growthColor,
          icon: d.growthPositive ? Icons.trending_up : Icons.trending_down,
        ),
      ),
      _MetricCard(
        label: 'ADVANCE COLLECTED',
        value: _money(d.advance),
        tile: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.darkGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.savings, size: 22, color: Colors.white),
        ),
        badge: _badge(p, '${d.ratioLabel} Collection Ratio', _goldText),
      ),
      _MetricCard(
        label: 'OUTSTANDING BALANCE DUE',
        value: _money(d.outstanding),
        danger: true,
        tile: _tile(const Color(0xFFFBE3E3), Icons.volunteer_activism, _red),
        badge: _badge(
          p,
          'Actionable Dues',
          _red,
          icon: Icons.warning_amber_rounded,
        ),
      ),
      _MetricCard(
        label: 'AVERAGE ORDER VALUE (AOV)',
        value: _money(d.aov),
        tile: _tile(const Color(0xFFF7EFD9), Icons.receipt_long, _goldText),
        badge: _badge(
          p,
          '${d.orders} ${d.orders == 1 ? 'Order' : 'Orders'} Analyzed',
          _goldText,
          icon: Icons.shopping_bag,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 26.0;
        final cols = c.maxWidth >= 1000 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final x in cards) SizedBox(width: w, child: x)],
        );
      },
    );
  }

  Widget _tile(Color bg, IconData icon, Color fg) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: 22, color: fg),
  );

  Widget _badge(AppPalette p, String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartRow(AppPalette p, ReportData d) {
    return LayoutBuilder(
      builder: (context, c) {
        final chart = _salesCard(p, d);
        final sizes = _topSizesCard(p, d);
        if (c.maxWidth < 1000) {
          return Column(children: [chart, const SizedBox(height: 26), sizes]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: chart),
              const SizedBox(width: 27),
              Expanded(flex: 5, child: sizes),
            ],
          ),
        );
      },
    );
  }

  Widget _salesCard(AppPalette p, ReportData d) {
    final series = d.chart;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: p.card(radius: 16),
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
                      d.chartTitle,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.period == ReportPeriod.allTime
                          ? 'Monthly billed revenue trajectory'
                          : 'Billed revenue trajectory (per '
                                '${d.period == ReportPeriod.month1 ? '5' : '10'}'
                                '-day period)',
                      style: TextStyle(fontSize: 13, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Revenue (₹)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.isDark ? AppColors.gold : _goldText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF25273D) : p.chipFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_period),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _TrajectoryPainter(
                  values: series.values,
                  labels: series.labels,
                  progress: t,
                  dark: p.isDark,
                  muted: p.textMuted,
                  strong: p.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topSizesCard(AppPalette p, ReportData d) {
    final goldPct = p.isDark ? AppColors.gold : _goldText;
    final track = p.isDark ? const Color(0xFF1F2135) : p.chipFill;

    final sizes = d.topFrameSizes;
    final materials = d.topMaterials;

    final rowStyles = <(Color, Decoration)>[
      (goldPct, const BoxDecoration(gradient: AppColors.darkGradient)),
      (
        AppPalette.statusGreen,
        const BoxDecoration(color: AppPalette.statusGreen),
      ),
      (AppPalette.teal, const BoxDecoration(color: AppPalette.teal)),
      (const Color(0xFFF2A04E), const BoxDecoration(color: Color(0xFFF2A04E))),
    ];

    final chipStyles = <(Color, Color)>[
      (
        p.isDark ? const Color(0xFF4A4A52) : const Color(0xFFF5EFE0),
        goldPct,
      ),
      (const Color(0xFFD8F5E3), const Color(0xFF3FB866)),
      (const Color(0xFFD9F3F8), AppPalette.teal),
      (const Color(0xFFFDEBDD), const Color(0xFFF2A04E)),
    ];

    Widget row(ShareItem item, Color pctColor, Decoration fill) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.label} (${item.count})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.percent}% of volume',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: pctColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: track,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: item.fraction.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: fill,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget chip(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg),
      ),
    );

    Widget emptyNote(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(text, style: TextStyle(fontSize: 14, color: p.textMuted)),
    );

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: p.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Frame Sizes Sold',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sales volume breakdown by frame size',
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
          const SizedBox(height: 22),
          if (sizes.isEmpty)
            emptyNote('No frame orders in this period.')
          else
            for (var i = 0; i < sizes.length; i++)
              row(sizes[i], rowStyles[i % rowStyles.length].$1,
                  rowStyles[i % rowStyles.length].$2),
          const SizedBox(height: 2),
          Divider(height: 1, color: p.rowDivider),
          const SizedBox(height: 18),
          Text(
            'Popular Material Types',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (materials.isEmpty)
            Text(
              'No material data in this period.',
              style: TextStyle(fontSize: 14, color: p.textMuted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < materials.length; i++)
                  chip(
                    '${materials[i].label} (${materials[i].percent}%)',
                    chipStyles[i % chipStyles.length].$1,
                    chipStyles[i % chipStyles.length].$2,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _customerCard(
    AppPalette p,
    List<Customer> active,
    List<Customer> archived,
  ) {
    final header = LayoutBuilder(
      builder: (context, c) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 22, color: AppColors.gold),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Customer Revenue & 7-Day Auto-Archived History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Orders completed & delivered >7 days ago are auto-removed from active list but permanently viewable here in Reports',
              style: TextStyle(fontSize: 13, color: p.textMuted),
            ),
          ],
        );
        final toggle = _tabToggle(p, active.length, archived.length);
        if (c.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), toggle],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            toggle,
          ],
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: p.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 18),
          if (_showArchived) ...[
            _banner(archived.length),
            const SizedBox(height: 14),
            archived.isEmpty
                ? _emptyState(p, 'No archived orders in this period.')
                : _archivedTable(p, archived),
          ] else
            active.isEmpty
                ? _emptyState(p, 'No active customers in this period.')
                : _activeTable(p, active),
        ],
      ),
    );
  }

  Widget _emptyState(AppPalette p, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: 15, color: p.textMuted)),
    );
  }

  Widget _tabToggle(AppPalette p, int activeN, int archivedN) {
    Widget btn(IconData icon, String label, bool selected, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.darkGradient : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: !selected && p.isDark ? Border.all(color: p.border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : p.textPrimary,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF20223A) : p.chipFill,
        borderRadius: BorderRadius.circular(12),
        border: p.isDark ? Border.all(color: p.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            Icons.groups,
            'Active Customers ($activeN)',
            !_showArchived,
            () => setState(() => _showArchived = false),
          ),
          const SizedBox(width: 4),
          btn(
            Icons.archive,
            'Archived Completed (>7 Days) ($archivedN)',
            _showArchived,
            () => setState(() => _showArchived = true),
          ),
        ],
      ),
    );
  }

  Widget _banner(int n) {
    const green = Color(0xFF2F9E5B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF6E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: AppPalette.statusGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing $n framing orders completed & delivered >7 days ago. Auto-removed from main Customers view, permanently preserved in owner reports.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableShell(
    AppPalette p,
    List<String> heads,
    List<int> flex,
    List<List<Widget>> rows,
  ) {
    Widget cell(int i, Widget w) => Expanded(
      flex: flex[i],
      child: Align(
        alignment: i == flex.length - 1
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: w,
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.max(c.maxWidth, 1000.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: p.tableHeaderBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < heads.length; i++)
                        cell(
                          i,
                          Text(
                            heads[i],
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
                    ],
                  ),
                ),
                for (var r = 0; r < rows.length; r++)
                  Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: r == 0
                          ? null
                          : Border(top: BorderSide(color: p.rowDivider)),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < rows[r].length; i++)
                          cell(i, rows[r][i]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avatar(AppPalette p, String name, {bool green = false}) {
    final fg = green ? AppPalette.statusGreen : AppColors.gold;
    final bg = green
        ? AppPalette.statusGreen.withValues(alpha: 0.16)
        : (p.isDark ? const Color(0xFF3E3F52) : p.avatarBg);
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _nameCell(
    AppPalette p,
    String name,
    String sub, {
    bool green = false,
  }) {
    return Row(
      children: [
        _avatar(p, name, green: green),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: p.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activeTable(AppPalette p, List<Customer> list) {
    TextStyle t(FontWeight w, [double s = 15.5, Color? c]) =>
        TextStyle(fontSize: s, fontWeight: w, color: c ?? p.textPrimary);

    final rows = <List<Widget>>[
      for (final c in list)
        [
          _nameCell(p, c.name, c.city),
          Text(c.phone, style: t(FontWeight.w500)),
          Text(c.frameSize, style: t(FontWeight.w500, 14)),
          Text(_money(c.total), style: t(FontWeight.w700)),
          Text(
            _money(c.advance),
            style: t(FontWeight.w600, 15.5, AppPalette.statusGreen),
          ),
          c.balance <= 0
              ? Text(
                  '₹0 (Settled)',
                  style: t(FontWeight.w600, 15.5, AppPalette.statusGreen),
                )
              : Text(_money(c.balance), style: t(FontWeight.w600, 15.5, _red)),
          _statusChip(
            c.balance <= 0 ? 'Fully Paid' : 'Pending Due',
            c.balance <= 0 ? AppPalette.statusGreen : _goldText,
          ),
          c.balance <= 0
              ? _paidButton(p)
              : _GradientButton(
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: 'Remind',
                  onTap: () {},
                  fontSize: 14.5,
                  vPad: 10,
                  radius: 8,
                ),
        ],
    ];

    return _tableShell(
      p,
      const [
        'CUSTOMER NAME',
        'PHONE NO',
        'FRAME DETAILS',
        'TOTAL BILLED',
        'ADVANCE PAID',
        'BALANCE DUE',
        'PAYMENT STATUS',
        'ACTION',
      ],
      const [16, 11, 12, 11, 12, 12, 13, 13],
      rows,
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      width: 124,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paidButton(AppPalette p) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF3A3C55) : p.chipFill,
        borderRadius: BorderRadius.circular(8),
        border: p.isDark ? Border.all(color: p.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 18, color: p.textPrimary),
          const SizedBox(width: 8),
          Text(
            'Paid',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _archivedTable(AppPalette p, List<Customer> list) {
    TextStyle t(FontWeight w, [double s = 15.5, Color? c]) =>
        TextStyle(fontSize: s, fontWeight: w, color: c ?? p.textPrimary);
    const green = AppPalette.statusGreen;

    final rows = <List<Widget>>[
      for (final c in list)
        [
          _nameCell(p, c.name, 'ID: ${c.id}', green: true),
          Text(c.phone, style: t(FontWeight.w500)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.frameSize, style: t(FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                _materialOf(c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: p.textMuted),
              ),
            ],
          ),
          Text(_date(_deliveryOf(c)), style: t(FontWeight.w500, 13.5, green)),
          c.balance <= 0
              ? Text(
                  '${_money(c.total)} (Paid)',
                  style: t(FontWeight.w700, 15.5, green),
                )
              : Text(
                  '${_money(c.advance)} (${_money(c.balance)} due)',
                  style: t(FontWeight.w700, 14, _red),
                ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.archive, size: 15, color: green),
                SizedBox(width: 8),
                Text(
                  'Archived (> 7d)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: p.isDark ? const Color(0xFF3A3C55) : p.chipFill,
                borderRadius: BorderRadius.circular(8),
                border: p.isDark ? Border.all(color: p.border) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, size: 17, color: p.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'View Record',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    ];

    return _tableShell(
      p,
      const [
        'ARCHIVED CUSTOMER',
        'PHONE NO',
        'FRAME ORDER DETAILS',
        'DELIVERY DATE',
        'AMOUNT SETTLED',
        'ARCHIVE STATUS',
        'REPORT RECORD',
      ],
      const [16, 11, 17, 12, 14, 16, 14],
      rows,
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.tile,
    required this.badge,
    this.danger = false,
  });

  final String label;
  final String value;
  final Widget tile;
  final Widget badge;
  final bool danger;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final highlight = widget.danger && _hover && !p.isDark;
    final deco = p.card(radius: 16);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        decoration: deco.copyWith(
          border: Border.all(
            color: highlight
                ? const Color(0xFFE0605E).withValues(alpha: 0.45)
                : p.border,
          ),
        ),
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
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: p.headerText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                widget.tile,
              ],
            ),
            const SizedBox(height: 14),
            widget.badge,
          ],
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.dark,
    required this.muted,
    required this.strong,
  });

  final List<double> values;
  final List<String> labels;
  final double progress;
  final bool dark;
  final Color muted;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const padX = 65.0;
    const top = 59.0;
    const bottom = 78.0;

    final baseY = size.height - bottom;
    final plotH = baseY - top;
    final w = size.width - padX * 2;
    final rawMax = values.reduce(math.max);
    final maxV = rawMax <= 0 ? 1.0 : rawMax;

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          padX + w * i / (values.length - 1),
          baseY - (values[i] / maxV) * plotH * progress,
        ),
    ];

    final grid = Paint()
      ..color = dark
          ? Colors.white.withValues(alpha: 0.85)
          : const Color(0xFFD4D0C4)
      ..strokeWidth = 1.2;
    for (final f in const [0.4, 0.8]) {
      final y = baseY - plotH * f;
      var x = padX;
      while (x < size.width - padX) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 5, size.width - padX), y),
          grid,
        );
        x += 10;
      }
    }

    final area = Path()..moveTo(pts.first.dx, baseY);
    for (final o in pts) {
      area.lineTo(o.dx, o.dy);
    }
    area
      ..lineTo(pts.last.dx, baseY)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: dark ? 0.45 : 0.28),
            AppColors.gold.withValues(alpha: dark ? 0.02 : 0.04),
          ],
        ).createShader(Rect.fromLTRB(0, top, size.width, baseY)),
    );

    canvas.drawLine(
      Offset(padX, baseY),
      Offset(size.width - padX, baseY),
      Paint()
        ..color = dark
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFFE3DED2)
        ..strokeWidth = dark ? 2 : 1.5,
    );

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < pts.length; i++) {
      final last = i == pts.length - 1;
      if (last) {
        canvas.drawCircle(pts[i], 8, Paint()..color = AppColors.gold);
        canvas.drawCircle(
          pts[i],
          8,
          Paint()
            ..color = const Color(0xFF14141F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      } else {
        canvas.drawCircle(pts[i], 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          pts[i],
          5.5,
          Paint()
            ..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      }
    }

    for (var i = 0; i < labels.length; i++) {
      final last = i == labels.length - 1;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 15,
            fontWeight: last ? FontWeight.w700 : FontWeight.w500,
            color: last ? strong : muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = padX + w * i / (labels.length - 1);
      tp.paint(canvas, Offset(x - tp.width / 2, baseY + 14));
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) =>
      old.progress != progress ||
      old.dark != dark ||
      old.values != values ||
      old.labels != labels;
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.fontSize = 15,
    this.vPad = 13,
    this.radius = 10,
  });

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  final double fontSize;
  final double vPad;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: vPad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

pw.Widget _pdfCell(String t, {bool bold = false}) => pw.Padding(
  padding: const pw.EdgeInsets.all(5),
  child: pw.Text(
    t,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

pw.Widget _pdfTable(List<String> heads, List<List<String>> rows) => pw.Table(
  border: pw.TableBorder.all(color: pdf.PdfColors.grey400, width: 0.5),
  children: [
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey200),
      children: [for (final h in heads) _pdfCell(h, bold: true)],
    ),
    for (final r in rows)
      pw.TableRow(children: [for (final c in r) _pdfCell(c)]),
  ],
);