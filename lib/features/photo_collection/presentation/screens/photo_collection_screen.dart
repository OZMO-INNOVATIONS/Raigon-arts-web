import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';

@JS('pickPhotoDirectory')
external JSPromise<JSString?> _pickPhotoDirectory();

@JS('deletePhotoFiles')
external JSPromise<JSString?> _deletePhotoFiles(JSString fileNamesJson);

@JS('refreshPhotoDirectory')
external JSPromise<JSString?> _refreshPhotoDirectory();

@JS('restorePhotoDirectory')
external JSPromise<JSString?> _restorePhotoDirectory();

void _photoLog(String message) {
  debugPrint('[PHOTO_COLLECTION] $message');
}

class PhotoItem {
  const PhotoItem({
    required this.id,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
  });

  final String id;
  final String fileName;
  final String url;
  final int sizeBytes;

  String get sizeLabel => _formatFileSize(sizeBytes);
}

class PhotoCollectionScreen extends StatefulWidget {
  const PhotoCollectionScreen({super.key});

  @override
  State<PhotoCollectionScreen> createState() => _PhotoCollectionScreenState();
}

class _PhotoCollectionScreenState extends State<PhotoCollectionScreen> {
  final List<PhotoItem> _photos = [];
  final Set<String> _selected = {};

  bool _gridView = true;
  bool _loading = false;
  bool _hasFolder = false;

