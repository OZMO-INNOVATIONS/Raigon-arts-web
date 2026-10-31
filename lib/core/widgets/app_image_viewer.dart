import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';

class AppViewerItem {
  const AppViewerItem({
    this.url,
    this.bytes,
    this.title,
    this.subtitle,
  });

  final String? url;
  final Uint8List? bytes;
  final String? title;
  final String? subtitle;

  bool get hasImage =>
      (url != null && url!.trim().isNotEmpty) ||
      (bytes != null && bytes!.isNotEmpty);

  String? get resolvedUrl => url != null ? ImageUrlHelper.resolve(url!) : null;

  ImageProvider get imageProvider {
    if (bytes != null && bytes!.isNotEmpty) {
      return MemoryImage(bytes!);
    }
    final finalUrl = resolvedUrl ?? '';
    return NetworkImage(finalUrl);
  }
}

List<AppViewerItem> viewerItemsFromCustomer(Customer customer) {
  final items = <AppViewerItem>[];

  // If customer has individual frames (> 1), build viewer items directly from frames
  if (customer.frames.length > 1) {
    for (var i = 0; i < customer.frames.length; i++) {
      final f = customer.frames[i];
      final title = '${f.sizeLabel} · ${f.frameType}';
      final photoName = f.photoName ??
          (i < customer.photoNames.length
              ? customer.photoNames[i]
              : 'Photo #${i + 1}');
      if (f.photoBytes != null) {
        items.add(
          AppViewerItem(
            bytes: f.photoBytes!,
            title: title,
            subtitle: '${customer.id} · ${customer.name} · $photoName',
          ),
        );
      } else if (f.photoUrl != null && f.photoUrl!.isNotEmpty) {
        items.add(
          AppViewerItem(
            url: ImageUrlHelper.resolve(f.photoUrl!),
            title: title,
            subtitle: '${customer.id} · ${customer.name} · $photoName',
          ),
        );
      } else if (i < customer.photoBytes.length) {
        items.add(
          AppViewerItem(
            bytes: customer.photoBytes[i],
            title: title,
            subtitle: '${customer.id} · ${customer.name} · $photoName',
          ),
        );
      } else if (i < customer.photoUrls.length) {
        items.add(
          AppViewerItem(
            url: ImageUrlHelper.resolve(customer.photoUrls[i]),
            title: title,
            subtitle: '${customer.id} · ${customer.name} · $photoName',
          ),
        );
      }
    }
    if (items.isNotEmpty) {
      return items;
    }
  }

  // 1. Memory bytes
  for (var i = 0; i < customer.photoBytes.length; i++) {
    final b = customer.photoBytes[i];
    final name = i < customer.photoNames.length
        ? customer.photoNames[i]
        : 'Photo #${i + 1}';
    final frameTitle = i < customer.frames.length
        ? '${customer.frames[i].sizeLabel} · ${customer.frames[i].frameType}'
        : null;

    items.add(
      AppViewerItem(
        bytes: b,
        title: frameTitle ?? name,
        subtitle: '${customer.id} · ${customer.name}',
      ),
    );
  }

  // 2. URLs
  final allUrls = <String>{};
  for (final u in customer.photoUrls) {
    if (u.trim().isNotEmpty) allUrls.add(u.trim());
  }
  for (final f in customer.frames) {
    final fu = f.photoUrl?.trim();
    if (fu != null && fu.isNotEmpty) allUrls.add(fu);
  }

  var urlIndex = 0;
  for (final u in allUrls) {
    FrameSpec? matchingFrame;
    for (final f in customer.frames) {
      if (f.photoUrl == u) {
        matchingFrame = f;
        break;
      }
    }
    final title = matchingFrame != null
        ? '${matchingFrame.sizeLabel} · ${matchingFrame.frameType}'
        : 'Attached Artwork #${urlIndex + 1}';

    items.add(
      AppViewerItem(
        url: u,
        title: title,
        subtitle: '${customer.id} · ${customer.name}',
      ),
    );
    urlIndex++;
  }

  return items;
}

