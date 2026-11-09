import 'package:http/http.dart' as http;
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/core/network/media_type_helper.dart';

class UploadedFileResult {
  const UploadedFileResult({
    required this.fileName,
    required this.fileUrl,
    required this.thumbnailUrl,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String fileName;
  final String fileUrl;
  final String thumbnailUrl;
  final int sizeBytes;
  final String mimeType;

  factory UploadedFileResult.fromJson(Map<String, dynamic> json) {
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : json);
    return UploadedFileResult(
      fileName: map['fileName'] as String? ?? map['file_name'] as String? ?? '',
      fileUrl:
          map['fileUrl'] as String? ??
          map['file_url'] as String? ??
          map['url'] as String? ??
          '',
      thumbnailUrl:
          map['thumbnailUrl'] as String? ??
          map['thumbnail_url'] as String? ??
          '',
      sizeBytes: (map['sizeBytes'] ?? map['size_bytes'] as num?)?.toInt() ?? 0,
      mimeType:
          map['mimeType'] as String? ??
          map['mime_type'] as String? ??
          'image/webp',
    );
  }
}

class StorageService {
  StorageService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<UploadedFileResult> uploadFile(
    List<int> bytes,
    String fileName,
  ) async {
    final safeName = ensureImageFilename(fileName);
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: safeName,
      contentType: detectMediaType(safeName),
    );
    final response = await _api.sendMultipart(
      method: 'POST',
      path: ApiConstants.uploadStorage,
      files: [file],
    );
    final map = response is Map<String, dynamic>
        ? response
        : Map<String, dynamic>.from(response as Map);
    return UploadedFileResult.fromJson(map);
  }
}
