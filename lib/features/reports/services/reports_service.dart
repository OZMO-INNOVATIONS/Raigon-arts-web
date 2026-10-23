import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';

class SalesTrajectory {
  const SalesTrajectory({
    required this.startDate,
    required this.endDate,
    required this.labels,
    required this.values,
    required this.dailyData,
  });

  final String startDate;
  final String endDate;
  final List<String> labels;
  final List<double> values;
  final List<Map<String, dynamic>> dailyData;

  factory SalesTrajectory.fromJson(Map<String, dynamic> json) => SalesTrajectory(
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    labels: [
      for (final l in (json['labels'] as List? ?? const [])) l.toString(),
    ],
    values: [
      for (final v in (json['values'] as List? ?? const []))
        (v as num?)?.toDouble() ?? 0.0,
    ],
    dailyData: [
      for (final d in (json['dailyData'] as List? ?? const []))
        if (d is Map) Map<String, dynamic>.from(d),
    ],
  );
}




class TopSellingSize {
  const TopSellingSize({
    required this.size,
    required this.count,
    required this.revenue,
  });

  final String size;
  final int count;
  final int revenue;

  factory TopSellingSize.fromJson(Map<String, dynamic> json) => TopSellingSize(
    size: json['size'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
    revenue: (json['revenue'] as num?)?.toInt() ?? 0,
  );
}

class ReportsSummary {
  const ReportsSummary({
    required this.period,
    required this.orderCount,
    required this.grossSales,
    required this.advanceCollected,
    required this.outstandingBalance,
    required this.topSellingSizes,
    required this.statusBreakdown,
    this.salesTrajectory,
  });

  final String period;
  final int orderCount;
  final int grossSales;
  final int advanceCollected;
  final int outstandingBalance;
  final List<TopSellingSize> topSellingSizes;
  final Map<String, int> statusBreakdown;
  final SalesTrajectory? salesTrajectory;

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, int>{};
    if (json['statusBreakdown'] is Map) {
      (json['statusBreakdown'] as Map).forEach((k, v) {
        breakdown[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    final topSizes = (json['topSellingSizes'] as List? ?? const [])
        .map((item) => TopSellingSize.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return ReportsSummary(
      period: json['period'] as String? ?? 'month1',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      grossSales: (json['grossSales'] as num?)?.toInt() ?? 0,
      advanceCollected: (json['advanceCollected'] as num?)?.toInt() ?? 0,
      outstandingBalance: (json['outstandingBalance'] as num?)?.toInt() ?? 0,
      topSellingSizes: topSizes,
      statusBreakdown: breakdown,
      salesTrajectory: json['salesTrajectory'] is Map
          ? SalesTrajectory.fromJson(Map<String, dynamic>.from(json['salesTrajectory'] as Map))
          : null,
    );
  }
}

class ReportsService {
  ReportsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<ReportsSummary> getSummary({String period = 'month1'}) async {
    final response = await _api.get(
      ApiConstants.reportsSummary,
      queryParameters: {'period': period},
    );
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return ReportsSummary.fromJson(map);
  }
}
