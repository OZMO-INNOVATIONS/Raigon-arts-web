import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/authentication/models/auth_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

const String kWorkshopPhone = AuthModel.registeredPhone;
// const String kWorkshopAddress = 'Main Workshop, MG Road, Trivandrum';
const String kWorkshopAddress =
    'VP 302-A, R J Building, Kollamkonam Junction, '
    'Vilappilsala, Thiruvananthapuram, Kerala 695573';

class CustomerWhatsAppService {
  static String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';

    const months = [
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

    return '${months[date.month - 1]} '
        '${date.day.toString().padLeft(2, '0')}, '
        '${date.year}';
  }

  static String _money(int amount) {
    final value = amount.abs().toString();

    if (value.length <= 3) {
      return '₹$value';
    }

    final lastThree = value.substring(value.length - 3);
    var remaining = value.substring(0, value.length - 3);
    final parts = <String>[];

    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '₹${parts.join(',')},$lastThree';
  }

  static String _paymentStatus(Customer customer) {
    if (customer.advance <= 0) return 'Unpaid';
    if (customer.advance >= customer.total) return 'Paid';
    return 'Partial';
  }

  static String _orderStatus(Status status) {
    return status.label;
  }

  //   static String buildMessage(Customer customer) {
  //     final balance = customer.total - customer.advance;
  //     final frames = customer.effectiveFrames;

  //     // Collect special instructions from individual frames.
  //     final specialRequests = frames
  //         .map((frame) => frame.notes.trim())
  //         .where((note) => note.isNotEmpty)
  //         .toSet()
  //         .join(', ');

  //     // Build numbered frame sizes.
  //     final frameDetails = frames.isEmpty
  //         ? 'Not specified'
  //         : frames
  //               .asMap()
  //               .entries
  //               .map((entry) {
  //                 final frame = entry.value;
  //                 final size = frame.sizeLabel.isNotEmpty
  //                     ? frame.sizeLabel
  //                     : 'Size not specified';

  //                 return '${entry.key + 1}. $size';
  //               })
  //               .join('\n');

  //     // Dynamic payment and order status.
  //     final paymentStatus = _paymentStatus(customer);
  //     final orderStatus = _orderStatus(customer.status);

  //     // Google Maps location.
  //     const workshopMapUrl = 'https://maps.app.goo.gl/Dr5ySuwTxbSHc4FH6';

  //     return '''

  // 🎨 *RAIGON ART GALLERY*
  // 🧾 *ORDER CONFIRMATION*

  // Dear *${customer.name}*,

  // Thank you for choosing *RAIGON ART GALLERY*! ❤️ We're pleased to confirm your order. Please find your order details below.

  // ━━━━━━━━━━━━━━━━━━━━

  // 📋 *ORDER DETAILS*

  // *Order ID:* ${customer.id}
  // *Order Date:* ${_formatDate(customer.orderDate)}
  // *Expected Delivery:* ${_formatDate(customer.expectedDelivery)}

  // 🖼️ *Items Ordered:*
  // $frameDetails

  // ${specialRequests.isNotEmpty ? '✨ *Special Request:* $specialRequests\n' : ''}📦 *Total Quantity:* ${customer.qty} Pieces

  // ━━━━━━━━━━━━━━━━━━━━

  // 💰 *PAYMENT SUMMARY*

  // *Total Amount:* ${_money(customer.total)}
  // *Advance Paid:* ${_money(customer.advance)}
  // *Balance Due:* ${_money(balance)}

  // 🚚 *Note:* Shipping charges are extra and will be calculated separately.

  // 💳 *Payment Status:* $paymentStatus
  // 🛠️ *Order Status:* $orderStatus

  // ━━━━━━━━━━━━━━━━━━━━

  // 📍 *PRODUCTION HOUSE LOCATION:*
  // $workshopMapUrl

  // 📞 *Contact:* +91 $kWorkshopPhone

  // ━━━━━━━━━━━━━━━━━━━━

  // 🙏 Thank you for trusting *RAIGON ART GALLERY* with your order. We appreciate your support and look forward to delivering your artwork!

  // *RAIGON ART GALLERY* 🖼️✨
  // '''
  //         .trim();
  //   }

