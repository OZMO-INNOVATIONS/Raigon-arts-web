import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> compressImageWeb(Uint8List bytes) async {
  final image = web.HTMLImageElement()
    ..src = 'data:image/jpeg;base64,${base64Encode(bytes)}';

  await image.decode().toDart;

  final originalWidth = image.naturalWidth;
  final originalHeight = image.naturalHeight;

  if (originalWidth == 0 || originalHeight == 0) {
    throw StateError('Unable to decode image.');
  }

  const maxDimension = 1200;

  final scale =
      (originalWidth > originalHeight
              ? maxDimension / originalWidth
              : maxDimension / originalHeight)
          .clamp(0.0, 1.0);

  final width = (originalWidth * scale).round().clamp(1, maxDimension);
  final height = (originalHeight * scale).round().clamp(1, maxDimension);

  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;

  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  context.drawImage(image, 0, 0, width, height);

  final completer = Completer<web.Blob?>();

  canvas.toBlob(
    (web.Blob? blob) {
      if (!completer.isCompleted) {
        completer.complete(blob);
      }
    }.toJS,
    'image/jpeg',
    0.70.toJS,
  );

  final blob = await completer.future;

  if (blob == null) {
    throw StateError('Unable to encode compressed image.');
  }

  final buffer = await blob.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