  String _query = '';
  String? _folderName;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFolder();
    });
  }

  Future<void> _restoreFolder() async {
    if (!mounted) return;

    _photoLog('RESTORE: checking saved folder');

    setState(() {
      _error = null;
      _selected.clear();
    });

    try {
      final result = await _restorePhotoDirectory().toDart;

      _photoLog('RESTORE: JS promise completed');

      if (result == null) {
        _photoLog('RESTORE: JS returned null');

        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final json = result.toDart;

      _photoLog('RESTORE: response = $json');

      final decoded = jsonDecode(json);

      if (decoded is! Map) {
        throw Exception('Invalid restore response.');
      }

      final hasFolder = decoded['hasFolder'] == true;

      if (!hasFolder) {
        _photoLog('RESTORE: no saved folder');

        if (!mounted) return;

        setState(() {
          _loading = false;
          _hasFolder = false;
          _folderName = null;
          _photos.clear();
        });

        return;
      }

      final folderName = decoded['folderName']?.toString();

      final permissionRequired = decoded['permissionRequired'] == true;

      final files = decoded['files'];

      final List<PhotoItem> photos = [];

      if (files is List) {
        for (final item in files) {
          if (item is! Map) continue;

          final fileName = item['name']?.toString() ?? '';

          final url = item['url']?.toString() ?? '';

          final size = _parseSize(item['size']);

          if (fileName.isEmpty || url.isEmpty) {
            continue;
          }

          photos.add(
            PhotoItem(
              id: '${folderName ?? 'Photos'}/$fileName',
              fileName: fileName,
              url: url,
              sizeBytes: size,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _photos
          ..clear()
          ..addAll(photos);

        _folderName = folderName;
        _hasFolder = true;
        _loading = false;
        _error = null;
      });

      _photoLog(
        'RESTORE SUCCESS: '
        'folder="$folderName", '
        'photos=${photos.length}, '
        'permissionRequired=$permissionRequired',
      );

      if (permissionRequired) {
        AppSnackBar.success(
          context,
          'Folder remembered. Click Refresh to allow access.',
        );
      }
    } catch (e, stackTrace) {
      _photoLog('RESTORE ERROR: $e');

      _photoLog('RESTORE STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _hasFolder = false;
        _folderName = null;
        _photos.clear();
        _error = null;
      });
    }
  }

  Future<void> _selectFolder() async {
    if (!mounted) return;

    _photoLog('SELECT: button tapped');
    _photoLog('SELECT: calling window.pickPhotoDirectory()');

    setState(() {
      _loading = true;
      _error = null;
      _selected.clear();
    });

    try {
      final result = await _pickPhotoDirectory().toDart;

      _photoLog('SELECT: JS promise completed');
      _photoLog('SELECT: result is null = ${result == null}');

      if (result == null) {
        _photoLog('SELECT: JS returned null');
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final json = result.toDart;
      _photoLog('SELECT: JSON length = ${json.length}');
      _photoLog(
        'SELECT: JSON preview = '
        '${json.length > 500 ? '${json.substring(0, 500)}...' : json}',
      );

      final decoded = jsonDecode(json);

      if (decoded is! Map) {
        _photoLog('SELECT ERROR: decoded response is ${decoded.runtimeType}');
        throw Exception('Invalid folder response.');
      }

      final folderName =
          decoded['folderName']?.toString() ?? 'Photo Collection';

      final files = decoded['files'];

      _photoLog('SELECT: folderName = $folderName');
      _photoLog('SELECT: files type = ${files.runtimeType}');
      _photoLog(
        'SELECT: files count = '
        '${files is List ? files.length : 0}',
      );

      final List<PhotoItem> photos = [];

      if (files is List) {
        for (final item in files) {
          if (item is! Map) {
            _photoLog('SELECT: skipping non-map file item');
            continue;
          }

          final fileName = item['name']?.toString() ?? '';
          final url = item['url']?.toString() ?? '';
          final size = _parseSize(item['size']);

          _photoLog(
            'SELECT: file name="$fileName", '
            'size=$size, url=${url.isEmpty ? 'EMPTY' : 'OK'}',
          );

          if (fileName.isEmpty || url.isEmpty) {
            _photoLog('SELECT: skipping invalid file "$fileName"');
            continue;
          }

          photos.add(
            PhotoItem(
              id: '$folderName/$fileName',
              fileName: fileName,
              url: url,
              sizeBytes: size,
            ),
          );
        }
      }

      _photoLog('SELECT: parsed ${photos.length} photos');

      if (!mounted) return;

      setState(() {
        _photos
          ..clear()
          ..addAll(photos);

        _selected.clear();
        _folderName = folderName;
        _hasFolder = true;
        _loading = false;
        _error = null;
      });

      _photoLog(
        'SELECT SUCCESS: folder="$folderName", '
        'photos=${photos.length}',
      );

      if (photos.isEmpty) {
        AppSnackBar.success(
          context,
          'Folder selected, but no supported images were found.',
        );
      } else {
        AppSnackBar.success(
          context,
          '${photos.length} photo${photos.length == 1 ? '' : 's'} loaded.',
        );
      }
    } catch (e, stackTrace) {
      _photoLog('SELECT ERROR: $e');
      _photoLog('SELECT STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _photos.clear();
        _selected.clear();
        _loading = false;
        _hasFolder = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _refreshFolder() async {
    if (!_hasFolder) {
      _photoLog('REFRESH: no folder selected, opening picker');
      await _selectFolder();
      return;
    }

    if (!mounted) return;

    _photoLog('REFRESH: refreshing folder "${_folderName ?? 'unknown'}"');

    setState(() {
      _loading = true;
      _error = null;
      _selected.clear();
    });

    try {
      final result = await _refreshPhotoDirectory().toDart;

      _photoLog('REFRESH: JS promise completed');
      _photoLog('REFRESH: result is null = ${result == null}');

      if (result == null) {
        throw Exception('Unable to refresh folder.');
      }

      final json = result.toDart;
      _photoLog('REFRESH: JSON length = ${json.length}');
      _photoLog(
        'REFRESH: JSON preview = '
        '${json.length > 500 ? '${json.substring(0, 500)}...' : json}',
      );

      final decoded = jsonDecode(json);

      if (decoded is! Map) {
        _photoLog('REFRESH ERROR: decoded response is ${decoded.runtimeType}');
        throw Exception('Unable to refresh folder.');
      }

      final folderName =
          decoded['folderName']?.toString() ?? _folderName ?? 'Photos';

      final files = decoded['files'];

      _photoLog('REFRESH: folderName = $folderName');
      _photoLog(
        'REFRESH: files count = '
        '${files is List ? files.length : 0}',
      );

      final List<PhotoItem> photos = [];

      if (files is List) {
        for (final item in files) {
          if (item is! Map) continue;

          final fileName = item['name']?.toString() ?? '';
          final url = item['url']?.toString() ?? '';
          final size = _parseSize(item['size']);

          _photoLog(
            'REFRESH: file="$fileName", '
            'size=$size, url=${url.isEmpty ? 'EMPTY' : 'OK'}',
          );

          if (fileName.isEmpty || url.isEmpty) continue;

          photos.add(
            PhotoItem(
              id: '$folderName/$fileName',
              fileName: fileName,
              url: url,
              sizeBytes: size,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _photos
          ..clear()
          ..addAll(photos);

        _folderName = folderName;
        _loading = false;
      });

      _photoLog(
        'REFRESH SUCCESS: folder="$folderName", '
        'photos=${photos.length}',
      );

      AppSnackBar.success(
        context,
        '${photos.length} photo${photos.length == 1 ? '' : 's'} loaded.',
      );
    } catch (e, stackTrace) {
      _photoLog('REFRESH ERROR: $e');
      _photoLog('REFRESH STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  List<PhotoItem> get _filtered {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      return _photos;
    }

    return _photos
        .where((photo) => photo.fileName.toLowerCase().contains(q))
        .toList();
  }

  List<PhotoItem> get _selectedItems {
    return _photos.where((photo) => _selected.contains(photo.id)).toList();
  }

  void _toggle(PhotoItem photo) {
    setState(() {
      if (!_selected.add(photo.id)) {
        _selected.remove(photo.id);
      }
    });
  }

  Future<void> _download(List<PhotoItem> items) async {
    if (items.isEmpty) return;

    try {
      for (final photo in items) {
        final response = await http.get(Uri.parse(photo.url));

        if (response.statusCode != 200) {
          throw Exception('Unable to download ${photo.fileName}');
        }

        final bytes = Uint8List.fromList(response.bodyBytes);

        final extension = _fileExtension(photo.fileName);

        final mimeType = _mimeType(extension);

        final baseName = photo.fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');

        await FileSaver.instance.saveFile(
          name: baseName,
          bytes: bytes,
          fileExtension: extension,
          mimeType: mimeType,
        );
      }

      if (!mounted) return;

      AppSnackBar.success(
        context,
        items.length == 1
            ? 'Downloaded ${items.first.fileName}'
            : 'Downloaded ${items.length} photos.',
      );
    } catch (e, stackTrace) {
      _photoLog('DOWNLOAD ERROR: $e');
      _photoLog('DOWNLOAD STACK: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final items = _selectedItems;

    if (items.isEmpty) return;
    try {
      final fileNames = items.map((photo) => photo.fileName).toList();

      _photoLog('DELETE: requesting deletion for ${fileNames.length} file(s)');
      _photoLog('DELETE: files = $fileNames');

      final result = await _deletePhotoFiles(jsonEncode(fileNames).toJS).toDart;

      _photoLog('DELETE: JS promise completed');
      _photoLog('DELETE: result is null = ${result == null}');

      if (result == null) {
        throw Exception('Delete failed.');
      }

      final deleteJson = result.toDart;
      _photoLog('DELETE: response = $deleteJson');

      final dartResult = jsonDecode(deleteJson);

      if (dartResult is Map) {
        final success = dartResult['success'];

        if (success != true) {
          throw Exception(
            dartResult['message']?.toString() ?? 'Delete failed.',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _photos.removeWhere((photo) => _selected.contains(photo.id));

        _selected.clear();
      });

      AppSnackBar.success(
        context,
        '${items.length} photo${items.length == 1 ? '' : 's'} deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  void _preview(PhotoItem photo) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (_, _, _) {
        return _PreviewOverlay(
          photo: photo,
          onDownload: () {
            _download([photo]);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _photoLog('DISPOSE: PhotoCollectionScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final list = _filtered;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleRow(p),
          const SizedBox(height: 20),
          _folderCard(p),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: p.card(radius: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hasFolder) _searchCard(p, list.length),

                  Expanded(child: _buildCollectionContent(p, list)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionContent(AppPalette p, List<PhotoItem> list) {
    if (_loading) {
      return Center(child: _loadingView(p));
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _errorView(p),
      );
    }

    if (!_hasFolder) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _selectFolderView(p),
      );
    }

    if (list.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emptyView(p),
      );
    }

    if (_gridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _grid(p, list),
          );
        },
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: _list(p, list),
    );
  }

  Widget _titleRow(AppPalette p) {
    final n = _selected.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Collection',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Centralized digital vault for customer photo prints and framing specifications',
                style: TextStyle(fontSize: 14.5, color: p.textMuted),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        if (n > 0) ...[
          _actionButton(
            p,
            icon: Icons.download,
            label: 'Download Selected ($n)',
            onTap: () {
              _download(_selectedItems);
            },
          ),

          const SizedBox(width: 12),

          _actionButton(
            p,
            icon: Icons.delete,
            label: 'Delete Selected ($n)',
            danger: true,
            onTap: _deleteSelected,
          ),

          const SizedBox(width: 12),
        ],

        _viewToggle(p),
      ],
    );
  }

  Widget _folderCard(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: p.card(radius: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.darkGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _folderName == null
                      ? 'No photo collection selected'
                      : _folderName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _folderName == null
                      ? 'Choose a folder from your computer'
                      : '${_photos.length} photo${_photos.length == 1 ? '' : 's'} in this folder',
                  style: TextStyle(fontSize: 13.5, color: p.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          _actionButton(
            p,
            icon: Icons.folder_open,
            label: _hasFolder ? 'Change Folder' : 'Select Photo Collection',
            onTap: _selectFolder,
          ),

          if (_hasFolder) ...[
            const SizedBox(width: 10),
            _smallIconButton(
              p,
              icon: Icons.refresh,
              tooltip: 'Refresh folder',
              onTap: _refreshFolder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectFolderView(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: p.surface,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 36,
                color: p.textMuted,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Select a photo collection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Choose a folder from your computer to display its images.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.textMuted),
            ),

            const SizedBox(height: 22),

            _actionButton(
              p,
              icon: Icons.folder_open,
              label: 'Select Photo Collection',
              onTap: _selectFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    AppPalette p, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final fg = danger ? Colors.white : p.textPrimary;

    return Material(
      color: danger
          ? AppPalette.statusRed
          : (p.isDark ? p.surface : p.softButtonFill),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: danger || !p.isDark ? null : Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: danger ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallIconButton(
    AppPalette p, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.border),
            ),
            child: Icon(icon, size: 19, color: p.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _viewToggle(AppPalette p) {
    Widget btn(IconData icon, bool grid) {
      final active = _gridView == grid;

      return InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() {
            _gridView = grid;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? AppColors.darkGradient : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : p.textPrimary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.grid_view, true),
          const SizedBox(width: 4),
          btn(Icons.format_list_bulleted, false),
        ],
      ),
    );
  }

  Widget _searchCard(AppPalette p, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: p.card(radius: 0),
      child: Row(
        children: [
          SizedBox(
            width: 340,
            height: 44,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              cursorColor: p.textPrimary,
              style: TextStyle(fontSize: 14.5, color: p.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by photo name...',
                hintStyle: TextStyle(fontSize: 14.5, color: p.textMuted),
                prefixIcon: Icon(Icons.search, size: 22, color: p.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),

          const Spacer(),

          Text.rich(
            TextSpan(
              text: 'Showing ',
              style: TextStyle(fontSize: 14.5, color: p.textMuted),
              children: [
                TextSpan(
                  text: '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const TextSpan(text: ' photos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingView(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Reading photos...',
              style: TextStyle(fontSize: 14.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 46, color: p.textMuted),

            const SizedBox(height: 14),

            Text(
              'Unable to access folder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _error ?? 'Please select the folder again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.textMuted),
            ),

            const SizedBox(height: 18),

            _actionButton(
              p,
              icon: Icons.folder_open,
              label: 'Select Folder',
              onTap: _selectFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: p.textMuted),
            const SizedBox(height: 14),
            Text(
              'No photos found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The selected folder does not contain supported image files.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(AppPalette p, List<PhotoItem> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 22.0;

        final cols = (constraints.maxWidth / 250).floor().clamp(1, 5);

        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final photo in list)
              SizedBox(width: width, child: _gridCard(p, photo)),
          ],
        );
      },
    );
  }

  Widget _gridCard(AppPalette p, PhotoItem photo) {
    final checked = _selected.contains(photo.id);

    return Container(
      decoration: p.card(radius: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () {
                  _preview(photo);
                },
                child: AspectRatio(
                  aspectRatio: 1.42,
                  child: Image.network(
                    photo.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageError(p);
                    },
                  ),
                ),
              ),

              Positioned(
                left: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    _toggle(photo);
                  },
                  child: _Check(checked: checked, grid: true, dark: p.isDark),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 14,
                      color: p.textMuted,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      photo.sizeLabel,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageError(AppPalette p) {
    return Container(
      color: p.surface,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, size: 42, color: p.textMuted),
    );
  }

  static const _flex = [9, 11, 34, 14, 10];

  static const _heads = [
    'SELECT',
    'PREVIEW',
    'FILE NAME',
    'FILE SIZE',
    'ACTIONS',
  ];

  Widget _list(AppPalette p, List<PhotoItem> list) {
    return Container(
      decoration: p.card(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(constraints.maxWidth, 850.0);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  Container(
                    height: 48,
                    color: p.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (var i = 0; i < _heads.length; i++)
                          Expanded(
                            flex: _flex[i],
                            child: Text(
                              _heads[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                                color: p.headerText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  for (var i = 0; i < list.length; i++)
                    _listRow(p, list[i], i == list.length - 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _listRow(AppPalette p, PhotoItem photo, bool last) {
    Widget cell(int index, Widget child) {
      return Expanded(
        flex: _flex[index],
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
    }

    TextStyle textStyle(FontWeight weight) {
      return TextStyle(fontSize: 15, fontWeight: weight, color: p.textPrimary);
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.rowDivider)),
      ),
      child: Row(
        children: [
          cell(
            0,
            GestureDetector(
              onTap: () {
                _toggle(photo);
              },
              child: _Check(
                checked: _selected.contains(photo.id),
                grid: false,
                dark: p.isDark,
              ),
            ),
          ),

          cell(
            1,
            GestureDetector(
              onTap: () {
                _preview(photo);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photo.url,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 46,
                      height: 46,
                      color: p.surface,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: p.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          cell(
            2,
            Text(
              photo.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle(FontWeight.w600),
            ),
          ),

          cell(3, Text(photo.sizeLabel, style: textStyle(FontWeight.w500))),

          cell(
            4,
            IconButton(
              tooltip: 'Preview',
              onPressed: () {
                _preview(photo);
              },
              icon: Icon(Icons.fullscreen, size: 24, color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.checked, required this.grid, required this.dark});

  final bool checked;
  final bool grid;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;

    if (grid) {
      fill = checked
          ? const Color(0xFFD8C79C)
          : Colors.white.withValues(alpha: 0.92);

      border = checked ? const Color(0xFFD8C79C) : const Color(0xFFB9B7B0);
    } else if (checked) {
      fill = const Color(0xFF2F6BFF);
      border = const Color(0xFF2F6BFF);
    } else {
      fill = dark ? Colors.white : Colors.transparent;

      border = dark ? Colors.white : const Color(0xFF6B6B76);
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(grid ? 6 : 5),
        border: Border.all(color: border, width: 1.5),
      ),
      child: checked
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _PreviewOverlay extends StatelessWidget {
  const _PreviewOverlay({required this.photo, required this.onDownload});

  final PhotoItem photo;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mq = MediaQuery.of(context);

    final side = math.max(
      200.0,
      math.min(732.0, mq.size.height - 64 - 48 - 90),
    );

    final headerBg = p.isDark
        ? const Color(0xFFA3A3B5)
        : const Color(0xFFFCFAF5);

    final bodyBg = p.isDark ? p.surface : const Color(0xFFF1F0EE);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.8 : 0.72),
                ),
              ),
            ),
          ),

          Positioned(top: 24, right: 28, child: _closePreviewButton(context)),

          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: side + 48,
                decoration: BoxDecoration(
                  color: bodyBg,
                  borderRadius: BorderRadius.circular(24),
                  border: p.isDark ? Border.all(color: p.border) : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 64,
                      color: headerBg,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image,
                            size: 22,
                            color: Color(0xFFD1BC85),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.isDark
                                        ? Colors.black
                                        : AppColors.black,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  photo.sizeLabel,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          _downloadPill(context),

                          const SizedBox(width: 10),

                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.isDark
                                    ? const Color(0xFF2E3050)
                                    : const Color(0xFFF2F0EB),
                                border: p.isDark
                                    ? null
                                    : Border.all(color: p.border),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: p.isDark
                                    ? Colors.white
                                    : AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          photo.url,
                          width: side,
                          height: side,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: side,
                              height: side,
                              color: p.surface,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 60,
                                color: p.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadPill(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onDownload,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closePreviewButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Close Preview',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _parseSize(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    final kb = bytes / 1024;

    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  }

  if (bytes < 1024 * 1024 * 1024) {
    final mb = bytes / (1024 * 1024);

    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  final gb = bytes / (1024 * 1024 * 1024);

  return '${gb.toStringAsFixed(2)} GB';
}

String _fileExtension(String fileName) {
  final index = fileName.lastIndexOf('.');

  if (index == -1 || index == fileName.length - 1) {
    return 'jpg';
  }

  return fileName.substring(index + 1).toLowerCase();
}

MimeType _mimeType(String extension) {
  switch (extension) {
    case 'png':
      return MimeType.png;

    case 'webp':
      return MimeType.webp;

    case 'gif':
      return MimeType.gif;

    case 'bmp':
      return MimeType.bmp;

    case 'jpg':
    case 'jpeg':
    default:
      return MimeType.jpeg;
  }
}

String _cleanError(Object error) {
  final message = error.toString();

  if (message.contains('AbortError')) {
    return 'Folder selection was cancelled.';
  }

  if (message.contains('NotAllowedError')) {
    return 'Folder access was not allowed.';
  }

  return message.replaceFirst('Exception: ', '');
}
