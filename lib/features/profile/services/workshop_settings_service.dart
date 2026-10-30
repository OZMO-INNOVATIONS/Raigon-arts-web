import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';

class WorkshopProfile {
  const WorkshopProfile({
    required this.businessName,
    required this.tagline,
    required this.businessPhone,
    required this.businessEmail,
    required this.workshopAddress,
    required this.gstin,
    required this.businessHours,
  });

  final String businessName;
  final String tagline;
  final String businessPhone;
  final String businessEmail;
  final String workshopAddress;
  final String gstin;
  final List<dynamic> businessHours;

  factory WorkshopProfile.fromJson(Map<String, dynamic> json) =>
      WorkshopProfile(
        businessName: json['businessName'] as String? ?? 'RAIGON ART',
        tagline: json['tagline'] as String? ?? 'Photo Frames & Custom Framing',
        businessPhone: json['businessPhone'] as String? ?? '8137922114',
        businessEmail:
            json['businessEmail'] as String? ?? 'orders@raigonarts.com',
        workshopAddress:
            json['workshopAddress'] as String? ??
            'Main Workshop, MG Road, Trivandrum',
        gstin: json['gstin'] as String? ?? '',
        businessHours: json['businessHours'] as List? ?? const [],
      );

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'tagline': tagline,
    'businessPhone': businessPhone,
    'businessEmail': businessEmail,
    'workshopAddress': workshopAddress,
    'gstin': gstin,
  };
}

class RetentionPolicy {
  const RetentionPolicy({
    required this.retentionDays,
    required this.autoCleanupEnabled,
    required this.retentionTarget,
    this.cutoffDate,
    this.eligibleCustomersCount = 0,
    this.eligiblePhotosCount = 0,
  });

  final int retentionDays;
  final bool autoCleanupEnabled;
  final String retentionTarget;
  final String? cutoffDate;
  final int eligibleCustomersCount;
  final int eligiblePhotosCount;

  factory RetentionPolicy.fromJson(Map<String, dynamic> json) =>
      RetentionPolicy(
        retentionDays: (json['retentionDays'] as num?)?.toInt() ?? 45,
        autoCleanupEnabled: json['autoCleanupEnabled'] as bool? ?? true,
        retentionTarget: json['retentionTarget'] as String? ?? 'all',
        cutoffDate: json['cutoffDate'] as String?,
        eligibleCustomersCount:
            (json['eligibleCustomersCount'] as num?)?.toInt() ?? 0,
        eligiblePhotosCount:
            (json['eligiblePhotosCount'] as num?)?.toInt() ?? 0,
      );
}

class WorkshopSettingsService {
  WorkshopSettingsService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<WorkshopProfile> getProfile() async {
    final response = await _api.get(ApiConstants.workshopProfile);
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return WorkshopProfile.fromJson(map);
  }

  Future<WorkshopProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(ApiConstants.workshopProfile, body: data);
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return WorkshopProfile.fromJson(map);
  }

  Future<RetentionPolicy> getRetentionPolicy() async {
    final response = await _api.get(ApiConstants.retentionPolicy);
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return RetentionPolicy.fromJson(map);
  }

  Future<RetentionPolicy> updateRetentionPolicy({
    required int days,
    required bool enabled,
    String target = 'all',
  }) async {
    final response = await _api.put(
      ApiConstants.retentionPolicy,
      body: {'days': days, 'enabled': enabled, 'target': target},
    );
    final data = response is Map && response['data'] != null
        ? response['data']
        : response;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
    return RetentionPolicy.fromJson(map);
  }

  Future<Map<String, dynamic>> triggerManualCleanup({int? days}) async {
    final response = await _api.post(
      ApiConstants.cleanupTrigger,
      body: days != null ? {'days': days} : {},
    );
    return response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
  }
}
