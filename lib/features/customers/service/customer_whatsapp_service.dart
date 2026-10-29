import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/authentication/models/auth_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

const String kWorkshopPhone = AuthModel.registeredPhone;
const String kWorkshopAddress = 'Main Workshop, MG Road, Trivandrum';

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
    return switch (status) {
      Status.pending => 'Pending',
      Status.inProgress => 'In Progress',
      Status.completed => 'Completed',
      Status.cancelled => 'Cancelled',
    };
  }

  static String _orientation(String value) {
    final index = value.indexOf(' (');
    return index == -1 ? value : value.substring(0, index);
  }

  static String _frameDetails(Customer customer) {
    final frames = customer.effectiveFrames;

    return frames
        .map((frame) {
          final size = frame.sizeLabel.isEmpty
              ? 'Size not specified'
              : frame.sizeLabel;

          return '$size (${frame.frameType} - ${frame.material})';
        })
        .join('\n');
  }

  static String _frameFinishes(Customer customer) {
    return customer.effectiveFrames
        .map((frame) {
          return '${frame.finish} | ${_orientation(frame.orientation)}';
        })
        .join('\n');
  }

  static String buildMessage(Customer customer) {
    final balance = customer.total - customer.advance;

    return '''
📦 *RAIGON ARTS WORKSHOP* - Order Confirmation
----------------------------------------
Dear *${customer.name}*,

Thank you for your framing order with Raigon Arts! Here are your complete order details:

🧾 *Order ID:* ${customer.id}
📅 *Order Date:* ${_formatDate(customer.orderDate)}
🚚 *Expected Delivery Date:* ${_formatDate(customer.expectedDelivery)}

🖼️ *Frame Details:*
${_frameDetails(customer)}

🎨 *Color Finish | Orientation:*
${_frameFinishes(customer)}

🔢 *Total Quantity:* ${customer.qty}

💰 *TOTAL AMOUNT:* ${_money(customer.total)}
💵 *Advance Paid:* ${_money(customer.advance)}
💳 *BALANCE DUE:* ${_money(balance)}
📌 *Payment Status:* ${_paymentStatus(customer)}
📋 *Order Status:* ${_orderStatus(customer.status)}
----------------------------------------
📍 *Workshop Address:* $kWorkshopAddress
📞 *Contact:* +91 $kWorkshopPhone

Thank you for choosing Raigon Arts! ❤️
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

  static String buildPaymentReminderMessage(Customer customer) {
    final balance = customer.total - customer.advance;

    return '''
📦 *RAIGON ARTS WORKSHOP* - Payment Due Reminder
----------------------------------------
Dear *${customer.name}*,

Friendly reminder regarding your framing order with Raigon Arts:

🧾 *Order ID:* ${customer.id}
📅 *Order Date:* ${_formatDate(customer.orderDate)}
🚚 *Expected Delivery:* ${_formatDate(customer.expectedDelivery)}

🖼️ *Frame Details:*
${_frameDetails(customer)}

🔢 *Total Quantity:* ${customer.qty} Frame(s)

💰 *TOTAL AMOUNT:* ${_money(customer.total)}
💵 *Advance Paid:* ${_money(customer.advance)}
💳 *BALANCE DUE:* ${_money(balance)}
📌 *Payment Status:* ${_paymentStatus(customer)}
----------------------------------------
📍 *Workshop Address:* $kWorkshopAddress
📞 *Contact / GPay / UPI:* +91 $kWorkshopPhone

Kindly clear the pending balance at your earliest convenience. Thank you! ❤️
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
