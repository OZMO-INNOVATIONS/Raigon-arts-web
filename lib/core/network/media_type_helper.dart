import 'package:http_parser/http_parser.dart';

/// Detects MediaType according to file extension for multipart uploads.
/// Ensures that uploads are sent with explicit MIME types (e.g. image/jpeg, image/png)
/// rather than defaulting to application/octet-stream which multer rejects.
MediaType detectMediaType(String filename) {
  final parts = filename.split('.');
  final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
  switch (ext) {
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'heic':
      return MediaType('image', 'heic');
    case 'pdf':
      return MediaType('application', 'pdf');
    case 'jpg':
    case 'jpeg':
    default:
      return MediaType('image', 'jpeg');
  }
}

/// Ensures the filename has an allowed extension (jpg, jpeg, png, webp, heic, pdf)
/// so that backend multer fileFilter does not reject it.
String ensureImageFilename(String filename, [String defaultExt = 'jpg']) {
  if (filename.isEmpty) return 'photo.$defaultExt';
  if (!filename.contains('.')) {
    return '$filename.$defaultExt';
  }
  final ext = filename.split('.').last.toLowerCase();
  const allowed = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'];
  if (!allowed.contains(ext)) {
    return '$filename.$defaultExt';
  }
  return filename;
}
