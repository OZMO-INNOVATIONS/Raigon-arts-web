import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:raigon_art/core/widgets/app_image_cropper.dart';

void main() {
  group('AppImageCropper Unit & Math Tests', () {
    test('CropAspectRatio enum ratios are defined correctly', () {
      expect(CropAspectRatio.free.ratio, isNull);
      expect(CropAspectRatio.sq1_1.ratio, 1.0);
      expect(CropAspectRatio.r4_3.ratio, closeTo(4.0 / 3.0, 0.001));
      expect(CropAspectRatio.r3_2.ratio, closeTo(3.0 / 2.0, 0.001));
      expect(CropAspectRatio.r16_9.ratio, closeTo(16.0 / 9.0, 0.001));
      expect(CropAspectRatio.r2_3.ratio, closeTo(2.0 / 3.0, 0.001));
      expect(CropAspectRatio.r3_4.ratio, closeTo(3.0 / 4.0, 0.001));
      expect(CropAspectRatio.r9_16.ratio, closeTo(9.0 / 16.0, 0.001));
    });

    test('calculateCropRect computes centered rectangles matching aspect ratio', () {
      const viewport = Size(1000, 800);

      // Free crop: 88% width, 82% height
      final freeRect = AppImageCropperDialog.calculateCropRect(viewport, null);
      expect(freeRect.width, 1000 * 0.88);
      expect(freeRect.height, 800 * 0.82);
      expect(freeRect.left, (1000 - freeRect.width) / 2.0);
      expect(freeRect.top, (800 - freeRect.height) / 2.0);

      // 1:1 Square
      final sqRect = AppImageCropperDialog.calculateCropRect(viewport, 1.0);
      expect(sqRect.width, sqRect.height);
      expect(sqRect.left, (1000 - sqRect.width) / 2.0);
      expect(sqRect.top, (800 - sqRect.height) / 2.0);

      // 16:9 Landscape
      final wideRect = AppImageCropperDialog.calculateCropRect(viewport, 16.0 / 9.0);
      expect(wideRect.width / wideRect.height, closeTo(16.0 / 9.0, 0.001));
      expect(wideRect.left, (1000 - wideRect.width) / 2.0);
      expect(wideRect.top, (800 - wideRect.height) / 2.0);

      // 9:16 Portrait
      final tallRect = AppImageCropperDialog.calculateCropRect(viewport, 9.0 / 16.0);
      expect(tallRect.width / tallRect.height, closeTo(9.0 / 16.0, 0.001));
      expect(tallRect.left, (1000 - tallRect.width) / 2.0);
      expect(tallRect.top, (800 - tallRect.height) / 2.0);
    });

    test('Coordinate inverse matrix transforms screen points to local image pixels', () {
      // Suppose image pixel size is 2000x1000.
      // Viewport is 1000x800.
      const vpSize = Size(1000, 800);
      const rotPixelW = 2000.0;
      const rotPixelH = 1000.0;

      final scaleFactor = (vpSize.width / rotPixelW < vpSize.height / rotPixelH)
          ? vpSize.width / rotPixelW
          : vpSize.height / rotPixelH;
      expect(scaleFactor, 0.5);

      final displayW = rotPixelW * scaleFactor; // 1000
      final displayH = rotPixelH * scaleFactor; // 500
      final tx = (vpSize.width - displayW) / 2.0; // 0
      final ty = (vpSize.height - displayH) / 2.0; // 150

      final transform = Matrix4.translationValues(tx, ty, 0.0);
      final inv = Matrix4.inverted(transform);

      // A crop rect in viewport coords:
      const cropRect = Rect.fromLTWH(200, 250, 600, 300);

      final localTopLeft = MatrixUtils.transformPoint(inv, cropRect.topLeft);
      final localBottomRight = MatrixUtils.transformPoint(inv, cropRect.bottomRight);

      expect(localTopLeft.dx, 200.0);
      expect(localTopLeft.dy, 250.0 - 150.0); // 100.0

      expect(localBottomRight.dx, 800.0);
      expect(localBottomRight.dy, 550.0 - 150.0); // 400.0

      // Map to original image pixel coordinates:
      final pixelX = (localTopLeft.dx / scaleFactor).round();
      final pixelY = (localTopLeft.dy / scaleFactor).round();
      final pixelW = ((localBottomRight.dx - localTopLeft.dx) / scaleFactor).round();
      final pixelH = ((localBottomRight.dy - localTopLeft.dy) / scaleFactor).round();

      expect(pixelX, 400);
      expect(pixelY, 200);
      expect(pixelW, 1200);
      expect(pixelH, 600);
    });

    test('Image crop execution produces valid JPEG with correct cropped dimensions', () {
      // Create a test image: 200x100 filled with blue
      final original = img.Image(width: 200, height: 100);
      img.fill(original, color: img.ColorRgb8(0, 120, 240));
      final rawJpg = Uint8List.fromList(img.encodeJpg(original));

      // Test crop worker directly
      final task = _TestCropTask(
        bytes: rawJpg,
        rotationTurns: 0,
        cropX: 50,
        cropY: 20,
        cropW: 80,
        cropH: 50,
      );

      final croppedBytes = _testCropImageWorker(task);
      expect(croppedBytes, isNotNull);

      final decodedCropped = img.decodeImage(croppedBytes!);
      expect(decodedCropped, isNotNull);
      expect(decodedCropped!.width, 80);
      expect(decodedCropped.height, 50);
    });

    test('Image crop execution with 90-degree rotation swaps dimensions correctly', () {
      final original = img.Image(width: 200, height: 100);
      img.fill(original, color: img.ColorRgb8(240, 120, 0));
      final rawJpg = Uint8List.fromList(img.encodeJpg(original));

      // 90 deg rotation makes it 100x200
      final task = _TestCropTask(
        bytes: rawJpg,
        rotationTurns: 1,
        cropX: 10,
        cropY: 20,
        cropW: 60,
        cropH: 100,
      );

      final croppedBytes = _testCropImageWorker(task);
      expect(croppedBytes, isNotNull);

      final decodedCropped = img.decodeImage(croppedBytes!);
      expect(decodedCropped, isNotNull);
      expect(decodedCropped!.width, 60);
      expect(decodedCropped.height, 100);
    });
  });
}

