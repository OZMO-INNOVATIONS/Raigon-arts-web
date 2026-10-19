import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalCustomers,
    required this.totalRevenue,
    required this.totalAdvance,
    required this.pendingBalance,
    required this.statusCounts,
    required this.recentOrders,
  });

  final int totalCustomers;
  final int totalRevenue;
  final int totalAdvance;
  final int pendingBalance;
  final Map<String, int> statusCounts;
  final List<dynamic> recentOrders;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    if (json['statusCounts'] is Map) {
      (json['statusCounts'] as Map).forEach((k, v) {
        counts[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return DashboardStats(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      totalAdvance: (json['totalAdvance'] as num?)?.toInt() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toInt() ?? 0,
      statusCounts: counts,
      recentOrders: (json['recentOrders'] as List? ?? const []).toList(),
    );
  }
}

class DashboardService {
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<DashboardStats> getStats() async {
    final response = await _api.get(ApiConstants.dashboardStats);
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return DashboardStats.fromJson(map);
  }
}
