import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/utils/image_url_helper.dart';

enum CropAspectRatio {
  free('Free', null),
  sq1_1('1:1', 1.0),
  r4_3('4:3', 4.0 / 3.0),
  r3_2('3:2', 3.0 / 2.0),
  r16_9('16:9', 16.0 / 9.0),
  r2_3('2:3', 2.0 / 3.0),
  r3_4('3:4', 3.0 / 4.0),
  r9_16('9:16', 9.0 / 16.0);

  const CropAspectRatio(this.label, this.ratio);
  final String label;
  final double? ratio;
}

Future<Uint8List?> showAppImageCropper({
  required BuildContext context,
  Uint8List? bytes,
  String? url,
  String title = 'Crop Artwork Image',
}) async {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AppImageCropperDialog(
      initialBytes: bytes,
      imageUrl: url,
      title: title,
    ),
  );
}

class AppImageCropperDialog extends StatefulWidget {
  const AppImageCropperDialog({
    super.key,
    this.initialBytes,
    this.imageUrl,
    this.title = 'Crop Artwork Image',
  });

  final Uint8List? initialBytes;
  final String? imageUrl;
  final String title;

  static Rect calculateCropRect(Size viewportSize, double? aspectRatio) {
    double frameW = viewportSize.width * 0.88;
    double frameH = viewportSize.height * 0.82;

    if (aspectRatio != null && aspectRatio > 0) {
      if (frameW / frameH > aspectRatio) {
        frameW = frameH * aspectRatio;
      } else {
        frameH = frameW / aspectRatio;
      }
    }

    final double frameX = (viewportSize.width - frameW) / 2.0;
    final double frameY = (viewportSize.height - frameH) / 2.0;
    return Rect.fromLTWH(frameX, frameY, frameW, frameH);
  }

  @override
  State<AppImageCropperDialog> createState() => _AppImageCropperDialogState();
}

class _AppImageCropperDialogState extends State<AppImageCropperDialog> {
  Uint8List? _rawBytes;
  img.Image? _decodedImage;
  bool _isLoading = true;
  String? _errorMessage;

  CropAspectRatio _selectedRatio = CropAspectRatio.free;
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3
  final TransformationController _transformController = TransformationController();
  final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(1.0);
  bool _isProcessing = false;

