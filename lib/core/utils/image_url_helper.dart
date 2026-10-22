import 'package:raigon_art/core/network/api_constants.dart';

class ImageUrlHelper {
  const ImageUrlHelper._();

  /// Normalizes and resolves an image URL to a valid, accessible HTTP/HTTPS URL.
  /// - Converts legacy or mock 'cdn.raigonart.com' links to live Supabase Storage URLs.
  /// - Automatically transforms unreachable 'localhost:10000' / 'localhost:5001' URLs
  ///   to direct, public Supabase Storage bucket URLs or ApiConstants.serverHost.
  /// - Resolves relative '/uploads/...' paths.
  /// - Preserves blob:, data:, and valid HTTP/HTTPS URLs.
  static String resolve(String? url) {
    if (url == null) return '';
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    // 1. Blob / data URIs for local browser preview
    if (trimmed.startsWith('blob:') || trimmed.startsWith('data:')) {
      return trimmed;
    }

    // 2. Convert dead mock cdn.raigonart.com URLs to live Supabase Storage bucket URLs
    if (trimmed.contains('cdn.raigonart.com/')) {
      trimmed = trimmed
          .replaceAll(
            'https://cdn.raigonart.com/',
            'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/',
          )
          .replaceAll(
            'http://cdn.raigonart.com/',
            'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/',
          )
          .replaceAll(
            '//cdn.raigonart.com/',
            'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/',
          );
    }

    // 3. Convert unreachable localhost container URLs to live Supabase Storage or serverHost
    if (trimmed.contains('localhost:10000') ||
        trimmed.contains('127.0.0.1:10000') ||
        trimmed.contains('localhost:5001')) {
      // If it contains a customer uploads path e.g. /uploads/customers/RA-1004/photos/download.webp
      final customerPathMatch = RegExp(r'/uploads/(customers/[^?#]+)').firstMatch(trimmed);
      if (customerPathMatch != null) {
        final path = customerPathMatch.group(1)!;
        return 'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/$path';
      }

      trimmed = trimmed
          .replaceAll('http://localhost:10000', ApiConstants.serverHost)
          .replaceAll('https://localhost:10000', ApiConstants.serverHost)
          .replaceAll('http://127.0.0.1:10000', ApiConstants.serverHost)
          .replaceAll('https://127.0.0.1:10000', ApiConstants.serverHost)
          .replaceAll('http://localhost:5001', ApiConstants.serverHost)
          .replaceAll('https://localhost:5001', ApiConstants.serverHost);
    }

    // 4. Relative paths from backend server (/uploads/...)
    if (trimmed.startsWith('/uploads/')) {
      if (trimmed.startsWith('/uploads/customers/')) {
        final subPath = trimmed.replaceFirst('/uploads/', '');
        return 'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/$subPath';
      }
      return '${ApiConstants.serverHost}$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return '${ApiConstants.serverHost}$trimmed';
    }

    // 5. Storage bucket folder paths (customers/..., photos/...)
    if (trimmed.startsWith('customers/') ||
        trimmed.startsWith('photos/') ||
        trimmed.startsWith('thumbnails/')) {
      return 'https://nhqewkbztfmlophtzqmk.supabase.co/storage/v1/object/public/raigon-art-storage/$trimmed';
    }

    // 6. Already fully-qualified HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return '${ApiConstants.serverHost}/$trimmed';
  }
}
