import 'package:flutter/foundation.dart';

class Helper {
  const Helper();

  static const _months = [
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

  static const _fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static String formatExpectedDate(DateTime d) {
    final dayStr = d.day.toString().padLeft(2, '0');
    final monthStr = _fullMonths[d.month - 1];
    return '$dayStr $monthStr ${d.year}';
  }

  // Instagram connection debugging
  static const bool debugInstagram = true;

  static void igLog(
    String action, {
    String? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!debugInstagram || !kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer('[IG_DEBUG][$timestamp] $action');

    if (details != null && details.isNotEmpty) {
      buffer.write(' | $details');
    }

    debugPrint(buffer.toString());

    if (error != null) {
      debugPrint('[IG_DEBUG] ERROR: $error');
    }

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