  static String buildMessage(Customer customer) {
    final balance = customer.total - customer.advance;
    final frames = customer.effectiveFrames;

    // Collect special instructions from individual frames.
    final specialRequests = frames
        .map((frame) => frame.notes.trim())
        .where((note) => note.isNotEmpty)
        .toSet()
        .join(', ');

    // Build numbered frame sizes.
    final frameDetails = frames.isEmpty
        ? 'Not specified'
        : frames
              .asMap()
              .entries
              .map((entry) {
                final frame = entry.value;
                final size = frame.sizeLabel.isNotEmpty
                    ? frame.sizeLabel
                    : 'Size not specified';

                return '${entry.key + 1}. $size';
              })
              .join('\n');

    // Dynamic payment and order status.
    final paymentStatus = _paymentStatus(customer);
    final orderStatus = _orderStatus(customer.status);

    // Google Maps location.
    const workshopMapUrl = 'https://maps.app.goo.gl/Dr5ySuwTxbSHc4FH6';

    return '''

*RAIGON ART GALLERY*
*ORDER CONFIRMATION*

Dear *${customer.name}*,

Thank you for choosing *RAIGON ART GALLERY*! We're pleased to confirm your order. Please find your order details below.

━━━━━━━━━━━━━━━━━━━━

*ORDER DETAILS*

*Order ID:* ${customer.id}
*Order Date:* ${_formatDate(customer.orderDate)}
*Expected Delivery:* ${_formatDate(customer.expectedDelivery)}

*Items Ordered:*
$frameDetails

${specialRequests.isNotEmpty ? '✨ *Special Request:* $specialRequests\n' : ''}*Total Quantity:* ${customer.qty} Pieces

━━━━━━━━━━━━━━━━━━━━

*PAYMENT SUMMARY*

*Total Amount:* ${_money(customer.total)}
*Advance Paid:* ${_money(customer.advance)}
*Balance Due:* ${_money(balance)}

*Note:* Shipping charges are extra and will be calculated separately.

*Payment Status:* $paymentStatus
*Order Status:* $orderStatus

━━━━━━━━━━━━━━━━━━━━

*PRODUCTION HOUSE LOCATION:*
$workshopMapUrl

*Contact:* +91 $kWorkshopPhone

━━━━━━━━━━━━━━━━━━━━

Thank you for trusting *RAIGON ART GALLERY* with your order. We appreciate your support and look forward to delivering your artwork!

*RAIGON ART GALLERY*
'''
        .trim();
  }

  static String _whatsAppNumber(String phone) {
    // Remove spaces, +, brackets, hyphens and other punctuation.
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    // Normalize 10-digit Indian mobile numbers to country code 91.
    if (digits.length == 10) {
      digits = '91$digits';
    }

    return digits;
  }

  //   static String buildPaymentReminderMessage(Customer customer) {
  //     final balance = customer.total - customer.advance;
  //     final frames = customer.effectiveFrames;

  //     final specialRequests = frames
  //         .map((frame) => frame.notes.trim())
  //         .where((note) => note.isNotEmpty)
  //         .toSet()
  //         .join(', ');

  //     final frameDetails = frames.isEmpty
  //         ? 'Not specified'
  //         : frames
  //               .asMap()
  //               .entries
  //               .map((entry) {
  //                 final frame = entry.value;
  //                 final size = frame.sizeLabel.isNotEmpty
  //                     ? frame.sizeLabel
  //                     : 'Size not specified';

  //                 return '${entry.key + 1}. $size';
  //               })
  //               .join('\n');

  //     final paymentStatus = _paymentStatus(customer);
  //     final orderStatus = _orderStatus(customer.status);

  //     const workshopMapUrl = 'https://maps.app.goo.gl/T2UKxfZCaXzkEj5H7';

  //     return '''
  // 🎨 *RAIGON ART GALLERY*
  // 💳 *PAYMENT REMINDER*

  // Dear *${customer.name}*,

  // We hope you are doing well! ❤️

  // This is a friendly reminder regarding the pending balance for your framing order with *RAIGON ART GALLERY*.

  // Please find your order and payment details below.

  // ━━━━━━━━━━━━━━━━━━━━

  // 📋 *ORDER DETAILS*

  // *Order ID:* ${customer.id}
  // *Order Date:* ${_formatDate(customer.orderDate)}
  // *Expected Delivery:* ${_formatDate(customer.expectedDelivery)}

  // 🖼️ *Items Ordered:*
  // $frameDetails

  // ${specialRequests.isNotEmpty ? '✨ *Special Request:* $specialRequests\n' : ''}📦 *Total Quantity:* ${customer.qty} Pieces

  // ━━━━━━━━━━━━━━━━━━━━

  // 💰 *PAYMENT SUMMARY*

  // *Total Amount:* ${_money(customer.total)}
  // *Advance Paid:* ${_money(customer.advance)}
  // *Balance Due:* ${_money(balance)}

  // 💳 *Payment Status:* $paymentStatus
  // 🛠️ *Order Status:* $orderStatus

  // ━━━━━━━━━━━━━━━━━━━━

  // 📢 *PAYMENT REQUEST*

  // We kindly request you to clear the pending balance of *${_money(balance)}* at your earliest convenience.

  // Your timely payment will help us proceed smoothly with your order.

  // 🚚 *Note:* Shipping charges are extra and will be calculated separately.

  // ━━━━━━━━━━━━━━━━━━━━

  // 📍 *PRODUCTION HOUSE LOCATION:*
  // $kWorkshopAddress

  // 🗺️ *Google Maps:*
  // $workshopMapUrl

  // 📞 *Contact / GPay / UPI:* +91 $kWorkshopPhone

  // ━━━━━━━━━━━━━━━━━━━━

  // 🙏 Thank you for choosing *RAIGON ART GALLERY*. We truly appreciate your trust and support!

  // *RAIGON ART GALLERY* 🖼️✨
  // '''
  //         .trim();
  //   }

