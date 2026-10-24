import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  bool _isRefreshing = false;
  static const Duration defaultTimeout = Duration(seconds: 25);
  static void Function()? onSessionExpired;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConstants.baseUrl}$cleanPath';
    final uri = Uri.parse(fullUrl);

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final sanitizedQuery = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        sanitizedQuery[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: sanitizedQuery);
  }

  Map<String, String> _buildHeaders({
    bool isJson = true,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (isJson) 'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = AuthTokenManager.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return decoded;
    }

    String message = 'Request failed with status ${response.statusCode}';
    List<dynamic> errors = const [];

    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
        message = decoded['message'].toString().trim();
      } else if (decoded['error'] != null && decoded['error'].toString().trim().isNotEmpty) {
        message = decoded['error'].toString().trim();
      } else if (decoded['details'] != null && decoded['details'].toString().trim().isNotEmpty) {
        message = decoded['details'].toString().trim();
      }
      if (decoded['errors'] is List) {
        errors = decoded['errors'] as List<dynamic>;
      }
    } else if (decoded is String && decoded.trim().isNotEmpty && !decoded.contains('<html')) {
      message = decoded.trim();
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      errors: errors,
      rawResponse: decoded,
    );
  }

  Future<T> _executeWithNetworkHandling<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('[ApiClient] ClientException: ${e.message}');
      throw ApiException(
        message: 'Cannot reach server. Please ensure the backend is running at ${ApiConstants.baseUrl}.',
        statusCode: 0,
      );
    } on TimeoutException {
      debugPrint('[ApiClient] TimeoutException');
      throw const ApiException(
        message: 'The request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      debugPrint('[ApiClient] Unexpected error: $e');
      if (e is ApiException) rethrow;
      final str = e.toString();
      final cleanMsg = str.contains('SocketException') || str.contains('Failed host lookup')
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Network request error: $e';
      throw ApiException(
        message: cleanMsg,
        statusCode: 0,
      );
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = AuthTokenManager.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty || _isRefreshing) {
      return false;
    }

    _isRefreshing = true;
    try {
      final refreshUri = _buildUri(ApiConstants.refresh);
      final response = await _http.post(
        refreshUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        final newToken = payload['token'] as String?;
        final newRefreshToken = payload['refreshToken'] as String?;

        if (newToken != null) {
          await AuthTokenManager.instance.updateTokens(
            token: newToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[ApiClient] Server rejected refresh token (${response.statusCode}). Session expired.');
        onSessionExpired?.call();
      }
      return false;
    } catch (e) {
      debugPrint('[ApiClient] Token refresh network note: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path, queryParameters);
      final headers = _buildHeaders(requiresAuth: requiresAuth);

      http.Response response = await _http.get(uri, headers: headers).timeout(defaultTimeout);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = _buildHeaders(requiresAuth: true);
          response = await _http.get(uri, headers: newHeaders).timeout(defaultTimeout);
        }
      }

      return _handleResponse(response);
    });
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);

      final encodedBody = body != null ? jsonEncode(body) : null;
      http.Response response = await _http
          .post(uri, headers: headers, body: encodedBody)
          .timeout(defaultTimeout);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = _buildHeaders(requiresAuth: true);
          response = await _http
              .post(uri, headers: newHeaders, body: encodedBody)
              .timeout(defaultTimeout);
        }
      }

      return _handleResponse(response);
    });
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);

      final encodedBody = body != null ? jsonEncode(body) : null;
      http.Response response = await _http
          .put(uri, headers: headers, body: encodedBody)
          .timeout(defaultTimeout);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = _buildHeaders(requiresAuth: true);
          response = await _http
              .put(uri, headers: newHeaders, body: encodedBody)
              .timeout(defaultTimeout);
        }
      }

      return _handleResponse(response);
    });
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);

      final encodedBody = body != null ? jsonEncode(body) : null;
      http.Response response = await _http
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(defaultTimeout);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = _buildHeaders(requiresAuth: true);
          response = await _http
              .patch(uri, headers: newHeaders, body: encodedBody)
              .timeout(defaultTimeout);
        }
      }

      return _handleResponse(response);
    });
  }

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);

      http.Response response =
          await _http.delete(uri, headers: headers).timeout(defaultTimeout);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = _buildHeaders(requiresAuth: true);
          response = await _http
              .delete(uri, headers: newHeaders)
              .timeout(defaultTimeout);
        }
      }

      return _handleResponse(response);
    });
  }

  Future<dynamic> sendMultipart({
    required String method,
    required String path,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool requiresAuth = true,
  }) async {
    return _executeWithNetworkHandling(() async {
      final uri = _buildUri(path);
      final request = http.MultipartRequest(method, uri);

      final headers = _buildHeaders(isJson: false, requiresAuth: requiresAuth);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryRequest = http.MultipartRequest(method, uri);
          final retryHeaders = _buildHeaders(
            isJson: false,
            requiresAuth: true,
          );
          retryRequest.headers.addAll(retryHeaders);
          if (fields != null) retryRequest.fields.addAll(fields);
          if (files != null) retryRequest.files.addAll(files);
          final retryStreamed =
              await retryRequest.send().timeout(const Duration(seconds: 60));
          final retryResponse = await http.Response.fromStream(retryStreamed);
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    });
  }
}
