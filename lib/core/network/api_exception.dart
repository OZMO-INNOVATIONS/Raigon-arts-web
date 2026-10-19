class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode = 500,
    this.errors = const [],
    this.rawResponse,
  });

  final String message;
  final int statusCode;
  final List<dynamic> errors;
  final dynamic rawResponse;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isBadRequest => statusCode == 400;
  bool get isNetworkError => statusCode == 0;
  bool get isTimeout => statusCode == 408;

  String get userFriendlyMessage {
    if (errors.isNotEmpty) {
      final fieldDetails = <String>[];
      for (final err in errors) {
        if (err is Map) {
          final field = err['field']?.toString();
          final msg = err['message']?.toString();
          if (field != null && msg != null) {
            fieldDetails.add('$field: $msg');
          } else if (msg != null) {
            fieldDetails.add(msg);
          }
        } else if (err != null) {
          fieldDetails.add(err.toString());
        }
      }
      if (fieldDetails.isNotEmpty) {
        return '$message: ${fieldDetails.join(', ')}';
      }
    }

    if (isNetworkError) {
      return message.isNotEmpty
          ? message
          : 'Unable to connect to the server. Please check your network connection.';
    }

    if (isTimeout) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    if (isUnauthorized) {
      return message.isNotEmpty && message.toLowerCase() != 'unauthorized'
          ? message
          : 'Invalid credentials or session expired. Please sign in again.';
    }

    if (isForbidden) {
      return 'Access denied. You do not have permission for this action.';
    }

    if (isNotFound) {
      return message.isNotEmpty && message.toLowerCase() != 'not found'
          ? message
          : 'The requested resource was not found.';
    }

    if (isConflict) {
      return message.isNotEmpty ? message : 'A conflict occurred. Record already exists.';
    }

    return message.isNotEmpty ? message : 'An error occurred (Status $statusCode).';
  }

  @override
  String toString() => 'ApiException($statusCode): $userFriendlyMessage';
}