  Size? _viewportSize;
  bool _hasInitializedTransform = false;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasInitializedTransform = false;
    });

    try {
      Uint8List? bytes = widget.initialBytes;
      if ((bytes == null || bytes.isEmpty) && widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        final resolved = ImageUrlHelper.resolve(widget.imageUrl!);
        final resp = await http.get(Uri.parse(resolved));
        if (resp.statusCode == 200) {
          bytes = resp.bodyBytes;
        } else {
          throw Exception('Failed to download image (HTTP ${resp.statusCode})');
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No valid image data provided for cropping.');
      }

      final decoded = kIsWeb
          ? img.decodeImage(bytes)
          : await compute(_decodeImageIsolate, bytes);

      if (decoded == null) {
        throw Exception('Could not decode image format.');
      }

      if (mounted) {
        setState(() {
          _rawBytes = bytes;
          _decodedImage = decoded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  static img.Image? _decodeImageIsolate(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  void _centerImage({Size? viewportSize}) {
    final vp = viewportSize ?? _viewportSize;
    if (_decodedImage == null || vp == null || vp.width <= 0 || vp.height <= 0) return;

    final rotTurns = _rotationQuarterTurns;
    final rawW = _decodedImage!.width.toDouble();
    final rawH = _decodedImage!.height.toDouble();
    final rotPixelW = (rotTurns % 2 == 1) ? rawH : rawW;
    final rotPixelH = (rotTurns % 2 == 1) ? rawW : rawH;

    final scaleFactor = math.min(
      vp.width / rotPixelW,
      vp.height / rotPixelH,
    );
    final displayW = rotPixelW * scaleFactor;
    final displayH = rotPixelH * scaleFactor;

    final tx = (vp.width - displayW) / 2.0;
    final ty = (vp.height - displayH) / 2.0;

    _transformController.value = Matrix4.translationValues(tx, ty, 0.0);
    _scaleNotifier.value = 1.0;
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _centerImage();
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _selectedRatio = CropAspectRatio.free;
      _centerImage();
    });
  }

  void _zoomBy(double factor) {
    if (_viewportSize == null) return;
    final center = Offset(_viewportSize!.width / 2.0, _viewportSize!.height / 2.0);
    final zoomMatrix = Matrix4.translationValues(center.dx, center.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0))
      ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));

    _transformController.value = zoomMatrix * _transformController.value;
    _scaleNotifier.value = _transformController.value.getMaxScaleOnAxis();
  }

  Future<void> _executeCrop() async {
    if (_decodedImage == null || _rawBytes == null || _viewportSize == null) return;
    setState(() => _isProcessing = true);

    try {
      final rotTurns = _rotationQuarterTurns;
      final rawW = _decodedImage!.width.toDouble();
      final rawH = _decodedImage!.height.toDouble();
      final rotPixelW = (rotTurns % 2 == 1) ? rawH : rawW;
      final rotPixelH = (rotTurns % 2 == 1) ? rawW : rawH;

      final scaleFactor = math.min(
        _viewportSize!.width / rotPixelW,
        _viewportSize!.height / rotPixelH,
      );

      final cropRect = AppImageCropperDialog.calculateCropRect(_viewportSize!, _selectedRatio.ratio);
      final inv = Matrix4.inverted(_transformController.value);

      final localTopLeft = MatrixUtils.transformPoint(inv, cropRect.topLeft);
      final localBottomRight = MatrixUtils.transformPoint(inv, cropRect.bottomRight);

      final x1 = math.min(localTopLeft.dx, localBottomRight.dx);
      final x2 = math.max(localTopLeft.dx, localBottomRight.dx);
      final y1 = math.min(localTopLeft.dy, localBottomRight.dy);
      final y2 = math.max(localTopLeft.dy, localBottomRight.dy);

      final cropPixelX = (x1 / scaleFactor).round();
      final cropPixelY = (y1 / scaleFactor).round();
      final cropPixelW = ((x2 - x1) / scaleFactor).round();
      final cropPixelH = ((y2 - y1) / scaleFactor).round();

      final task = _CropTask(
        bytes: _rawBytes!,
        rotationTurns: _rotationQuarterTurns,
        cropX: cropPixelX,
        cropY: cropPixelY,
        cropW: cropPixelW,
        cropH: cropPixelH,
      );

      final Uint8List? croppedBytes = kIsWeb
          ? _cropImageWorker(task)
          : await compute(_cropImageWorker, task);

      if (croppedBytes != null && mounted) {
        Navigator.of(context).pop(croppedBytes);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Could not process crop. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Crop error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 36,
        vertical: isNarrow ? 16 : 30,
      ),
      child: Container(
        width: math.min(size.width * 0.94, 900),
        height: math.min(size.height * 0.92, 780),
        decoration: BoxDecoration(
          color: p.isDark ? const Color(0xFF1E2030) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(p),
            const Divider(height: 1),

            // Aspect Ratio Presets Bar
            _buildRatioBar(p),
            const Divider(height: 1),

            // Main Cropper Viewport
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(RemixIcons.error_warning_line, size: 40, color: Color(0xFFE5484D)),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: p.textPrimary, fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _loadImageData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final vpSize = Size(constraints.maxWidth, constraints.maxHeight);
                            if (_viewportSize != vpSize) {
                              _viewportSize = vpSize;
                              if (!_hasInitializedTransform) {
                                _hasInitializedTransform = true;
                                _centerImage(viewportSize: vpSize);
                              }
                            }

                            final rotTurns = _rotationQuarterTurns;
                            final rawW = _decodedImage!.width.toDouble();
                            final rawH = _decodedImage!.height.toDouble();
                            final rotPixelW = (rotTurns % 2 == 1) ? rawH : rawW;
                            final rotPixelH = (rotTurns % 2 == 1) ? rawW : rawH;

                            final scaleFactor = math.min(
                              vpSize.width / rotPixelW,
                              vpSize.height / rotPixelH,
                            );
                            final displayW = rotPixelW * scaleFactor;
                            final displayH = rotPixelH * scaleFactor;

                            final unrotatedDisplayW = (rotTurns % 2 == 1) ? displayH : displayW;
                            final unrotatedDisplayH = (rotTurns % 2 == 1) ? displayW : displayH;

                            return Stack(
                              children: [
                                // Interactive Zoom/Pan Canvas
                                Positioned.fill(
                                  child: Container(
                                    color: const Color(0xFF12131A),
                                    child: InteractiveViewer(
                                      transformationController: _transformController,
                                      minScale: 0.1,
                                      maxScale: 10.0,
                                      constrained: false,
                                      boundaryMargin: const EdgeInsets.all(double.infinity),
                                      onInteractionUpdate: (_) {
                                        _scaleNotifier.value = _transformController.value.getMaxScaleOnAxis();
                                      },
                                      child: SizedBox(
                                        width: displayW,
                                        height: displayH,
                                        child: RotatedBox(
                                          quarterTurns: rotTurns,
                                          child: SizedBox(
                                            width: unrotatedDisplayW,
                                            height: unrotatedDisplayH,
                                            child: Image.memory(
                                              _rawBytes!,
                                              fit: BoxFit.fill,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Crop Guide Overlay with Mask
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CropOverlayPainter(
                                        aspectRatio: _selectedRatio.ratio,
                                      ),
                                    ),
                                  ),
                                ),

                                // Processing Overlay
                                if (_isProcessing)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: p.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                            ),
                                            SizedBox(width: 14),
                                            Text(
                                              'Processing high-res crop...',
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // Controls & Action Footer
            _buildFooter(p),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(RemixIcons.crop_line, size: 20, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  'Zoom & pan to reposition. Select aspect ratio preset or crop freely.',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(RemixIcons.close_line),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildRatioBar(AppPalette p) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'Aspect Ratio:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          for (final ratio in CropAspectRatio.values) ...[
            InkWell(
              onTap: () {
                setState(() => _selectedRatio = ratio);
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedRatio == ratio
                      ? AppColors.gold
                      : (p.isDark ? const Color(0xFF2C2E44) : const Color(0xFFF0EEE9)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedRatio == ratio
                        ? AppColors.gold
                        : (p.isDark ? p.border : Colors.black12),
                  ),
                ),
                child: Text(
                  ratio.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedRatio == ratio
                        ? Colors.black
                        : p.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final tools = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _rotateClockwise,
                icon: const Icon(RemixIcons.anticlockwise_line, size: 20),
                tooltip: 'Rotate 90° Clockwise',
              ),
              IconButton(
                onPressed: _resetTransform,
                icon: const Icon(RemixIcons.refresh_line, size: 20),
                tooltip: 'Reset Positioning',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _zoomBy(0.8),
                icon: const Icon(RemixIcons.zoom_out_line, size: 20),
                tooltip: 'Zoom Out',
              ),
              IconButton(
                onPressed: () => _zoomBy(1.25),
                icon: const Icon(RemixIcons.zoom_in_line, size: 20),
                tooltip: 'Zoom In',
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<double>(
                valueListenable: _scaleNotifier,
                builder: (context, scale, _) {
                  return Text(
                    'Zoom: ${(scale * 100).round()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted),
                  );
                },
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_isProcessing || _rawBytes == null)
                    ? null
                    : _executeCrop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(RemixIcons.check_line, size: 18),
                label: const Text(
                  'Apply Crop',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tools,
                ),
                const SizedBox(height: 8),
                actions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              tools,
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CropTask {
  _CropTask({
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

Uint8List? _cropImageWorker(_CropTask task) {
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

  // Clamp within image bounds
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

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({this.aspectRatio});
  final double? aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = AppImageCropperDialog.calculateCropRect(size, aspectRatio);
    final frameX = cropRect.left;
    final frameY = cropRect.top;
    final frameW = cropRect.width;
    final frameH = cropRect.height;

    // Dim the outside area
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, bgPaint);

    // Crop border
    final borderPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // Rule of thirds grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double x1 = frameX + frameW / 3.0;
    final double x2 = frameX + (frameW * 2.0) / 3.0;
    final double y1 = frameY + frameH / 3.0;
    final double y2 = frameY + (frameH * 2.0) / 3.0;

    canvas.drawLine(Offset(x1, frameY), Offset(x1, frameY + frameH), gridPaint);
    canvas.drawLine(Offset(x2, frameY), Offset(x2, frameY + frameH), gridPaint);
    canvas.drawLine(Offset(frameX, y1), Offset(frameX + frameW, y1), gridPaint);
    canvas.drawLine(Offset(frameX, y2), Offset(frameX + frameW, y2), gridPaint);

    // Corner accents
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    const cornerLen = 20.0;

    // Top-left
    canvas.drawLine(Offset(frameX, frameY), Offset(frameX + cornerLen, frameY), cornerPaint);
    canvas.drawLine(Offset(frameX, frameY), Offset(frameX, frameY + cornerLen), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(frameX + frameW, frameY), Offset(frameX + frameW - cornerLen, frameY), cornerPaint);
    canvas.drawLine(Offset(frameX + frameW, frameY), Offset(frameX + frameW, frameY + cornerLen), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(frameX, frameY + frameH), Offset(frameX + cornerLen, frameY + frameH), cornerPaint);
    canvas.drawLine(Offset(frameX, frameY + frameH), Offset(frameX, frameY + frameH - cornerLen), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(frameX + frameW, frameY + frameH), Offset(frameX + frameW - cornerLen, frameY + frameH), cornerPaint);
    canvas.drawLine(Offset(frameX + frameW, frameY + frameH), Offset(frameX + frameW, frameY + frameH - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.aspectRatio != aspectRatio;
  }
}
