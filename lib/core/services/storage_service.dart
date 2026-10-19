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

  factory UploadedFileResult.fromJson(Map<String, dynamic> json) =>
      UploadedFileResult(
        fileName: json['fileName'] as String? ?? '',
        fileUrl: json['fileUrl'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        mimeType: json['mimeType'] as String? ?? 'image/webp',
      );
}

class StorageService {
  StorageService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<UploadedFileResult> uploadFile(List<int> bytes, String fileName) async {
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
