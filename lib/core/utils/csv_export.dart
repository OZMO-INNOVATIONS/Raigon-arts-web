import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<void> downloadCsv(String fileName, String content) async {
  debugPrint('WEB CSV DOWNLOAD START');
  debugPrint('File name: $fileName');
  debugPrint('Content length: ${content.length}');

  try {
    final bytes = Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(content),
    ]);

    debugPrint('Bytes created: ${bytes.length}');

    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );

    debugPrint('Blob created successfully');

    final url = web.URL.createObjectURL(blob);
    debugPrint('Object URL created');
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body?.append(anchor);
    debugPrint('Download anchor appended');
    anchor.click();
    debugPrint('Download triggered');
    anchor.remove();
    web.URL.revokeObjectURL(url);
    debugPrint('Object URL revoked');
    debugPrint('WEB CSV DOWNLOAD SUCCESS');
  } catch (e, stackTrace) {
    debugPrint('WEB CSV DOWNLOAD ERROR');
    debugPrint('Error: $e');
    debugPrint('Type: ${e.runtimeType}');
    debugPrint('$stackTrace');

    rethrow;
  }
}