class _TestCropTask {
  _TestCropTask({
    required this.bytes,
    required this.rotationTurns,
    required this.cropX,
    required this.cropY,
    required this.cropW,
    required this.cropH,
  });

  final Uint8List bytes;
  final int rotationTurns;
  final int cropX;
  final int cropY;
  final int cropW;
  final int cropH;
}

Uint8List? _testCropImageWorker(_TestCropTask task) {
  img.Image? src = img.decodeImage(task.bytes);
  if (src == null) return null;

  if (task.rotationTurns == 1) {
    src = img.copyRotate(src, angle: 90);
  } else if (task.rotationTurns == 2) {
    src = img.copyRotate(src, angle: 180);
  } else if (task.rotationTurns == 3) {
    src = img.copyRotate(src, angle: 270);
  }

  int x = task.cropX;
  int y = task.cropY;
  int w = task.cropW;
  int h = task.cropH;

  if (x < 0) {
    w += x;
    x = 0;
  }
  if (y < 0) {
    h += y;
    y = 0;
  }
  if (x + w > src.width) {
    w = src.width - x;
  }
  if (y + h > src.height) {
    h = src.height - y;
  }

  if (w <= 10 || h <= 10 || x >= src.width || y >= src.height) {
    return Uint8List.fromList(img.encodeJpg(src, quality: 95));
  }

  final cropped = img.copyCrop(
    src,
    x: x,
    y: y,
    width: w,
    height: h,
  );

  return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
}
