// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:raigon_art/features/customers/models/frame_spec.dart';

// class PhotoCaptureService {
//   static final ImagePicker _picker = ImagePicker();

//   /// Captures a photo using the device camera
//   static Future<PickedPhoto?> captureFromCamera(BuildContext context) async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 2048,
//         maxHeight: 2048,
//         imageQuality: 88,
//       );
//       if (file == null) return null;
//       final bytes = await file.readAsBytes();
//       return PickedPhoto(
//         name: file.name.isNotEmpty
//             ? file.name
//             : 'Camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
//         bytes: bytes,
//         size: bytes.length,
//       );
//     } catch (e) {
//       debugPrint('[PhotoCaptureService] Camera capture error: $e');
//       return null;
//     }
//   }

//   /// Selects photo(s) from device gallery / file system
//   static Future<List<PickedPhoto>> pickFromGallery({
//     bool multiple = true,
//   }) async {
//     try {
//       if (multiple) {
//         final List<XFile> files = await _picker.pickMultiImage(
//           maxWidth: 2048,
//           maxHeight: 2048,
//           imageQuality: 88,
//         );
//         if (files.isNotEmpty) {
//           final result = <PickedPhoto>[];
//           for (final f in files) {
//             final bytes = await f.readAsBytes();
//             result.add(
//               PickedPhoto(
//                 name: f.name.isNotEmpty
//                     ? f.name
//                     : 'Gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
//                 bytes: bytes,
//                 size: bytes.length,
//               ),
//             );
//           }
//           return result;
//         }
//       } else {
//         final XFile? f = await _picker.pickImage(
//           source: ImageSource.gallery,
//           maxWidth: 2048,
//           maxHeight: 2048,
//           imageQuality: 88,
//         );
//         if (f != null) {
//           final bytes = await f.readAsBytes();
//           return [
//             PickedPhoto(
//               name: f.name.isNotEmpty
//                   ? f.name
//                   : 'Gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
//               bytes: bytes,
//               size: bytes.length,
//             ),
//           ];
//         }
//       }
//     } catch (e) {
//       debugPrint('[PhotoCaptureService] Gallery error: $e');
//     }

//     // Fallback to FilePicker
//     try {
//       if (multiple) {
//         final files = await FilePicker.pickFiles(type: FileType.image);
//         if (files.isNotEmpty) {
//           final result = <PickedPhoto>[];
//           for (final f in files) {
//             final bytes = await f.readAsBytes();
//             result.add(
//               PickedPhoto(name: f.name, bytes: bytes, size: bytes.length),
//             );
//           }
//           return result;
//         }
//       } else {
//         final f = await FilePicker.pickFile(type: FileType.image);
//         if (f != null) {
//           final bytes = await f.readAsBytes();
//           return [PickedPhoto(name: f.name, bytes: bytes, size: bytes.length)];
//         }
//       }
//     } catch (e) {
//       debugPrint('[PhotoCaptureService] FilePicker fallback error: $e');
//     }
//     return [];
//   }

//   /// Prompts user to choose between Camera and Gallery
//   static Future<List<PickedPhoto>> showPhotoSourceSelector(
//     BuildContext context, {
//     bool multiple = true,
//   }) async {
//     final source = await showModalBottomSheet<String>(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
//         decoration: BoxDecoration(
//           color: Theme.of(ctx).scaffoldBackgroundColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SafeArea(
//           top: false,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.withValues(alpha: 0.4),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const Text(
//                 'Select Photo Source',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),

//               Material(
//                 color: Colors.transparent,
//                 borderRadius: BorderRadius.circular(12),
//                 clipBehavior: Clip.antiAlias,
//                 child: ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Color(0xFFE0E7FF),
//                     child: Icon(
//                       Icons.camera_alt_rounded,
//                       color: Color(0xFF4338CA),
//                     ),
//                   ),
//                   title: const Text(
//                     'Capture with Camera',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: const Text('Take a new photo using device camera'),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   onTap: () => Navigator.of(ctx).pop('camera'),
//                 ),
//               ),

//               const SizedBox(height: 8),

//               Material(
//                 color: Colors.transparent,
//                 borderRadius: BorderRadius.circular(12),
//                 clipBehavior: Clip.antiAlias,
//                 child: ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Color(0xFFFEF3C7),
//                     child: Icon(
//                       Icons.photo_library_rounded,
//                       color: Color(0xFFB45309),
//                     ),
//                   ),
//                   title: const Text(
//                     'Choose from Gallery / Files',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text(
//                     multiple
//                         ? 'Select one or more photos from files or gallery'
//                         : 'Select a photo from files or gallery',
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   onTap: () => Navigator.of(ctx).pop('gallery'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//     if (source == 'camera') {
//       if (!context.mounted) return [];
//       final photo = await captureFromCamera(context);
//       return photo == null ? [] : [photo];
//     } else if (source == 'gallery') {
//       return await pickFromGallery(multiple: multiple);
//     }
//     return [];
//   }
// }
