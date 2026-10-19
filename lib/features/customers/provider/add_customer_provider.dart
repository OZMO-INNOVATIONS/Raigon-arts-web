// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:raigon_art/core/models/status.dart';
// import 'package:raigon_art/features/customers/models/customer_model.dart';
// import 'package:raigon_art/features/customers/models/frame_spec.dart';
// import 'package:raigon_art/features/customers/presentation/widgets/frame_spec_fields.dart';

// enum FrameMode { same, individual }

// class AddCustomerProvider extends ChangeNotifier {
//   static const List<String> paymentOptions = ['Unpaid', 'Partial', 'Paid'];

//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final altPhoneController = TextEditingController();
//   final cityController = TextEditingController();
//   final addressController = TextEditingController();
//   final pinController = TextEditingController();
//   final totalController = TextEditingController();
//   final advanceController = TextEditingController();
//   final balanceController = TextEditingController();

//   final List<PickedPhoto> _photos = [];
//   List<PickedPhoto> get photos => List.unmodifiable(_photos);

//   final FrameSpecData sharedFrame = FrameSpecData();

//   final List<FrameEntry> _entries = [];
//   List<FrameEntry> get entries => List.unmodifiable(_entries);

//   FrameMode _mode = FrameMode.same;
//   FrameMode get mode => _mode;

//   bool _dragging = false;
//   bool get dragging => _dragging;

//   DateTime _orderDate = DateUtils.dateOnly(DateTime.now());
//   DateTime get orderDate => _orderDate;

//   DateTime? _delivery;
//   DateTime? get delivery => _delivery;

//   String _payment = 'Unpaid';
//   String get payment => _payment;

//   bool _paymentTouched = false;

//   Status _status = Status.inProgress;
//   Status get status => _status;

//   void setDragging(bool value) {
//     if (_dragging == value) return;
//     _dragging = value;
//     notifyListeners();
//   }

//   void addPhotos(Iterable<PickedPhoto> photos) {
//     _photos.addAll(photos);
//     notifyListeners();
//   }

//   void removePhotoAt(int index) {
//     if (index < 0 || index >= _photos.length) return;
//     _photos.removeAt(index);
//     notifyListeners();
//   }

//   void setMode(FrameMode mode) {
//     if (_mode == mode) return;

//     if (mode == FrameMode.individual && _entries.isEmpty) {
//       if (_photos.isEmpty) {
//         _entries.add(FrameEntry());
//       } else {
//         for (final photo in _photos) {
//           _entries.add(FrameEntry(photo: photo));
//         }
//       }
//     }

//     if (mode == FrameMode.same && _photos.isEmpty) {
//       _photos.addAll([
//         for (final entry in _entries)
//           if (entry.photo != null) entry.photo!,
//       ]);
//     }

//     _mode = mode;
//     notifyListeners();
//   }

//   void addIndividualPhotos(Iterable<PickedPhoto> photos) {
//     if (_entries.length == 1 && _entries.first.photo == null) {
//       _entries.first.dispose();
//       _entries.clear();
//     }

//     for (final photo in photos) {
//       _entries.add(FrameEntry(photo: photo));
//     }

//     notifyListeners();
//   }

//   void replaceEntryPhoto(FrameEntry entry, PickedPhoto photo) {
//     entry.photo = photo;
//     notifyListeners();
//   }

//   void removeEntry(FrameEntry entry) {
//     entry.dispose();
//     _entries.remove(entry);

//     if (_entries.isEmpty) {
//       _entries.add(FrameEntry());
//     }

//     notifyListeners();
//   }

//   void setOrderDate(DateTime value) {
//     _orderDate = DateUtils.dateOnly(value);
//     notifyListeners();
//   }

//   void setDelivery(DateTime? value) {
//     _delivery = value;
//     notifyListeners();
//   }

//   void setPayment(String value) {
//     _payment = value;
//     _paymentTouched = true;
//     notifyListeners();
//   }

//   void setStatus(Status value) {
//     _status = value;
//     notifyListeners();
//   }

//   void refresh() {
//     notifyListeners();
//   }

//   void recalculatePayment() {
//     final total = double.tryParse(totalController.text) ?? 0;
//     final advance = double.tryParse(advanceController.text) ?? 0;

//     balanceController.text =
//         totalController.text.isEmpty && advanceController.text.isEmpty
//         ? ''
//         : math.max(0, total - advance).round().toString();

//     if (!_paymentTouched) {
//       _payment = advance <= 0
//           ? 'Unpaid'
//           : (total > 0 && advance >= total ? 'Paid' : 'Partial');
//     }

//     notifyListeners();
//   }

//   String joinLabels(List<String> values) {
//     if (values.isEmpty) return '—';
//     return values.length == 1
//         ? values.first
//         : '${values.first} +${values.length - 1} more';
//   }

//   void loadCustomer(Customer customer) {
//     nameController.text = customer.name;
//     phoneController.text = customer.phone;
//     altPhoneController.text = customer.altPhone;
//     cityController.text = customer.city;
//     addressController.text = customer.address;
//     pinController.text = customer.pincode;

//     totalController.text = customer.total > 0 ? '${customer.total}' : '';
//     advanceController.text = customer.advance > 0 ? '${customer.advance}' : '';
//     balanceController.text = customer.total == 0 && customer.advance == 0
//         ? ''
//         : '${math.max(0, customer.balance)}';

//     _orderDate = DateUtils.dateOnly(customer.orderDate);
//     _delivery = customer.expectedDelivery;
//     _payment = customer.paymentStatus;
//     _paymentTouched = false;
//     _status = customer.status;

//     final frames = customer.effectiveFrames;

//     if (frames.length > 1) {
//       _mode = FrameMode.individual;

//       for (final frame in frames) {
//         final bytes = frame.photoBytes;

//         _entries.add(
//           FrameEntry(
//             photo: bytes == null
//                 ? null
//                 : PickedPhoto(
//                     name: frame.photoName ?? 'Photo',
//                     bytes: bytes,
//                     size: bytes.length,
//                   ),
//           )..spec.loadSpec(frame),
//         );
//       }
//     } else {
//       for (var i = 0; i < customer.photoBytes.length; i++) {
//         final bytes = customer.photoBytes[i];

//         _photos.add(
//           PickedPhoto(
//             name: i < customer.photoNames.length
//                 ? customer.photoNames[i]
//                 : 'Photo_${i + 1}.jpg',
//             bytes: bytes,
//             size: bytes.length,
//           ),
//         );
//       }

//       if (frames.isNotEmpty) {
//         sharedFrame.loadSpec(frames.first);
//       }

//       if (customer.frames.isEmpty) {
//         sharedFrame.qty.text = customer.photoCount > 1
//             ? '1'
//             : '${customer.qty}';
//       }
//     }

//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     for (final controller in [
//       nameController,
//       phoneController,
//       altPhoneController,
//       cityController,
//       addressController,
//       pinController,
//       totalController,
//       advanceController,
//       balanceController,
//     ]) {
//       controller.dispose();
//     }

//     sharedFrame.dispose();

//     for (final entry in _entries) {
//       entry.dispose();
//     }

//     super.dispose();
//   }
// }

// class FrameEntry {
//   FrameEntry({this.photo});

//   PickedPhoto? photo;
//   final FrameSpecData spec = FrameSpecData();

//   void dispose() {
//     spec.dispose();
//   }
// }
