import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Data passed from the Reports screen (plain values, no UI dependencies)
// ---------------------------------------------------------------------------

class PdfShare {
  const PdfShare(this.label, this.count, this.fraction);

  final String label;
  final int count;
  final double fraction;

  int get percent => (fraction * 100).round();
}

class PdfActiveRow {
  const PdfActiveRow({
    required this.name,
    required this.city,
    required this.phone,
    required this.frame,
    required this.total,
    required this.advance,
    required this.balance,
  });

  final String name;
  final String city;
  final String phone;
  final String frame;
  final int total;
  final int advance;
  final int balance;
}

class PdfArchivedRow {
  const PdfArchivedRow({
    required this.name,
    required this.orderId,
    required this.phone,
    required this.frame,
    required this.material,
    required this.delivery,
    required this.total,
    required this.advance,
    required this.balance,
  });

  final String name;
  final String orderId;
  final String phone;
  final String frame;
  final String material;
  final String delivery;
  final int total;
  final int advance;
  final int balance;
}

class ReportPdfData {
  const ReportPdfData({
    required this.rangeLabel,
    required this.chartTitle,
    required this.chartSubtitle,
    required this.generatedAt,
    required this.billed,
    required this.advance,
    required this.outstanding,
    required this.highestOrder,
    required this.orders,
    required this.aov,
    required this.collectionRatio,
    required this.growthLabel,
    required this.hasGrowth,
    required this.growthPositive,
    required this.chartLabels,
    required this.chartValues,
    required this.frameSizes,
    required this.materials,
    required this.active,
    required this.archived,
  });

  final String rangeLabel;
  final String chartTitle;
  final String chartSubtitle;
  final DateTime generatedAt;

  final int billed;
  final int advance;
  final int outstanding;
  final int highestOrder;
  final int orders;
  final int aov;
  final double collectionRatio;

  final String growthLabel;
  final bool hasGrowth;
  final bool growthPositive;

  final List<String> chartLabels;
  final List<double> chartValues;

  final List<PdfShare> frameSizes;
  final List<PdfShare> materials;

  final List<PdfActiveRow> active;
  final List<PdfArchivedRow> archived;
}

// ---------------------------------------------------------------------------
// Palette (matches the app: black + gold, warm neutrals)
// ---------------------------------------------------------------------------

class _C {
  static final black = pdf.PdfColor.fromInt(0xFF0B0B0B);
  static final ink = pdf.PdfColor.fromInt(0xFF1E1E2E);
  static final gold = pdf.PdfColor.fromInt(0xFFB49A55);
  static final goldLight = pdf.PdfColor.fromInt(0xFFCDBB88);
  static final goldSoft = pdf.PdfColor.fromInt(0xFFF7EFD9);
  static final cream = pdf.PdfColor.fromInt(0xFFF8F6F2);
  static final headerBg = pdf.PdfColor.fromInt(0xFFF3EEE0);
  static final border = pdf.PdfColor.fromInt(0xFFE6E0D2);
  static final track = pdf.PdfColor.fromInt(0xFFEFEBE2);
  static final muted = pdf.PdfColor.fromInt(0xFF7C7B8C);
  static final green = pdf.PdfColor.fromInt(0xFF2F9E5B);
  static final greenSoft = pdf.PdfColor.fromInt(0xFFE3F6EA);
  static final red = pdf.PdfColor.fromInt(0xFFD9534F);
  static final teal = pdf.PdfColor.fromInt(0xFF2BB3C6);
  static final orange = pdf.PdfColor.fromInt(0xFFF28C38);
  static final white = pdf.PdfColors.white;
}

// ---------------------------------------------------------------------------
// Formatting helpers (ASCII only: the built-in PDF fonts have no rupee glyph)
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

String _rs(int v) => 'Rs. ${_inr(v)}';

String _compact(double v) {
  if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.round().toString();
}

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

