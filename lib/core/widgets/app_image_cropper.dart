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
  double _currentScale = 1.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      // Decode image in background compute
      final decoded = await compute(_decodeImageIsolate, bytes);
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

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
      _selectedRatio = CropAspectRatio.free;
    });
  }

  Future<void> _executeCrop(Size viewportSize) async {
    if (_decodedImage == null || _rawBytes == null) return;
    setState(() => _isProcessing = true);

    try {
      final matrix = _transformController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();

      // Compute crop based on viewport and transform
      final croppedBytes = await compute(_cropImageIsolate, _CropTask(
        bytes: _rawBytes!,
        rotationTurns: _rotationQuarterTurns,
        scale: scale,
        tx: translation.x,
        ty: translation.y,
        viewportWidth: viewportSize.width,
        viewportHeight: viewportSize.height,
        aspectRatio: _selectedRatio.ratio,
      ));

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

  static Uint8List? _cropImageIsolate(_CropTask task) {
    img.Image? src = img.decodeImage(task.bytes);
    if (src == null) return null;

    // Apply rotation if any
    if (task.rotationTurns == 1) {
      src = img.copyRotate(src, angle: 90);
    } else if (task.rotationTurns == 2) {
      src = img.copyRotate(src, angle: 180);
    } else if (task.rotationTurns == 3) {
      src = img.copyRotate(src, angle: 270);
    }

    // Determine target crop frame inside viewport
    final double vpW = task.viewportWidth;
    final double vpH = task.viewportHeight;

    double frameW = vpW * 0.88;
    double frameH = vpH * 0.82;

    if (task.aspectRatio != null) {
      final double r = task.aspectRatio!;
      if (frameW / frameH > r) {
        frameW = frameH * r;
      } else {
        frameH = frameW / r;
      }
    }

    final double frameX = (vpW - frameW) / 2.0;
    final double frameY = (vpH - frameH) / 2.0;

    // Calculate how the image is positioned inside the viewport
    // Default image fit inside viewport (contained)
    final double imgAspect = src.width / src.height;
    final double vpAspect = vpW / vpH;

    double baseW;
    double baseH;
    if (imgAspect > vpAspect) {
      baseW = vpW;
      baseH = vpW / imgAspect;
    } else {
      baseH = vpH;
      baseW = vpH * imgAspect;
    }

    final double baseLeft = (vpW - baseW) / 2.0;
    final double baseTop = (vpH - baseH) / 2.0;

    // Actual rendered image rect in viewport space:
    final double renderedLeft = baseLeft * task.scale + task.tx;
    final double renderedTop = baseTop * task.scale + task.ty;
    final double renderedWidth = baseW * task.scale;
    final double renderedHeight = baseH * task.scale;

    // Mapping frame coordinates into image pixel coordinates:
    final double pixelPerRenderedX = src.width / renderedWidth;
    final double pixelPerRenderedY = src.height / renderedHeight;

    double cropX = (frameX - renderedLeft) * pixelPerRenderedX;
    double cropY = (frameY - renderedTop) * pixelPerRenderedY;
    double cropW = frameW * pixelPerRenderedX;
    double cropH = frameH * pixelPerRenderedY;

    // Clamp coordinates
    if (cropX < 0) {
      cropW += cropX;
      cropX = 0;
    }
    if (cropY < 0) {
      cropH += cropY;
      cropY = 0;
    }
    if (cropX + cropW > src.width) {
      cropW = src.width - cropX;
    }
    if (cropY + cropH > src.height) {
      cropH = src.height - cropY;
    }

    if (cropW <= 10 || cropH <= 10) {
      // Fallback: entire image
      return Uint8List.fromList(img.encodeJpg(src, quality: 92));
    }

    final cropped = img.copyCrop(
      src,
      x: cropX.round(),
      y: cropY.round(),
      width: cropW.round(),
      height: cropH.round(),
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
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
                            return Stack(
                              children: [
                                // Interactive Zoom/Pan Canvas
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black,
                                    child: InteractiveViewer(
                                      transformationController: _transformController,
                                      minScale: 0.5,
                                      maxScale: 6.0,
                                      boundaryMargin: const EdgeInsets.all(double.infinity),
                                      onInteractionUpdate: (_) {
                                        setState(() {
                                          _currentScale = _transformController.value.getMaxScaleOnAxis();
                                        });
                                      },
                                      child: Center(
                                        child: RotatedBox(
                                          quarterTurns: _rotationQuarterTurns,
                                          child: Image.memory(
                                            _rawBytes!,
                                            fit: BoxFit.contain,
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
                                            Text('Processing high-res crop...'),
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
          final isNarrow = constraints.maxWidth < 560;

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
              const SizedBox(width: 6),
              Text(
                'Zoom: ${(_currentScale * 100).round()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textMuted),
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
                onPressed: _isProcessing || _rawBytes == null
                    ? null
                    : () {
                        final renderBox = context.findRenderObject() as RenderBox?;
                        final size = renderBox?.size ?? const Size(800, 600);
                        _executeCrop(size);
                      },
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
                tools,
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
    required this.scale,
    required this.tx,
    required this.ty,
    required this.viewportWidth,
    required this.viewportHeight,
    this.aspectRatio,
  });

  final Uint8List bytes;
  final int rotationTurns;
  final double scale;
  final double tx;
  final double ty;
  final double viewportWidth;
  final double viewportHeight;
  final double? aspectRatio;
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({this.aspectRatio});
  final double? aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    double frameW = size.width * 0.88;
    double frameH = size.height * 0.82;

    if (aspectRatio != null) {
      final double r = aspectRatio!;
      if (frameW / frameH > r) {
        frameW = frameH * r;
      } else {
        frameH = frameW / r;
      }
    }

    final double frameX = (size.width - frameW) / 2.0;
    final double frameY = (size.height - frameH) / 2.0;
    final cropRect = Rect.fromLTWH(frameX, frameY, frameW, frameH);

    // Dim the outside area
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
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
      ..color = Colors.white.withValues(alpha: 0.28)
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

    const cornerLen = 18.0;

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