  static String buildPaymentReminderMessage(Customer customer) {
    final balance = customer.total - customer.advance;
    final frames = customer.effectiveFrames;

    final specialRequests = frames
        .map((frame) => frame.notes.trim())
        .where((note) => note.isNotEmpty)
        .toSet()
        .join(', ');

    final frameDetails = frames.isEmpty
        ? 'Not specified'
        : frames
              .asMap()
              .entries
              .map((entry) {
                final frame = entry.value;
                final size = frame.sizeLabel.isNotEmpty
                    ? frame.sizeLabel
                    : 'Size not specified';

                return '${entry.key + 1}. $size';
              })
              .join('\n');

    final paymentStatus = _paymentStatus(customer);
    final orderStatus = _orderStatus(customer.status);

    const workshopMapUrl = 'https://maps.app.goo.gl/T2UKxfZCaXzkEj5H7';

    return '''
*RAIGON ART GALLERY*
*PAYMENT REMINDER*

Dear *${customer.name}*,

We hope you are doing well!

This is a friendly reminder regarding the pending balance for your framing order with *RAIGON ART GALLERY*.

Please find your order and payment details below.

━━━━━━━━━━━━━━━━━━━━

*ORDER DETAILS*

*Order ID:* ${customer.id}
*Order Date:* ${_formatDate(customer.orderDate)}
*Expected Delivery:* ${_formatDate(customer.expectedDelivery)}

*Items Ordered:*
$frameDetails

${specialRequests.isNotEmpty ? '✨ *Special Request:* $specialRequests\n' : ''}*Total Quantity:* ${customer.qty} Pieces

━━━━━━━━━━━━━━━━━━━━

*PAYMENT SUMMARY*

*Total Amount:* ${_money(customer.total)}
*Advance Paid:* ${_money(customer.advance)}
*Balance Due:* ${_money(balance)}

*Payment Status:* $paymentStatus
*Order Status:* $orderStatus

━━━━━━━━━━━━━━━━━━━━

*PAYMENT REQUEST*

We kindly request you to clear the pending balance of *${_money(balance)}* at your earliest convenience.

Your timely payment will help us proceed smoothly with your order.

*Note:* Shipping charges are extra and will be calculated separately.

━━━━━━━━━━━━━━━━━━━━

*PRODUCTION HOUSE LOCATION:*
$kWorkshopAddress

*Google Maps:*
$workshopMapUrl

*Contact / GPay / UPI:* +91 $kWorkshopPhone

━━━━━━━━━━━━━━━━━━━━

Thank you for choosing *RAIGON ART GALLERY*. We truly appreciate your trust and support!

*RAIGON ART GALLERY*
'''
        .trim();
  }

  static Future<bool> openOrderConfirmation(Customer customer) async {
    final phone = _whatsAppNumber(customer.phone);
    if (phone.isEmpty) return false;

    final message = buildMessage(customer);
    return openDirectChat(phone, message);
  }

  static Future<bool> openPaymentReminder(Customer customer) async {
    final phone = _whatsAppNumber(customer.phone);
    if (phone.isEmpty) return false;

    final message = buildPaymentReminderMessage(customer);
    return openDirectChat(phone, message);
  }

  static Future<bool> openDirectChat(String phone, [String? text]) async {
    final cleanPhone = _whatsAppNumber(phone);
    if (cleanPhone.isEmpty) return false;

    final queryParams = text != null && text.isNotEmpty
        ? {'text': text}
        : <String, String>{};
    final uri = Uri.https('wa.me', '/$cleanPhone', queryParams);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        final fallbackUri = Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanPhone'
          '${text != null && text.isNotEmpty ? '&text=${Uri.encodeComponent(text)}' : ''}',
        );
        return await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      }
      return launched;
    } catch (e) {
      debugPrint(
        '[CustomerWhatsAppService] openDirectChat failed, trying fallback: $e',
      );
      try {
        final fallbackUri = Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanPhone'
          '${text != null && text.isNotEmpty ? '&text=${Uri.encodeComponent(text)}' : ''}',
        );
        return await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } catch (_) {
        return false;
      }
    }
  }

  /// Alias for openDirectChat with named parameters
  static Future<bool> openWhatsApp({required String phone, String? message}) =>
      openDirectChat(phone, message);

  static Future<bool> sendApiOrderConfirmation(String customerId) async {
    try {
      final client = ApiClient();
      await client.post(
        ApiConstants.whatsappSendConfirmation,
        body: {'customerId': customerId},
      );
      return true;
    } catch (e) {
      debugPrint(
        '[CustomerWhatsAppService] sendApiOrderConfirmation failed: $e',
      );
      return false;
    }
  }

  static Future<bool> sendApiStatusUpdate({
    required String customerId,
    required String status,
    String? customNote,
  }) async {
    try {
      final client = ApiClient();
      await client.post(
        ApiConstants.whatsappSendStatus,
        body: {
          'customerId': customerId,
          'status': status,
          if (customNote != null && customNote.isNotEmpty)
            'customNote': customNote,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[CustomerWhatsAppService] sendApiStatusUpdate failed: $e');
      return false;
    }
  }
}
