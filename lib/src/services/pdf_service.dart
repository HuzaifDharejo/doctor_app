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
  
  /// Parse signature data which may be in JSON format (strokes or image)
  /// or raw base64 image data
  static Uint8List? _parseSignatureData(String? signatureData) {
    if (signatureData == null || signatureData.isEmpty) return null;
    
    try {
      // Try to parse as JSON first
      final jsonData = jsonDecode(signatureData);
      if (jsonData is Map) {
        // Handle image format: {"image": "base64data"}
        if (jsonData['image'] != null) {
          return base64Decode(jsonData['image'] as String);
        }
        // Handle strokes format: {"strokes": [...]} - can't render strokes in PDF directly
        // Would need to render to image first, skip for now
        if (jsonData['strokes'] != null) {
          log.w('PDF', 'Signature is in strokes format - cannot render in PDF. Please re-capture signature as image.');
          return null;
        }
      }
    } catch (_) {
      // Not JSON, try as raw base64
      try {
        return base64Decode(signatureData);
      } catch (e) {
        log.w('PDF', 'Error parsing signature as base64: $e');
      }
    }
    return null;
  }
  
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

  /// Generate and share a medical record PDF
  static Future<void> shareMedicalRecordPdf({
    required Patient patient,
    required MedicalRecord record,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    await _initFonts();
    final pdf = await _generateMedicalRecordPdf(
      patient: patient,
      record: record,
      doctorName: doctorName,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
    );
    
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'medical_record_${record.id}_${_formatDateForFile(record.recordDate)}.pdf',
    );
  }

  /// Print a medical record PDF
  static Future<void> printMedicalRecordPdf({
    required Patient patient,
    required MedicalRecord record,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    await _initFonts();
    final pdf = await _generateMedicalRecordPdf(
      patient: patient,
      record: record,
      doctorName: doctorName,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
    );
    
    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Medical Record - ${patient.firstName} ${patient.lastName}',
    );
  }

  static Future<Uint8List> _generateMedicalRecordPdf({
    required Patient patient,
    required MedicalRecord record,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    final theme = _getTheme();
    final pdf = theme != null ? pw.Document(theme: theme) : pw.Document();
    
    // Parse record data
    Map<String, dynamic> data = {};
    if (record.dataJson.isNotEmpty && record.dataJson != '{}') {
      try {
        data = jsonDecode(record.dataJson) as Map<String, dynamic>;
      } catch (e) {
        log.w('PDF', 'Error parsing record data: $e');
      }
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Header
            _buildPdfHeader(clinicName, clinicPhone, clinicAddress, doctorName),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.blue800),
            pw.SizedBox(height: 10),
            
            // Record Type and Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    _formatRecordType(record.recordType),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
                pw.Text('Date: ${_formatDate(record.recordDate)}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Patient Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Patient:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  if (patient.dateOfBirth != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Age:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text('${_calculateAge(patient.dateOfBirth!)} years', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Title
            pw.Text(
              record.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            
            // Description
            if (record.description.isNotEmpty) ...[
              _buildSectionHeader('Description'),
              pw.SizedBox(height: 8),
              pw.Text(record.description, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ],
            
            // Diagnosis
            if (record.diagnosis.isNotEmpty) ...[
              _buildSectionHeader('Diagnosis'),
              pw.SizedBox(height: 8),
              pw.Text(record.diagnosis, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ],
            
            // Treatment
            if (record.treatment.isNotEmpty) ...[
              _buildSectionHeader('Treatment Plan'),
              pw.SizedBox(height: 8),
              pw.Text(record.treatment, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ],
            
            // Type-specific data
            ..._buildTypeSpecificContent(record.recordType, data),
            
            // Doctor's Notes
            if (record.doctorNotes.isNotEmpty) ...[
              _buildSectionHeader("Doctor's Notes"),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.amber200),
                ),
                child: pw.Text(record.doctorNotes, style: const pw.TextStyle(fontSize: 11)),
              ),
            ],
            
            pw.SizedBox(height: 30),
            
            // Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Dr. $doctorName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static List<pw.Widget> _buildTypeSpecificContent(String recordType, Map<String, dynamic> data) {
    if (data.isEmpty) return [];
    
    final widgets = <pw.Widget>[];
    
    switch (recordType) {
      case 'psychiatric_assessment':
        if (data['symptoms'] != null && data['symptoms'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Presenting Symptoms'),
            pw.SizedBox(height: 8),
            pw.Text(data['symptoms'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        if (data['mse'] != null) {
          final mse = data['mse'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Mental Status Examination'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(mse),
            pw.SizedBox(height: 16),
          ]);
        }
        
      case 'pulmonary_evaluation':
        if (data['chestExam'] != null) {
          final chest = data['chestExam'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Chest Examination'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(chest),
            pw.SizedBox(height: 16),
          ]);
        }
        if (data['spirometry'] != null) {
          final spirometry = data['spirometry'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Spirometry'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(spirometry),
            pw.SizedBox(height: 16),
          ]);
        }
        
      case 'lab_result':
        widgets.addAll([
          _buildSectionHeader('Lab Results'),
          pw.SizedBox(height: 8),
          _buildKeyValueTable(data),
          pw.SizedBox(height: 16),
        ]);
        
      case 'imaging':
        if (data['findings'] != null) {
          widgets.addAll([
            _buildSectionHeader('Imaging Findings'),
            pw.SizedBox(height: 8),
            pw.Text(data['findings'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        if (data['impression'] != null) {
          widgets.addAll([
            _buildSectionHeader('Impression'),
            pw.SizedBox(height: 8),
            pw.Text(data['impression'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
    }
    
    return widgets;
  }

  static pw.Widget _buildKeyValueTable(Map<String, dynamic> data) {
    final entries = data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    if (entries.isEmpty) return pw.SizedBox();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: entries.map((e) => pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.grey100,
            child: pw.Text(_formatLabel(e.key), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),).toList(),
    );
  }

  static String _formatLabel(String key) {
    return key
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  static String _formatRecordType(String type) {
    const types = {
      'general': 'General Consultation',
      'psychiatric_assessment': 'Psychiatric Assessment',
      'pulmonary_evaluation': 'Pulmonary Evaluation',
      'lab_result': 'Lab Result',
      'imaging': 'Imaging',
      'procedure': 'Procedure',
      'follow_up': 'Follow-up',
    };
    return types[type] ?? type;
  }

  static int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
    final signatureBytes = _parseSignatureData(signatureData);
    if (signatureBytes != null) {
      try {
        signatureImage = pw.MemoryImage(signatureBytes);
      } catch (e) {
        log.w('PDF', 'Error creating signature image: $e');
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
    final signatureBytes = _parseSignatureData(signatureData);
    if (signatureBytes != null) {
      try {
        signatureImage = pw.MemoryImage(signatureBytes);
      } catch (e) {
        log.w('PDF', 'Error creating signature image: $e');
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

  /// Generate and share a complete patient summary PDF
  static Future<void> sharePatientSummaryPdf({
    required Patient patient,
    required List<Appointment> appointments,
    required List<Prescription> prescriptions,
    required List<VitalSign> vitalSigns,
    required List<Invoice> invoices,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    await _initFonts();
    final pdf = await _generatePatientSummaryPdf(
      patient: patient,
      appointments: appointments,
      prescriptions: prescriptions,
      vitalSigns: vitalSigns,
      invoices: invoices,
      doctorName: doctorName,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
    );
    
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'patient_summary_${patient.firstName}_${patient.lastName}_${_formatDateForFile(DateTime.now())}.pdf',
    );
  }

  /// Print a patient summary PDF
  static Future<void> printPatientSummaryPdf({
    required Patient patient,
    required List<Appointment> appointments,
    required List<Prescription> prescriptions,
    required List<VitalSign> vitalSigns,
    required List<Invoice> invoices,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    await _initFonts();
    final pdf = await _generatePatientSummaryPdf(
      patient: patient,
      appointments: appointments,
      prescriptions: prescriptions,
      vitalSigns: vitalSigns,
      invoices: invoices,
      doctorName: doctorName,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      clinicAddress: clinicAddress,
    );
    
    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Patient Summary - ${patient.firstName} ${patient.lastName}',
    );
  }

  static Future<Uint8List> _generatePatientSummaryPdf({
    required Patient patient,
    required List<Appointment> appointments,
    required List<Prescription> prescriptions,
    required List<VitalSign> vitalSigns,
    required List<Invoice> invoices,
    required String doctorName,
    required String clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) async {
    final theme = _getTheme();
    final pdf = theme != null ? pw.Document(theme: theme) : pw.Document();
    final now = DateTime.now();
    
    // Calculate patient age
    String age = '';
    if (patient.dateOfBirth != null) {
      final dob = patient.dateOfBirth!;
      int years = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        years--;
      }
      age = '$years years';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(clinicName, clinicPhone, clinicAddress, doctorName),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) {
          return [
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.blue800),
            pw.SizedBox(height: 10),
            
            // Title
            pw.Center(
              child: pw.Text(
                'PATIENT SUMMARY REPORT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'Generated on: ${_formatDate(now)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Patient Demographics
            _buildSectionHeader('Patient Information'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name', '${patient.firstName} ${patient.lastName ?? ''}'),
                  if (age.isNotEmpty) _buildInfoRow('Age', age),
                  if (patient.phone.isNotEmpty) _buildInfoRow('Phone', patient.phone),
                  if (patient.email.isNotEmpty) _buildInfoRow('Email', patient.email),
                  if (patient.address.isNotEmpty) _buildInfoRow('Address', patient.address),
                  if (patient.riskLevel > 0) 
                    _buildInfoRow('Risk Level', _formatRiskLevel(patient.riskLevel)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            
            // Medical History
            if (patient.medicalHistory.isNotEmpty) ...[
              _buildSectionHeader('Medical History'),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(patient.medicalHistory, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 15),
            ],
            
            // Recent Vital Signs
            if (vitalSigns.isNotEmpty) ...[
              _buildSectionHeader('Recent Vital Signs (Last 5)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _tableCell('Date', isHeader: true),
                      _tableCell('BP', isHeader: true),
                      _tableCell('HR', isHeader: true),
                      _tableCell('Temp', isHeader: true),
                      _tableCell('SpO2', isHeader: true),
                      _tableCell('Weight', isHeader: true),
                    ],
                  ),
                  ...vitalSigns.take(5).map((v) => pw.TableRow(
                    children: [
                      _tableCell(_formatDate(v.recordedAt)),
                      _tableCell(_formatBloodPressure(v.systolicBp, v.diastolicBp)),
                      _tableCell(v.heartRate != null ? '${v.heartRate} bpm' : '-'),
                      _tableCell(v.temperature != null ? '${v.temperature}°C' : '-'),
                      _tableCell(v.oxygenSaturation != null ? '${v.oxygenSaturation}%' : '-'),
                      _tableCell(v.weight != null ? '${v.weight} kg' : '-'),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 15),
            ],
            
            // Recent Appointments
            if (appointments.isNotEmpty) ...[
              _buildSectionHeader('Recent Appointments (Last 10)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _tableCell('Date', isHeader: true),
                      _tableCell('Reason', isHeader: true),
                      _tableCell('Status', isHeader: true),
                    ],
                  ),
                  ...appointments.take(10).map((a) => pw.TableRow(
                    children: [
                      _tableCell(_formatDate(a.appointmentDateTime)),
                      _tableCell(a.reason.isEmpty ? 'General Visit' : a.reason),
                      _tableCell(a.status.toUpperCase()),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 15),
            ],
            
            // Active Prescriptions
            if (prescriptions.isNotEmpty) ...[
              _buildSectionHeader('Recent Prescriptions (Last 5)'),
              ...prescriptions.take(5).map((p) {
                final items = _parsePrescriptionItems(p.itemsJson);
                final firstItem = items.isNotEmpty ? items.first : null;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            (firstItem?['name'] as String?) ?? 'Prescription',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                          ),
                          pw.Text(_formatDate(p.createdAt), style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      if (firstItem != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${(firstItem['dosage'] as String?) ?? ''} - ${(firstItem['frequency'] as String?) ?? ''}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                      if (p.instructions.isNotEmpty)
                        pw.Text(
                          'Instructions: ${p.instructions}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 15),
            ],
            
            // Billing Summary
            if (invoices.isNotEmpty) ...[
              _buildSectionHeader('Billing Summary'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('Total Invoices', invoices.length.toString()),
                  _buildStatBox('Paid', invoices.where((i) => i.paymentStatus.toLowerCase() == 'paid').length.toString()),
                  _buildStatBox('Pending', invoices.where((i) => i.paymentStatus.toLowerCase() != 'paid').length.toString()),
                  _buildStatBox('Total Amount', 
                    '₹${invoices.fold<double>(0, (sum, i) => sum + i.grandTotal).toStringAsFixed(0)}'),
                ],
              ),
            ],
            
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Text(
              'This document is confidential and contains protected health information.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, 
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  // Helper method to format blood pressure from systolic/diastolic
  static String _formatBloodPressure(double? systolic, double? diastolic) {
    if (systolic == null && diastolic == null) return '-';
    final sys = systolic?.toInt() ?? 0;
    final dia = diastolic?.toInt() ?? 0;
    return '$sys/$dia';
  }

  // Helper method to format risk level from int to string
  static String _formatRiskLevel(int riskLevel) {
    switch (riskLevel) {
      case 1: return 'Low';
      case 2: return 'Low-Moderate';
      case 3: return 'Moderate';
      case 4: return 'Moderate-High';
      case 5: return 'High';
      default: return 'Unknown';
    }
  }

  // Helper method to parse prescription items from JSON
  static List<Map<String, dynamic>> _parsePrescriptionItems(String itemsJson) {
    try {
      final items = jsonDecode(itemsJson) as List<dynamic>;
      return items.map((item) => item as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate and share a monthly clinic report PDF
  static Future<void> shareMonthlyReportPdf({
    required String clinicName,
    required DateTime month,
    required MonthlyReportData reportData,
    String? doctorName,
    String? clinicAddress,
    String? clinicPhone,
  }) async {
    await _initFonts();
    
    final pdf = pw.Document(theme: _getTheme());
    final monthName = _getMonthName(month.month);
    final reportTitle = 'Monthly Clinic Report - $monthName ${month.year}';
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          clinicName: clinicName,
          reportTitle: reportTitle,
          doctorName: doctorName,
          clinicAddress: clinicAddress,
          clinicPhone: clinicPhone,
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (context) => [
          // Executive Summary Section
          _buildSectionTitle('Executive Summary'),
          pw.SizedBox(height: 10),
          _buildSummaryCards(reportData),
          pw.SizedBox(height: 20),
          
          // Patient Statistics
          _buildSectionTitle('Patient Statistics'),
          pw.SizedBox(height: 10),
          _buildPatientStats(reportData),
          pw.SizedBox(height: 20),
          
          // Appointment Statistics
          _buildSectionTitle('Appointment Statistics'),
          pw.SizedBox(height: 10),
          _buildAppointmentStats(reportData),
          pw.SizedBox(height: 20),
          
          // Financial Summary
          _buildSectionTitle('Financial Summary'),
          pw.SizedBox(height: 10),
          _buildFinancialStats(reportData),
          pw.SizedBox(height: 20),
          
          // Top Diagnoses
          if (reportData.topDiagnoses.isNotEmpty) ...[
            _buildSectionTitle('Top Diagnoses'),
            pw.SizedBox(height: 10),
            _buildTopDiagnosesList(reportData.topDiagnoses),
            pw.SizedBox(height: 20),
          ],
          
          // Prescription Summary
          if (reportData.prescriptionCount > 0) ...[
            _buildSectionTitle('Prescription Summary'),
            pw.SizedBox(height: 10),
            _buildPrescriptionStats(reportData),
            pw.SizedBox(height: 20),
          ],
          
          // Report Footer
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Report Generated',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Period: ${month.year}-${month.month.toString().padLeft(2, '0')}-01 to ${_getLastDayOfMonth(month)}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'monthly_report_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  static pw.Widget _buildReportHeader({
    required String clinicName,
    required String reportTitle,
    String? doctorName,
    String? clinicAddress,
    String? clinicPhone,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    clinicName,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  if (doctorName != null)
                    pw.Text(doctorName, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  if (clinicAddress != null)
                    pw.Text(clinicAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  if (clinicPhone != null)
                    pw.Text('Tel: $clinicPhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Icon(const pw.IconData(0xe1b1), size: 24, color: PdfColors.blue800), // Chart icon
                    pw.SizedBox(height: 4),
                    pw.Text('Monthly Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo900,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              reportTitle,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 1),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _buildSummaryCards(MonthlyReportData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBox('Total Patients', data.totalPatients.toString()),
        _buildStatBox('Appointments', data.totalAppointments.toString()),
        _buildStatBox('Revenue', 'Rs. ${data.totalRevenue.toStringAsFixed(0)}'),
        _buildStatBox('Prescriptions', data.prescriptionCount.toString()),
      ],
    );
  }

  static pw.Widget _buildPatientStats(MonthlyReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('New Patients:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('${data.newPatients}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Returning Patients:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('${data.returningPatients}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('High Risk Patients:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
              pw.Text('${data.highRiskPatients}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAppointmentStats(MonthlyReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Completed:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
              pw.Text('${data.completedAppointments}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cancelled:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
              pw.Text('${data.cancelledAppointments}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('No-Shows:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.orange700)),
              pw.Text('${data.noShowAppointments}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Completion Rate:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('${data.completionRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialStats(MonthlyReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Invoiced:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Rs. ${data.totalInvoiced.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Amount Collected:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
              pw.Text('Rs. ${data.totalRevenue.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Outstanding:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
              pw.Text('Rs. ${data.outstandingAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.green300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Collection Rate:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('${data.collectionRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopDiagnosesList(List<DiagnosisCount> diagnoses) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text('Diagnosis', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(flex: 1, child: pw.Text('Count', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 1, child: pw.Text('%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
            ],
          ),
          pw.Divider(color: PdfColors.grey300),
          ...diagnoses.take(10).map((d) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text(d.name, style: const pw.TextStyle(fontSize: 9))),
                pw.Expanded(flex: 1, child: pw.Text('${d.count}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 1, child: pw.Text('${d.percentage.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), textAlign: pw.TextAlign.right)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildPrescriptionStats(MonthlyReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Prescriptions:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('${data.prescriptionCount}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Unique Medications:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('${data.uniqueMedications}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Refillable Prescriptions:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('${data.refillablePrescriptions}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static String _getMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  static String _getLastDayOfMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';
  }
}

/// Data model for monthly report
class MonthlyReportData {
  final int totalPatients;
  final int newPatients;
  final int returningPatients;
  final int highRiskPatients;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int noShowAppointments;
  final double totalRevenue;
  final double totalInvoiced;
  final double outstandingAmount;
  final int prescriptionCount;
  final int uniqueMedications;
  final int refillablePrescriptions;
  final List<DiagnosisCount> topDiagnoses;

  MonthlyReportData({
    required this.totalPatients,
    required this.newPatients,
    required this.returningPatients,
    required this.highRiskPatients,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.noShowAppointments,
    required this.totalRevenue,
    required this.totalInvoiced,
    required this.outstandingAmount,
    required this.prescriptionCount,
    required this.uniqueMedications,
    required this.refillablePrescriptions,
    required this.topDiagnoses,
  });

  double get completionRate => totalAppointments > 0 
      ? (completedAppointments / totalAppointments) * 100 
      : 0;
  
  double get collectionRate => totalInvoiced > 0 
      ? (totalRevenue / totalInvoiced) * 100 
      : 0;
}

/// Data model for diagnosis count
class DiagnosisCount {
  final String name;
  final int count;
  final double percentage;

  DiagnosisCount({
    required this.name,
    required this.count,
    required this.percentage,
  });
}
