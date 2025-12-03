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
}
