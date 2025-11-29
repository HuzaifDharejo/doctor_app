import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../db/doctor_db.dart';
import 'logger_service.dart';

class PdfService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _italicFont;
  static bool _fontsInitialized = false;
  
  /// Initialize fonts with Unicode support - with fallback
  static Future<void> _initFonts() async {
    if (_fontsInitialized) return;
    
    try {
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
      _italicFont = await PdfGoogleFonts.notoSansItalic();
      _fontsInitialized = true;
    } catch (e) {
      // Fallback to default Helvetica if Google Fonts fail
      log.w('PDF', 'Failed to load Google Fonts, using defaults: $e');
      _fontsInitialized = true;
    }
  }
  
  static pw.ThemeData? _getTheme() {
    if (_regularFont == null) return null;
    return pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
      boldItalic: _boldFont,
    );
  }

  /// Generate and share a prescription PDF
  static Future<void> sharePrescriptionPdf({
    required Patient patient,
    required Prescription prescription,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
    String? signatureData, // Base64 encoded signature
  }) async {
    await _initFonts();
    final pdf = await _generatePrescriptionPdf(
      patient: patient,
      prescription: prescription,
      doctorName: doctorName,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
      signatureData: signatureData,
    );
    
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'prescription_${patient.firstName}_${_formatDateForFile(prescription.createdAt)}.pdf',
    );
  }

  /// Generate and share an invoice PDF
  static Future<void> shareInvoicePdf({
    required Patient patient,
    required Invoice invoice,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
    String? signatureData, // Base64 encoded signature
    String? doctorName,
  }) async {
    await _initFonts();
    final pdf = await _generateInvoicePdf(
      patient: patient,
      invoice: invoice,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
      signatureData: signatureData,
      doctorName: doctorName,
    );
    
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<Uint8List> _generatePrescriptionPdf({
    required Patient patient,
    required Prescription prescription,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
    String? signatureData,
  }) async {
    final theme = _getTheme();
    final pdf = theme != null ? pw.Document(theme: theme) : pw.Document();
    
    // Parse signature image if available
    pw.MemoryImage? signatureImage;
    if (signatureData != null && signatureData.isNotEmpty) {
      try {
        final bytes = base64Decode(signatureData);
        signatureImage = pw.MemoryImage(bytes);
      } catch (e) {
        log.w('PDF', 'Error parsing signature: $e');
      }
    }
    
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(clinicName, clinicPhone, clinicAddress, doctorName),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),
              
              // Prescription Title
              pw.Center(
                child: pw.Text(
                  'PRESCRIPTION',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Patient Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Patient Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${patient.firstName} ${patient.lastName}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(_formatDate(prescription.createdAt)),
                      ],
                    ),
                    if (patient.phone.isNotEmpty)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Phone:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(patient.phone),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Rx Symbol
              pw.Row(
                children: [
                  pw.Text(
                    'Rx',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              
              // Medications Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _tableCell('#', isHeader: true),
                      _tableCell('Medication', isHeader: true),
                      _tableCell('Dosage', isHeader: true),
                      _tableCell('Frequency', isHeader: true),
                      _tableCell('Duration', isHeader: true),
                    ],
                  ),
                  // Medication rows
                  ...medications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final med = entry.value as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _tableCell('${index + 1}'),
                        _tableCell((med['name'] as String?) ?? 'Unknown'),
                        _tableCell((med['dosage'] as String?) ?? '-'),
                        _tableCell((med['frequency'] as String?) ?? '-'),
                        _tableCell((med['duration'] as String?) ?? '-'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Instructions
              if (prescription.instructions.isNotEmpty) ...[
                pw.Text(
                  'Instructions:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(prescription.instructions),
                ),
              ],
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      // Show signature image if available
                      if (signatureImage != null) ...[
                        pw.Image(signatureImage, height: 50, width: 120),
                        pw.SizedBox(height: 4),
                      ] else ...[
                        pw.Container(width: 150, child: pw.Divider()),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text('Dr. $doctorName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Signature'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generateInvoicePdf({
    required Patient patient,
    required Invoice invoice,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
    String? signatureData,
    String? doctorName,
  }) async {
    final theme = _getTheme();
    final pdf = theme != null ? pw.Document(theme: theme) : pw.Document();
    
    // Parse signature image if available
    pw.MemoryImage? signatureImage;
    if (signatureData != null && signatureData.isNotEmpty) {
      try {
        final bytes = base64Decode(signatureData);
        signatureImage = pw.MemoryImage(bytes);
      } catch (e) {
        log.w('PDF', 'Error parsing signature: $e');
      }
    }
    
    List<dynamic> items = [];
    try {
      items = jsonDecode(invoice.itemsJson) as List<dynamic>;
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(clinicName, clinicPhone, clinicAddress, null),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.green800),
              pw.SizedBox(height: 20),
              
              // Invoice Title & Number
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${_formatDate(invoice.invoiceDate)}'),
                      if (invoice.dueDate != null)
                        pw.Text('Due: ${_formatDate(invoice.dueDate!)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Bill To
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('${patient.firstName} ${patient.lastName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (patient.phone.isNotEmpty) pw.Text(patient.phone),
                        if (patient.address.isNotEmpty) pw.Text(patient.address),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      _tableCell('#', isHeader: true),
                      _tableCell('Description', isHeader: true),
                      _tableCell('Qty', isHeader: true),
                      _tableCell('Rate', isHeader: true),
                      _tableCell('Amount', isHeader: true),
                    ],
                  ),
                  // Item rows
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _tableCell('${index + 1}'),
                        _tableCell((item['description'] as String?) ?? 'Item'),
                        _tableCell('${item['quantity'] ?? 1}'),
                        _tableCell('Rs. ${item['rate'] ?? 0}'),
                        _tableCell('Rs. ${item['total'] ?? 0}'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _totalRow('Subtotal', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
                        if (invoice.discountAmount > 0)
                          _totalRow('Discount (${invoice.discountPercent}%)', '-Rs. ${invoice.discountAmount.toStringAsFixed(0)}', isDiscount: true),
                        if (invoice.taxAmount > 0)
                          _totalRow('Tax (${invoice.taxPercent}%)', 'Rs. ${invoice.taxAmount.toStringAsFixed(0)}'),
                        pw.Divider(),
                        _totalRow('Grand Total', 'Rs. ${invoice.grandTotal.toStringAsFixed(0)}', isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Payment Status
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: invoice.paymentStatus == 'Paid' ? PdfColors.green100 : PdfColors.orange100,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'Status: ${invoice.paymentStatus}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: invoice.paymentStatus == 'Paid' ? PdfColors.green800 : PdfColors.orange800,
                  ),
                ),
              ),
              
              pw.Spacer(),
              
              // Footer with Signature
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Thank you for your visit!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Column(
                    children: [
                      // Show signature image if available
                      if (signatureImage != null) ...[
                        pw.Image(signatureImage, height: 50, width: 120),
                        pw.SizedBox(height: 4),
                      ] else ...[
                        pw.Container(width: 150, child: pw.Divider()),
                        pw.SizedBox(height: 4),
                      ],
                      if (doctorName != null)
                        pw.Text('Dr. $doctorName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Authorized Signature'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(String clinicName, String? phone, String? address, String? doctorName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              clinicName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            if (doctorName != null)
              pw.Text('Dr. $doctorName', style: const pw.TextStyle(fontSize: 12)),
            if (phone != null && phone.isNotEmpty)
              pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 10)),
            if (address != null && address.isNotEmpty)
              pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            border: pw.Border.all(color: PdfColors.blue800, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text('+', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 11 : 10,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : null,
              fontSize: isTotal ? 14 : 11,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : null,
              fontSize: isTotal ? 14 : 11,
              color: isDiscount ? PdfColors.red : (isTotal ? PdfColors.green800 : null),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