Future<void> showSingleImageViewer({
  required BuildContext context,
  String? url,
  Uint8List? bytes,
  String? title,
  String? subtitle,
}) {
  return showAppImageViewer(
    context: context,
    items: [
      AppViewerItem(
        url: url,
        bytes: bytes,
        title: title,
        subtitle: subtitle,
      ),
    ],
    initialIndex: 0,
  );
}

Future<void> showAppImageViewer({
  required BuildContext context,
  required List<AppViewerItem> items,
  int initialIndex = 0,
}) {
  if (items.isEmpty) return Future.value();

  final safeIndex = initialIndex.clamp(0, items.length - 1);

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (ctx) => _AppImageViewerDialog(
      items: items,
      initialIndex: safeIndex,
    ),
  );
}

class _AppImageViewerDialog extends StatefulWidget {
  const _AppImageViewerDialog({
    required this.items,
    required this.initialIndex,
  });

  final List<AppViewerItem> items;
  final int initialIndex;

  @override
  State<_AppImageViewerDialog> createState() => _AppImageViewerDialogState();
}

class _AppImageViewerDialogState extends State<_AppImageViewerDialog> {
  late int _currentIndex;
  late final TransformationController _transformController;
  final FocusNode _focusNode = FocusNode();

  int _rotationQuarterTurns = 0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
      _rotationQuarterTurns = 0;
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(1.35, 1.35, 1.0, 1.0);
    setState(() {
      _transformController.value = matrix;
    });
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(0.74, 0.74, 1.0, 1.0);
    setState(() {
      _transformController.value = matrix;
    });
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _toggleDoubleTapZoom(TapDownDetails details) {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      final matrix = Matrix4.identity()
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
      setState(() {
        _transformController.value = matrix;
      });
    }
  }

  void _prevPhoto() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetZoom();
      });
    }
  }

  void _nextPhoto() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() {
        _currentIndex++;
        _resetZoom();
      });
    }
  }

  void _selectIndex(int index) {
    if (index >= 0 && index < widget.items.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _resetZoom();
      });
    }
  }

  Future<void> _openInNewTab(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final resolved = ImageUrlHelper.resolve(url);
    final uri = Uri.tryParse(resolved);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_currentIndex];
    final hasMultiple = widget.items.length > 1;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevPhoto,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _nextPhoto,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        focusNode: _focusNode,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1240, maxHeight: 860),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // --- TOP BAR ---
                  _buildTopBar(item),

                  // --- MAIN IMAGE CANVAS ---
                  Expanded(
                    child: Stack(
                      children: [
                        // The interactive image
                        Positioned.fill(
                          child: GestureDetector(
                            onDoubleTapDown: _toggleDoubleTapZoom,
                            child: Container(
                              color: const Color(0xFF07070B),
                              alignment: Alignment.center,
                              child: InteractiveViewer(
                                transformationController: _transformController,
                                panEnabled: true,
                                scaleEnabled: true,
                                minScale: 0.2,
                                maxScale: 8.0,
                                boundaryMargin: const EdgeInsets.all(260),
                                child: RotatedBox(
                                  quarterTurns: _rotationQuarterTurns,
                                  child: _buildImageContent(item),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Navigation Arrow: Left
                        if (hasMultiple && _currentIndex > 0)
                          Positioned(
                            left: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _ArrowButton(
                                icon: RemixIcons.arrow_left_s_line,
                                tooltip: 'Previous photo (Left arrow)',
                                onPressed: _prevPhoto,
                              ),
                            ),
                          ),

                        // Navigation Arrow: Right
                        if (hasMultiple && _currentIndex < widget.items.length - 1)
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _ArrowButton(
                                icon: RemixIcons.arrow_right_s_line,
                                tooltip: 'Next photo (Right arrow)',
                                onPressed: _nextPhoto,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- BOTTOM THUMBNAILS & CONTROLS ---
                  _buildBottomBar(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppViewerItem item) {
    return Container(
      color: const Color(0xFF161622),
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(RemixIcons.gallery_line, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title ?? 'Photo #${_currentIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.items.length > 1) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1} of ${widget.items.length}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Zoom Controls in Top Bar
          _IconButtonBadge(
            icon: RemixIcons.zoom_in_line,
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
          ),
          const SizedBox(width: 6),
          _IconButtonBadge(
            icon: RemixIcons.zoom_out_line,
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
          ),
          const SizedBox(width: 6),
          _IconButtonBadge(
            icon: RemixIcons.refresh_line,
            tooltip: 'Reset view (1:1)',
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 6),
          _IconButtonBadge(
            icon: RemixIcons.clockwise_line,
            tooltip: 'Rotate 90°',
            onPressed: _rotateClockwise,
          ),

          if (item.resolvedUrl != null && item.resolvedUrl!.isNotEmpty) ...[
            const SizedBox(width: 8),
            _IconButtonBadge(
              icon: RemixIcons.external_link_line,
              tooltip: 'Open full-resolution file in new tab',
              highlight: true,
              onPressed: () => _openInNewTab(item.resolvedUrl),
            ),
          ],

          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(RemixIcons.close_line, color: Colors.white70, size: 24),
            tooltip: 'Close (Esc)',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(AppViewerItem item) {
    if (item.bytes != null && item.bytes!.isNotEmpty) {
      return Image.memory(
        item.bytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, error, _) => _buildErrorWidget('Cannot render local photo'),
      );
    }

    final rawUrl = item.resolvedUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      return _buildErrorWidget('No image source available');
    }

    return Image.network(
      rawUrl,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        final loaded = progress.cumulativeBytesLoaded;
        final progressVal = total != null && total > 0 ? loaded / total : null;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progressVal,
                color: AppColors.gold,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading high-resolution artwork...',
                style: TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _buildErrorWidget('Could not load image from network\n$rawUrl'),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(RemixIcons.image_line, size: 56, color: Color(0xFFE5484D)),
            const SizedBox(height: 14),
            const Text(
              'Unable to Display Image',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppViewerItem currentItem) {
    final hasMultiple = widget.items.length > 1;

    return Container(
      color: const Color(0xFF161622),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnails strip if multiple
          if (hasMultiple) ...[
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final it = widget.items[index];
                  final isSelected = index == _currentIndex;

                  return InkWell(
                    onTap: () => _selectIndex(index),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : Colors.white24,
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: it.imageProvider,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFF2A2A3A),
                              child: const Icon(RemixIcons.image_line, size: 20, color: Colors.white38),
                            ),
                          ),
                          if (!isSelected)
                            Container(color: Colors.black.withValues(alpha: 0.35)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Footer info row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(RemixIcons.aspect_ratio_line, size: 14, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      'Scale: ${(_currentScale * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                hasMultiple
                    ? 'Use ← → keys to switch · Scroll/pinch to zoom · Double-tap to expand'
                    : 'Scroll or pinch to zoom · Drag to pan · Double-tap to expand',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _hover
                  ? AppColors.gold
                  : const Color(0xFF1E1E2C).withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: _hover ? AppColors.gold : Colors.white30,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: _hover ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButtonBadge extends StatefulWidget {
  const _IconButtonBadge({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlight = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlight;

  @override
  State<_IconButtonBadge> createState() => _IconButtonBadgeState();
}

class _IconButtonBadgeState extends State<_IconButtonBadge> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover || widget.highlight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hover
                  ? AppColors.gold.withValues(alpha: 0.25)
                  : (widget.highlight
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? AppColors.gold.withValues(alpha: 0.8)
                    : Colors.white12,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 19,
              color: active ? AppColors.gold : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
