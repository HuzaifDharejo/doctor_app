import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../db/doctor_db.dart';

class WhatsAppService {
  /// Share prescription via WhatsApp
  static Future<void> sharePrescription({
    required Patient patient,
    required Prescription prescription,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
  }) async {
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (_) {}

    final buffer = StringBuffer();
    
    // Header
    buffer
      ..writeln('═══════════════════════')
      ..writeln('*$clinicName*');
    if (clinicPhone != null && clinicPhone.isNotEmpty) {
      buffer.writeln('📞 $clinicPhone');
    }
    buffer
      ..writeln('═══════════════════════')
      ..writeln()
      ..writeln('*PRESCRIPTION*')
      ..writeln('📅 ${_formatDate(prescription.createdAt)}')
      ..writeln();
    
    // Patient info
    buffer.writeln('*Patient:* ${patient.firstName} ${patient.lastName}');
    if (patient.phone.isNotEmpty) {
      buffer.writeln('📱 ${patient.phone}');
    }
    buffer.writeln();
    
    // Medications
    buffer
      ..writeln('*💊 Medications:*')
      ..writeln('───────────────────');
    for (int i = 0; i < medications.length; i++) {
      final med = medications[i];
      buffer
        ..writeln()
        ..writeln('${i + 1}. *${med['name'] ?? 'Unknown'}*');
      if (med['dosage'] != null && med['dosage'].toString().isNotEmpty) {
        buffer.writeln('   Dose: ${med['dosage']}');
      }
      if (med['frequency'] != null && med['frequency'].toString().isNotEmpty) {
        buffer.writeln('   ${med['frequency']}');
      }
      if (med['duration'] != null && med['duration'].toString().isNotEmpty) {
        buffer.writeln('   Duration: ${med['duration']}');
      }
      if (med['route'] != null && med['route'].toString().isNotEmpty) {
        buffer.writeln('   Route: ${med['route']}');
      }
    }
    buffer.writeln();
    
    // Instructions
    if (prescription.instructions.isNotEmpty) {
      buffer
        ..writeln('*📋 Instructions:*')
        ..writeln('───────────────────')
        ..writeln(prescription.instructions)
        ..writeln();
    }
    
    // Footer
    buffer
      ..writeln('───────────────────')
      ..writeln('*Dr. $doctorName*')
      ..writeln()
      ..writeln('_Get well soon! 🙏_');
    
    final message = Uri.encodeComponent(buffer.toString());
    final whatsappUrl = 'https://wa.me/${patient.phone.replaceAll(RegExp('[^0-9+]'), '')}?text=$message';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Share invoice via WhatsApp
  static Future<void> shareInvoice({
    required Patient patient,
    required Invoice invoice,
    required String clinicName,
    String? clinicPhone,
  }) async {
    List<dynamic> items = [];
    try {
      items = jsonDecode(invoice.itemsJson) as List<dynamic>;
    } catch (_) {}

    final buffer = StringBuffer();
    
    // Header
    buffer
      ..writeln('═══════════════════════')
      ..writeln('*$clinicName*');
    if (clinicPhone != null && clinicPhone.isNotEmpty) {
      buffer.writeln('📞 $clinicPhone');
    }
    buffer
      ..writeln('═══════════════════════')
      ..writeln()
      ..writeln('*INVOICE: ${invoice.invoiceNumber}*')
      ..writeln('📅 ${_formatDate(invoice.invoiceDate)}')
      ..writeln();
    
    // Patient info
    buffer
      ..writeln('*Bill To:* ${patient.firstName} ${patient.lastName}')
      ..writeln();
    
    // Items
    buffer
      ..writeln('*📋 Services:*')
      ..writeln('───────────────────');
    for (final item in items) {
      buffer.writeln('• ${item['description']} - Rs. ${item['total']}');
    }
    buffer
      ..writeln('───────────────────')
      ..writeln();
    
    // Totals
    buffer.writeln('Subtotal: Rs. ${invoice.subtotal.toStringAsFixed(0)}');
    if (invoice.discountAmount > 0) {
      buffer.writeln('Discount: -Rs. ${invoice.discountAmount.toStringAsFixed(0)}');
    }
    if (invoice.taxAmount > 0) {
      buffer.writeln('Tax: Rs. ${invoice.taxAmount.toStringAsFixed(0)}');
    }
    buffer
      ..writeln()
      ..writeln('*Grand Total: Rs. ${invoice.grandTotal.toStringAsFixed(0)}*')
      ..writeln()
      ..writeln('Status: ${invoice.paymentStatus}')
      ..writeln()
      ..writeln('───────────────────')
      ..writeln('_Thank you for your visit!_');
    
    final message = Uri.encodeComponent(buffer.toString());
    final whatsappUrl = 'https://wa.me/${patient.phone.replaceAll(RegExp('[^0-9+]'), '')}?text=$message';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Open WhatsApp chat with patient
  static Future<void> openChat(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp('[^0-9+]'), '');
    final whatsappUrl = 'https://wa.me/$cleanPhone';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    }
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