String _dateOnly(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

String _timeOnly(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h12:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

// ---------------------------------------------------------------------------
// Template
// ---------------------------------------------------------------------------

class ReportPdfTemplate {
  const ReportPdfTemplate._();

  static Future<Uint8List> build(ReportPdfData d) async {
    final doc = pw.Document(
      title: 'Raigon Arts - Reports & Business Analytics',
      author: 'Raigon Arts',
      creator: 'Raigon Arts',
      subject: d.rangeLabel,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 40),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            italic: pw.Font.helveticaOblique(),
            boldItalic: pw.Font.helveticaBoldOblique(),
          ),
        ),
        header: (ctx) => _runningHeader(ctx),
        footer: (ctx) => _footer(ctx, d),
        build: (ctx) => [
          _hero(d),
          pw.SizedBox(height: 16),
          _kpiRow(d),
          _section(
            'Financial Summary',
            'Collections and billing for the selected period',
          ),
          _collectionCard(d),
          pw.SizedBox(height: 10),
          _summaryTable(d),
          _section(d.chartTitle, d.chartSubtitle),
          _chartCard(d),
          _section('Sales Mix', 'Volume breakdown by frame size and material'),
          _mixRow(d),
          _section(
            'Active Customers (${d.active.length})',
            'Orders in the selected period, excluding cancelled orders',
          ),
          if (d.active.isEmpty)
            _empty('No active customers in this period.')
          else
            _activeTable(d),
          _section(
            'Archived Completed > 7 Days (${d.archived.length})',
            'Delivered more than 7 days ago and permanently preserved in reports',
          ),
          if (d.archived.isEmpty)
            _empty('No archived orders in this period.')
          else
            _archivedTable(d),
          pw.SizedBox(height: 18),
          _notes(),
        ],
      ),
    );

    return doc.save();
  }

  // ----- page chrome -----

  static pw.Widget _runningHeader(pw.Context ctx) {
    if (ctx.pageNumber == 1) return pw.SizedBox();
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'RAIGON ARTS',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.8,
                color: _C.gold,
              ),
            ),
            pw.Text(
              'Reports & Business Analytics',
              style: pw.TextStyle(fontSize: 8, color: _C.muted),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 0.8, color: _C.border),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx, ReportPdfData d) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 8),
        pw.Container(height: 0.8, color: _C.border),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Raigon Arts  |  Confidential owner report  |  Generated ${_dateOnly(d.generatedAt)}',
              style: pw.TextStyle(fontSize: 7.5, color: _C.muted),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: _C.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----- hero -----

  static pw.Widget _hero(ReportPdfData d) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: _C.black,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 36, height: 3, color: _C.gold),
                pw.SizedBox(height: 10),
                pw.Text(
                  'RAIGON ARTS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2.4,
                    color: _C.goldLight,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Reports & Business Analytics',
                  style: pw.TextStyle(
                    fontSize: 21,
                    fontWeight: pw.FontWeight.bold,
                    color: _C.white,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  d.rangeLabel,
                  style: pw.TextStyle(fontSize: 10, color: _C.goldLight),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'GENERATED',
                style: pw.TextStyle(
                  fontSize: 7,
                  letterSpacing: 1.4,
                  color: _C.goldLight,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _dateOnly(d.generatedAt),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _C.white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _timeOnly(d.generatedAt),
                style: pw.TextStyle(fontSize: 8.5, color: _C.goldLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----- KPI cards -----

  static pw.Widget _kpiRow(ReportPdfData d) {
    final growthColor = !d.hasGrowth
        ? _C.muted
        : (d.growthPositive ? _C.green : _C.red);

    final cards = <pw.Widget>[
      _kpi('TOTAL BILLED', _rs(d.billed), d.growthLabel, _C.green, growthColor),
      _kpi(
        'ADVANCE COLLECTED',
        _rs(d.advance),
        '${d.collectionRatio.toStringAsFixed(1)}% collection ratio',
        _C.gold,
        _C.gold,
      ),
      _kpi(
        'OUTSTANDING DUE',
        _rs(d.outstanding),
        'Actionable dues',
        _C.red,
        _C.red,
      ),
      _kpi(
        'HIGHEST ORDER',
        _rs(d.highestOrder),
        '${d.orders} ${d.orders == 1 ? 'order' : 'orders'} analyzed',
        _C.orange,
        _C.muted,
      ),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 8),
          pw.Expanded(child: cards[i]),
        ],
      ],
    );
  }

  static pw.Widget _kpi(
    String label,
    String value,
    String note,
    pdf.PdfColor accent,
    pdf.PdfColor noteColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: pw.BoxDecoration(
        color: _C.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 18, height: 2.5, color: accent),
          pw.SizedBox(height: 8),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
              color: _C.muted,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: _C.black,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            note,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: noteColor,
            ),
          ),
        ],
      ),
    );
  }

  // ----- sections -----

  static pw.Widget _section(String title, [String? subtitle]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 3, height: 24, color: _C.gold),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _C.black,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(fontSize: 8, color: _C.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _empty(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 22),
      decoration: pw.BoxDecoration(
        color: _C.cream,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _C.muted)),
      ),
    );
  }

  // ----- collection + summary -----

  static pw.Widget _collectionCard(ReportPdfData d) {
    final collected = d.billed <= 0
        ? 0
        : ((d.advance / d.billed) * 100).round().clamp(0, 100).toInt();

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _C.cream,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Collection progress',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _C.black,
                ),
              ),
              pw.Text(
                '${d.collectionRatio.toStringAsFixed(1)}% collected',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _C.gold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Row(
              children: [
                if (collected > 0)
                  pw.Expanded(
                    flex: collected,
                    child: pw.Container(height: 7, color: _C.gold),
                  ),
                if (collected < 100)
                  pw.Expanded(
                    flex: 100 - collected,
                    child: pw.Container(height: 7, color: _C.track),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Collected ${_rs(d.advance)}',
                style: pw.TextStyle(fontSize: 8, color: _C.muted),
              ),
              pw.Text(
                'Outstanding ${_rs(d.outstanding)}',
                style: pw.TextStyle(fontSize: 8, color: _C.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryTable(ReportPdfData d) {
    final rows = <List<String>>[
      ['Total billed revenue', _rs(d.billed)],
      ['Advance collected', _rs(d.advance)],
      ['Outstanding balance due', _rs(d.outstanding)],
      ['Highest value order', _rs(d.highestOrder)],
      ['Orders analyzed', '${d.orders}'],
      ['Average order value', _rs(d.aov)],
      ['Revenue growth', d.growthLabel],
      ['Collection ratio', '${d.collectionRatio.toStringAsFixed(1)}%'],
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            for (var i = 0; i < rows.length; i++)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i.isEven ? _C.white : _C.cream,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: pw.Text(
                      rows[i][0],
                      style: pw.TextStyle(fontSize: 9, color: _C.muted),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        rows[i][1],
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _C.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ----- chart -----

  static pw.Widget _chartCard(ReportPdfData d) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _C.cream,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: _C.gold,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Text(
                'Billed revenue (Rs.)',
                style: pw.TextStyle(fontSize: 7.5, color: _C.muted),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: _C.black,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Text(
                'Latest period',
                style: pw.TextStyle(fontSize: 7.5, color: _C.muted),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _barChart(d.chartLabels, d.chartValues),
        ],
      ),
    );
  }

  static pw.Widget _barChart(List<String> labels, List<double> values) {
    final n = math.min(labels.length, values.length);
    final maxV = n == 0 ? 0.0 : values.take(n).reduce(math.max);

    if (maxV <= 0) {
      return pw.SizedBox(
        height: 80,
        child: pw.Center(
          child: pw.Text(
            'No billed revenue in this period.',
            style: pw.TextStyle(fontSize: 9, color: _C.muted),
          ),
        ),
      );
    }

    const maxBar = 92.0;
    final gap = n > 8 ? 2.0 : 6.0;

    return pw.SizedBox(
      height: 140,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            pw.Expanded(
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: gap),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      values[i] > 0 ? _compact(values[i]) : '',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _C.ink,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      height: values[i] > 0
                          ? math.max(2.0, values[i] / maxV * maxBar)
                          : 1.5,
                      decoration: pw.BoxDecoration(
                        color: i == n - 1 ? _C.black : _C.gold,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(2),
                          topRight: pw.Radius.circular(2),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      labels[i],
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 6.8,
                        fontWeight: i == n - 1
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: i == n - 1 ? _C.black : _C.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----- sales mix -----

  static pw.Widget _mixRow(ReportPdfData d) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _mixCard(
            'Top frame sizes',
            d.frameSizes,
            'No frame orders in this period.',
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _mixCard(
            'Popular materials',
            d.materials,
            'No material data in this period.',
          ),
        ),
      ],
    );
  }

  static pw.Widget _mixCard(String title, List<PdfShare> items, String empty) {
    final colors = [_C.gold, _C.green, _C.teal, _C.orange];

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _C.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.9,
              color: _C.muted,
            ),
          ),
          pw.SizedBox(height: 10),
          if (items.isEmpty)
            pw.Text(empty, style: pw.TextStyle(fontSize: 8.5, color: _C.muted))
          else
            for (var i = 0; i < items.length; i++)
              _shareRow(items[i], colors[i % colors.length]),
        ],
      ),
    );
  }

  static pw.Widget _shareRow(PdfShare s, pdf.PdfColor color) {
    final fill = (s.fraction * 100).round().clamp(1, 100).toInt();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${s.label} (${s.count})',
                  maxLines: 1,
                  style: pw.TextStyle(fontSize: 8.5, color: _C.ink),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                '${s.percent}%',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.ClipRRect(
            horizontalRadius: 2,
            verticalRadius: 2,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: fill,
                  child: pw.Container(height: 5, color: color),
                ),
                if (fill < 100)
                  pw.Expanded(
                    flex: 100 - fill,
                    child: pw.Container(height: 5, color: _C.track),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- tables -----

  static pw.Widget _text(
    String t, {
    bool bold = false,
    pdf.PdfColor? color,
    double size = 8.5,
  }) {
    return pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _C.ink,
      ),
    );
  }

  static pw.Widget _badge(String text, pdf.PdfColor fg, pdf.PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  static pw.Widget _person(String name, String sub) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _text(name, bold: true, color: _C.black),
        if (sub.trim().isNotEmpty) ...[
          pw.SizedBox(height: 1.5),
          _text(sub, size: 7, color: _C.muted),
        ],
      ],
    );
  }

  static pw.Widget _dataTable({
    required List<String> heads,
    required Map<int, pw.TableColumnWidth> widths,
    required List<List<pw.Widget>> rows,
    required List<pw.Widget> footer,
    Set<int> rightCols = const {},
  }) {
    pw.Widget cell(int col, pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Align(
        alignment: rightCols.contains(col)
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
        child: child,
      ),
    );

    return pw.Table(
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _C.black),
          children: [
            for (var i = 0; i < heads.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 8,
                ),
                child: pw.Align(
                  alignment: rightCols.contains(i)
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                  child: pw.Text(
                    heads[i],
                    style: pw.TextStyle(
                      fontSize: 6.8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.7,
                      color: _C.goldLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: r.isEven ? _C.white : _C.cream),
            children: [
              for (var i = 0; i < rows[r].length; i++) cell(i, rows[r][i]),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _C.headerBg),
          children: [
            for (var i = 0; i < footer.length; i++) cell(i, footer[i]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _activeTable(ReportPdfData d) {
    final totalBilled = d.active.fold<int>(0, (a, r) => a + r.total);
    final totalAdvance = d.active.fold<int>(0, (a, r) => a + r.advance);
    final totalBalance = d.active.fold<int>(0, (a, r) => a + r.balance);

    return _dataTable(
      heads: const [
        'CUSTOMER',
        'PHONE',
        'FRAME',
        'BILLED',
        'ADVANCE',
        'BALANCE',
        'STATUS',
      ],
      widths: {
        0: const pw.FlexColumnWidth(2.3),
        1: const pw.FlexColumnWidth(1.6),
        2: const pw.FlexColumnWidth(1.7),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(1.4),
        6: const pw.FlexColumnWidth(1.3),
      },
      rightCols: const {3, 4, 5},
      rows: [
        for (final r in d.active)
          [
            _person(r.name, r.city),
            _text(r.phone),
            _text(r.frame),
            _text(_rs(r.total), bold: true, color: _C.black),
            _text(_rs(r.advance), color: _C.green),
            _text(
              r.balance <= 0 ? 'Settled' : _rs(r.balance),
              bold: true,
              color: r.balance <= 0 ? _C.green : _C.red,
            ),
            r.balance <= 0
                ? _badge('PAID', _C.green, _C.greenSoft)
                : _badge('PENDING', _C.gold, _C.goldSoft),
          ],
      ],
      footer: [
        _text('TOTAL (${d.active.length})', bold: true, color: _C.black),
        _text(''),
        _text(''),
        _text(_rs(totalBilled), bold: true, color: _C.black),
        _text(_rs(totalAdvance), bold: true, color: _C.green),
        _text(_rs(totalBalance), bold: true, color: _C.red),
        _text(''),
      ],
    );
  }

  static pw.Widget _archivedTable(ReportPdfData d) {
    final totalSettled = d.archived.fold<int>(
      0,
      (a, r) => a + (r.balance <= 0 ? r.total : r.advance),
    );

    return _dataTable(
      heads: const [
        'CUSTOMER',
        'PHONE',
        'FRAME / MATERIAL',
        'DELIVERED',
        'SETTLED',
        'STATUS',
      ],
      widths: {
        0: const pw.FlexColumnWidth(2.3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(1.3),
      },
      rightCols: const {4},
      rows: [
        for (final r in d.archived)
          [
            _person(r.name, 'ID: ${r.orderId}'),
            _text(r.phone),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _text(r.frame, bold: true, color: _C.black),
                pw.SizedBox(height: 1.5),
                _text(r.material, size: 7, color: _C.muted),
              ],
            ),
            _text(r.delivery),
            r.balance <= 0
                ? _text(_rs(r.total), bold: true, color: _C.green)
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _text(_rs(r.advance), bold: true, color: _C.black),
                      pw.SizedBox(height: 1.5),
                      _text('${_rs(r.balance)} due', size: 7, color: _C.red),
                    ],
                  ),
            _badge('ARCHIVED', _C.green, _C.greenSoft),
          ],
      ],
      footer: [
        _text('TOTAL (${d.archived.length})', bold: true, color: _C.black),
        _text(''),
        _text(''),
        _text(''),
        _text(_rs(totalSettled), bold: true, color: _C.green),
        _text(''),
      ],
    );
  }

  // ----- notes -----

  static pw.Widget _notes() {
    pw.Widget bullet(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3,
            height: 3,
            margin: const pw.EdgeInsets.only(top: 3.5, right: 6),
            decoration: pw.BoxDecoration(
              color: _C.gold,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              t,
              style: pw.TextStyle(fontSize: 7.5, color: _C.muted),
            ),
          ),
        ],
      ),
    );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _C.cream,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _C.border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTES',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
              color: _C.gold,
            ),
          ),
          pw.SizedBox(height: 7),
          bullet(
            'All amounts are in Indian Rupees (Rs.). Cancelled orders are excluded from every figure.',
          ),
          bullet(
            'Auto-archive policy: orders completed and delivered more than 7 days ago are removed from the active customer list and kept permanently in reports.',
          ),
          bullet(
            'Growth compares the selected period with the previous period of the same length.',
          ),
        ],
      ),
    );
  }
}
