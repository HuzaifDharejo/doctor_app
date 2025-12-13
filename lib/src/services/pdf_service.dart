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
    List<Map<String, dynamic>>? medicationsList, // V5: Pre-loaded from normalized table
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
      medicationsList: medicationsList,
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
    List<Map<String, dynamic>>? lineItemsList, // V5: Pre-loaded from normalized table
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
      lineItemsList: lineItemsList,
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
                  if (patient.age != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Age:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text('${patient.age} years', style: const pw.TextStyle(fontSize: 12)),
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
        // Demographics
        if (data['name'] != null || data['age'] != null || data['gender'] != null) {
          final demographics = <String>[];
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            demographics.add('Name: ${data['name']}');
          }
          if (data['age'] != null && data['age'].toString().isNotEmpty) {
            demographics.add('Age: ${data['age']}');
          }
          if (data['gender'] != null && data['gender'].toString().isNotEmpty) {
            demographics.add('Gender: ${data['gender']}');
          }
          if (data['marital_status'] != null && data['marital_status'].toString().isNotEmpty) {
            demographics.add('Marital Status: ${data['marital_status']}');
          }
          if (demographics.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Demographics'),
              pw.SizedBox(height: 8),
              pw.Text(demographics.join(' | '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Chief Complaint
        if (data['chief_complaint'] != null && data['chief_complaint'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Chief Complaint'),
            pw.SizedBox(height: 8),
            pw.Text(data['chief_complaint'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Duration
        if (data['duration'] != null && data['duration'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Duration'),
            pw.SizedBox(height: 8),
            pw.Text(data['duration'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Presenting Symptoms
        if (data['symptoms'] != null && data['symptoms'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Presenting Symptoms'),
            pw.SizedBox(height: 8),
            pw.Text(data['symptoms'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // History of Present Illness
        if (data['hopi'] != null && data['hopi'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('History of Present Illness'),
            pw.SizedBox(height: 8),
            pw.Text(data['hopi'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Past Psychiatric History
        if (data['past_history'] != null && data['past_history'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Past Psychiatric History'),
            pw.SizedBox(height: 8),
            pw.Text(data['past_history'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Family History
        if (data['family_history'] != null && data['family_history'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Family History'),
            pw.SizedBox(height: 8),
            pw.Text(data['family_history'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Socioeconomic History
        if (data['socioeconomic'] != null && data['socioeconomic'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Socioeconomic History'),
            pw.SizedBox(height: 8),
            pw.Text(data['socioeconomic'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Mental Status Examination (flat format)
        final mseFields = <String, String>{
          'Mood': data['mood']?.toString() ?? '',
          'Affect': data['affect']?.toString() ?? '',
          'Speech': data['speech']?.toString() ?? '',
          'Thought': data['thought']?.toString() ?? '',
          'Perception': data['perception']?.toString() ?? '',
          'Cognition': data['cognition']?.toString() ?? '',
          'Insight': data['insight']?.toString() ?? '',
        };
        final nonEmptyMse = mseFields.entries.where((e) => e.value.isNotEmpty).toList();
        if (nonEmptyMse.isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Mental Status Examination'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(Map.fromEntries(nonEmptyMse.map((e) => MapEntry(e.key, e.value)))),
            pw.SizedBox(height: 16),
          ]);
        }
        // MSE nested format
        if (data['mse'] != null && data['mse'] is Map) {
          final mse = data['mse'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Mental Status Examination'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(mse),
            pw.SizedBox(height: 16),
          ]);
        }
        // Risk Assessment
        if (data['suicide_risk'] != null || data['homicide_risk'] != null) {
          final risks = <String>[];
          if (data['suicide_risk'] != null && data['suicide_risk'].toString().isNotEmpty) {
            risks.add('Suicide Risk: ${data['suicide_risk'].toString().toUpperCase()}');
          }
          if (data['homicide_risk'] != null && data['homicide_risk'].toString().isNotEmpty) {
            risks.add('Homicide Risk: ${data['homicide_risk'].toString().toUpperCase()}');
          }
          if (risks.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Risk Assessment'),
              pw.SizedBox(height: 8),
              pw.Text(risks.join(' | '), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Safety Plan
        if (data['safety_plan'] != null && data['safety_plan'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Safety Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['safety_plan'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Diagnosis
        if (data['diagnosis'] != null && data['diagnosis'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Diagnosis'),
            pw.SizedBox(height: 8),
            pw.Text(data['diagnosis'].toString(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Treatment Plan
        if (data['treatment_plan'] != null && data['treatment_plan'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Treatment Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['treatment_plan'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Medications
        if (data['medications'] != null && data['medications'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Medications'),
            pw.SizedBox(height: 8),
            pw.Text(data['medications'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Follow-up
        if (data['follow_up'] != null && data['follow_up'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Follow-up Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['follow_up'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        
      case 'pulmonary_evaluation':
        // Chief Complaint
        if (data['chief_complaint'] != null && data['chief_complaint'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Chief Complaint'),
            pw.SizedBox(height: 8),
            pw.Text(data['chief_complaint'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Duration
        if (data['duration'] != null && data['duration'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Duration'),
            pw.SizedBox(height: 8),
            pw.Text(data['duration'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Symptom Character (new form)
        if (data['symptom_character'] != null && data['symptom_character'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Symptom Character'),
            pw.SizedBox(height: 8),
            pw.Text(data['symptom_character'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Vitals
        if (data['vitals'] != null && data['vitals'] is Map) {
          final vitals = data['vitals'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Vital Signs'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(vitals),
            pw.SizedBox(height: 16),
          ]);
        }
        // Presenting Symptoms (legacy - Map<String, bool> format)
        if (data['symptoms'] != null && data['symptoms'] is Map) {
          final symptoms = (data['symptoms'] as Map<String, dynamic>)
              .entries.where((e) => e.value == true).map((e) => e.key).toList();
          if (symptoms.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Presenting Symptoms'),
              pw.SizedBox(height: 8),
              pw.Text(symptoms.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Systemic Symptoms (new form - List<String>)
        if (data['systemic_symptoms'] != null && data['systemic_symptoms'] is List) {
          final symptoms = List<String>.from(data['systemic_symptoms'] as List);
          if (symptoms.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Systemic Symptoms'),
              pw.SizedBox(height: 8),
              pw.Text(symptoms.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Red Flags (legacy - Map<String, bool> format)
        if (data['red_flags'] != null && data['red_flags'] is Map) {
          final flags = (data['red_flags'] as Map<String, dynamic>)
              .entries.where((e) => e.value == true).map((e) => e.key).toList();
          if (flags.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Red Flags'),
              pw.SizedBox(height: 8),
              pw.Text(flags.join(', '), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Red Flags (new form - List<String> format)
        if (data['red_flags'] != null && data['red_flags'] is List) {
          final flags = List<String>.from(data['red_flags'] as List);
          if (flags.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Red Flags'),
              pw.SizedBox(height: 8),
              pw.Text(flags.join(', '), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // ====== MEDICAL HISTORY SECTION (new form) ======
        if (data['past_pulmonary_history'] != null && data['past_pulmonary_history'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Past Pulmonary History'),
            pw.SizedBox(height: 8),
            pw.Text(data['past_pulmonary_history'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        if (data['exposure_history'] != null && data['exposure_history'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Exposure History'),
            pw.SizedBox(height: 8),
            pw.Text(data['exposure_history'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        if (data['allergy_atopy_history'] != null && data['allergy_atopy_history'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Allergy/Atopy History'),
            pw.SizedBox(height: 8),
            pw.Text(data['allergy_atopy_history'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Current Medications (new form - List<String>)
        if (data['current_medications'] != null && data['current_medications'] is List) {
          final meds = List<String>.from(data['current_medications'] as List);
          if (meds.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Current Medications'),
              pw.SizedBox(height: 8),
              pw.Text(meds.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Comorbidities (new form - List<String>)
        if (data['comorbidities'] != null && data['comorbidities'] is List) {
          final comorbidities = List<String>.from(data['comorbidities'] as List);
          if (comorbidities.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Comorbidities'),
              pw.SizedBox(height: 8),
              pw.Text(comorbidities.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Chest Findings (legacy - nested object)
        if (data['chest_findings'] != null && data['chest_findings'] is Map) {
          final findings = data['chest_findings'] as Map<String, dynamic>;
          widgets.addAll([
            _buildSectionHeader('Chest Examination'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(findings),
            pw.SizedBox(height: 16),
          ]);
        }
        // Chest Auscultation (new form - nested object with zones)
        if (data['chest_auscultation'] != null && data['chest_auscultation'] is Map) {
          final auscultation = data['chest_auscultation'] as Map<String, dynamic>;
          widgets.add(_buildSectionHeader('Chest Auscultation'));
          widgets.add(pw.SizedBox(height: 8));
          
          // Breath Sounds
          if (auscultation['breath_sounds'] != null && auscultation['breath_sounds'].toString().isNotEmpty) {
            widgets.add(pw.Text('Breath Sounds: ${auscultation['breath_sounds']}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
          }
          // Added Sounds
          if (auscultation['added_sounds'] != null && auscultation['added_sounds'] is List) {
            final sounds = List<String>.from(auscultation['added_sounds'] as List);
            if (sounds.isNotEmpty) {
              widgets.add(pw.Text('Added Sounds: ${sounds.join(', ')}', style: const pw.TextStyle(fontSize: 11)));
            }
          }
          // Zone findings
          final zones = <String, String>{
            'Right Upper Zone': auscultation['right_upper_zone']?.toString() ?? '',
            'Right Middle Zone': auscultation['right_middle_zone']?.toString() ?? '',
            'Right Lower Zone': auscultation['right_lower_zone']?.toString() ?? '',
            'Left Upper Zone': auscultation['left_upper_zone']?.toString() ?? '',
            'Left Middle Zone': auscultation['left_middle_zone']?.toString() ?? '',
            'Left Lower Zone': auscultation['left_lower_zone']?.toString() ?? '',
          };
          final nonEmptyZones = zones.entries.where((e) => e.value.isNotEmpty).toList();
          if (nonEmptyZones.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 4));
            for (final zone in nonEmptyZones) {
              widgets.add(pw.Text('${zone.key}: ${zone.value}', style: const pw.TextStyle(fontSize: 10)));
            }
          }
          // Additional Findings
          if (auscultation['additional_findings'] != null && auscultation['additional_findings'].toString().isNotEmpty) {
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Additional Findings: ${auscultation['additional_findings']}', style: const pw.TextStyle(fontSize: 11)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Breath Sounds (legacy - Map<String, bool> format)
        if (data['breath_sounds'] != null && data['breath_sounds'] is Map) {
          final sounds = (data['breath_sounds'] as Map<String, dynamic>)
              .entries.where((e) => e.value == true).map((e) => e.key).toList();
          if (sounds.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Breath Sounds'),
              pw.SizedBox(height: 8),
              pw.Text(sounds.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Diagnosis
        if (data['diagnosis'] != null && data['diagnosis'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Diagnosis'),
            pw.SizedBox(height: 8),
            pw.Text(data['diagnosis'].toString(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Differential
        if (data['differential'] != null && data['differential'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Differential Diagnosis'),
            pw.SizedBox(height: 8),
            pw.Text(data['differential'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Investigations (legacy - Map<String, bool> format)
        if (data['investigations'] != null && data['investigations'] is Map) {
          final invs = (data['investigations'] as Map<String, dynamic>)
              .entries.where((e) => e.value == true).map((e) => e.key).toList();
          if (invs.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Investigations Ordered'),
              pw.SizedBox(height: 8),
              pw.Text(invs.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Investigations Required (new form - List<String>)
        if (data['investigations_required'] != null && data['investigations_required'] is List) {
          final invs = List<String>.from(data['investigations_required'] as List);
          if (invs.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Investigations Required'),
              pw.SizedBox(height: 8),
              pw.Text(invs.join(', '), style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Treatment Plan (legacy)
        if (data['treatment_plan'] != null && data['treatment_plan'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Treatment Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['treatment_plan'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Medications (legacy)
        if (data['medications'] != null && data['medications'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Medications'),
            pw.SizedBox(height: 8),
            pw.Text(data['medications'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Follow-up (legacy)
        if (data['follow_up'] != null && data['follow_up'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Follow-up Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['follow_up'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Follow-up Plan (new form)
        if (data['follow_up_plan'] != null && data['follow_up_plan'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Follow-up Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['follow_up_plan'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        
      case 'lab_result':
        // Test Name and Category
        if (data['test_name'] != null && data['test_name'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Test Information'),
            pw.SizedBox(height: 8),
            pw.Text('Test: ${data['test_name']}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ]);
          if (data['test_category'] != null && data['test_category'].toString().isNotEmpty) {
            widgets.add(pw.Text('Category: ${data['test_category']}', style: const pw.TextStyle(fontSize: 11)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Result with status
        if (data['result'] != null && data['result'].toString().isNotEmpty) {
          final status = data['result_status']?.toString() ?? 'Normal';
          final statusColor = status.toLowerCase() == 'abnormal' ? PdfColors.red : 
                             status.toLowerCase() == 'critical' ? PdfColors.red900 : PdfColors.green;
          widgets.addAll([
            _buildSectionHeader('Result'),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(data['result'].toString(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: statusColor.shade(0.1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(status.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
          ]);
          if (data['units'] != null && data['units'].toString().isNotEmpty) {
            widgets.add(pw.Text('Units: ${data['units']}', style: const pw.TextStyle(fontSize: 10)));
          }
          if (data['reference_range'] != null && data['reference_range'].toString().isNotEmpty) {
            widgets.add(pw.Text('Reference Range: ${data['reference_range']}', style: const pw.TextStyle(fontSize: 10)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Specimen
        if (data['specimen'] != null && data['specimen'].toString().isNotEmpty) {
          widgets.addAll([
            pw.Text('Specimen: ${data['specimen']}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
          ]);
        }
        // Lab and Physician
        if (data['lab_name'] != null || data['ordering_physician'] != null) {
          final info = <String>[];
          if (data['lab_name'] != null && data['lab_name'].toString().isNotEmpty) {
            info.add('Lab: ${data['lab_name']}');
          }
          if (data['ordering_physician'] != null && data['ordering_physician'].toString().isNotEmpty) {
            info.add('Ordered by: ${data['ordering_physician']}');
          }
          if (info.isNotEmpty) {
            widgets.addAll([
              pw.Text(info.join(' | '), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Interpretation
        if (data['interpretation'] != null && data['interpretation'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Interpretation'),
            pw.SizedBox(height: 8),
            pw.Text(data['interpretation'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        
      case 'imaging':
        // Imaging type and body part
        if (data['imaging_type'] != null || data['body_part'] != null) {
          widgets.addAll([
            _buildSectionHeader('Study Information'),
            pw.SizedBox(height: 8),
          ]);
          if (data['imaging_type'] != null && data['imaging_type'].toString().isNotEmpty) {
            widgets.add(pw.Text('Type: ${data['imaging_type']}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)));
          }
          if (data['body_part'] != null && data['body_part'].toString().isNotEmpty) {
            widgets.add(pw.Text('Body Part: ${data['body_part']}', style: const pw.TextStyle(fontSize: 11)));
          }
          if (data['urgency'] != null && data['urgency'].toString().isNotEmpty) {
            widgets.add(pw.Text('Urgency: ${data['urgency']}', style: const pw.TextStyle(fontSize: 10)));
          }
          if (data['contrast_used'] == true) {
            widgets.add(pw.Text('Contrast Used: Yes', style: const pw.TextStyle(fontSize: 10)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Indication
        if (data['indication'] != null && data['indication'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Indication'),
            pw.SizedBox(height: 8),
            pw.Text(data['indication'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Technique
        if (data['technique'] != null && data['technique'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Technique'),
            pw.SizedBox(height: 8),
            pw.Text(data['technique'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Findings
        if (data['findings'] != null && data['findings'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Findings'),
            pw.SizedBox(height: 8),
            pw.Text(data['findings'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Impression
        if (data['impression'] != null && data['impression'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Impression'),
            pw.SizedBox(height: 8),
            pw.Text(data['impression'].toString(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Recommendations
        if (data['recommendations'] != null && data['recommendations'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Recommendations'),
            pw.SizedBox(height: 8),
            pw.Text(data['recommendations'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Radiologist and Facility
        if (data['radiologist'] != null || data['facility'] != null) {
          final info = <String>[];
          if (data['radiologist'] != null && data['radiologist'].toString().isNotEmpty) {
            info.add('Radiologist: ${data['radiologist']}');
          }
          if (data['facility'] != null && data['facility'].toString().isNotEmpty) {
            info.add('Facility: ${data['facility']}');
          }
          if (info.isNotEmpty) {
            widgets.addAll([
              pw.Text(info.join(' | '), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        
      case 'procedure':
        // Procedure name and code
        if (data['procedure_name'] != null && data['procedure_name'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Procedure'),
            pw.SizedBox(height: 8),
            pw.Text(data['procedure_name'].toString(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ]);
          if (data['procedure_code'] != null && data['procedure_code'].toString().isNotEmpty) {
            widgets.add(pw.Text('Code: ${data['procedure_code']}', style: const pw.TextStyle(fontSize: 10)));
          }
          if (data['procedure_status'] != null && data['procedure_status'].toString().isNotEmpty) {
            widgets.add(pw.Text('Status: ${data['procedure_status']}', style: const pw.TextStyle(fontSize: 10)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Timing
        if (data['start_time'] != null || data['end_time'] != null) {
          final timing = <String>[];
          if (data['start_time'] != null) timing.add('Start: ${data['start_time']}');
          if (data['end_time'] != null) timing.add('End: ${data['end_time']}');
          if (timing.isNotEmpty) {
            widgets.addAll([
              pw.Text(timing.join(' | '), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Indication
        if (data['indication'] != null && data['indication'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Indication'),
            pw.SizedBox(height: 8),
            pw.Text(data['indication'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Anesthesia
        if (data['anesthesia'] != null && data['anesthesia'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Anesthesia'),
            pw.SizedBox(height: 8),
            pw.Text(data['anesthesia'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Procedure Notes
        if (data['procedure_notes'] != null && data['procedure_notes'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Procedure Notes'),
            pw.SizedBox(height: 8),
            pw.Text(data['procedure_notes'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Findings
        if (data['findings'] != null && data['findings'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Findings'),
            pw.SizedBox(height: 8),
            pw.Text(data['findings'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Complications
        if (data['complications'] != null && data['complications'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Complications'),
            pw.SizedBox(height: 8),
            pw.Text(data['complications'].toString(), style: pw.TextStyle(fontSize: 11, color: PdfColors.red)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Specimen
        if (data['specimen'] != null && data['specimen'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Specimen Collected'),
            pw.SizedBox(height: 8),
            pw.Text(data['specimen'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Post-op Instructions
        if (data['post_op_instructions'] != null && data['post_op_instructions'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Post-Operative Instructions'),
            pw.SizedBox(height: 8),
            pw.Text(data['post_op_instructions'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Providers
        if (data['performed_by'] != null || data['assisted_by'] != null) {
          final providers = <String>[];
          if (data['performed_by'] != null && data['performed_by'].toString().isNotEmpty) {
            providers.add('Performed by: ${data['performed_by']}');
          }
          if (data['assisted_by'] != null && data['assisted_by'].toString().isNotEmpty) {
            providers.add('Assisted by: ${data['assisted_by']}');
          }
          if (providers.isNotEmpty) {
            widgets.addAll([
              pw.Text(providers.join(' | '), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Vitals (pre/post)
        if (data['vitals'] != null && data['vitals'] is Map) {
          final vitals = data['vitals'] as Map<String, dynamic>;
          final nonEmptyVitals = vitals.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
          if (nonEmptyVitals.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Vital Signs'),
              pw.SizedBox(height: 8),
              _buildKeyValueTable(Map.fromEntries(nonEmptyVitals.map((e) => MapEntry(e.key, e.value)))),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        
      case 'follow_up':
        // Progress notes
        if (data['progress_notes'] != null && data['progress_notes'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Progress Notes'),
            pw.SizedBox(height: 8),
            pw.Text(data['progress_notes'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        } else if (data['follow_up_notes'] != null && data['follow_up_notes'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Follow-up Notes'),
            pw.SizedBox(height: 8),
            pw.Text(data['follow_up_notes'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Overall progress
        if (data['overall_progress'] != null && data['overall_progress'].toString().isNotEmpty) {
          final progress = data['overall_progress'].toString();
          final progressColor = progress.toLowerCase() == 'improved' ? PdfColors.green :
                               progress.toLowerCase() == 'worsened' ? PdfColors.red : PdfColors.orange;
          widgets.addAll([
            pw.Row(
              children: [
                pw.Text('Overall Progress: ', style: const pw.TextStyle(fontSize: 11)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: progressColor.shade(0.1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(progress.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: progressColor)),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ]);
        }
        // Current symptoms
        if (data['symptoms'] != null && data['symptoms'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Current Symptoms'),
            pw.SizedBox(height: 8),
            pw.Text(data['symptoms'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Compliance
        if (data['compliance'] != null && data['compliance'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Medication Compliance'),
            pw.SizedBox(height: 8),
            pw.Text(data['compliance'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Side effects
        if (data['side_effects'] != null && data['side_effects'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Side Effects Reported'),
            pw.SizedBox(height: 8),
            pw.Text(data['side_effects'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Medication review
        if (data['medication_review'] != null && data['medication_review'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Medication Review'),
            pw.SizedBox(height: 8),
            pw.Text(data['medication_review'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Investigations
        if (data['investigations'] != null && data['investigations'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Investigations'),
            pw.SizedBox(height: 8),
            pw.Text(data['investigations'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Next follow-up
        if (data['next_follow_up_date'] != null || data['next_follow_up_notes'] != null) {
          widgets.add(_buildSectionHeader('Next Follow-up'));
          widgets.add(pw.SizedBox(height: 8));
          if (data['next_follow_up_date'] != null) {
            try {
              final date = DateTime.parse(data['next_follow_up_date'].toString());
              widgets.add(pw.Text('Date: ${date.day}/${date.month}/${date.year}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
            } catch (_) {
              widgets.add(pw.Text('Date: ${data['next_follow_up_date']}', style: const pw.TextStyle(fontSize: 11)));
            }
          }
          if (data['next_follow_up_notes'] != null && data['next_follow_up_notes'].toString().isNotEmpty) {
            widgets.add(pw.Text(data['next_follow_up_notes'].toString(), style: const pw.TextStyle(fontSize: 11)));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        // Vitals
        if (data['vitals'] != null && data['vitals'] is Map) {
          final vitals = data['vitals'] as Map<String, dynamic>;
          final nonEmptyVitals = vitals.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
          if (nonEmptyVitals.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Vital Signs'),
              pw.SizedBox(height: 8),
              _buildKeyValueTable(Map.fromEntries(nonEmptyVitals.map((e) => MapEntry(e.key, e.value)))),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        
      case 'general':
        // General record - display all data dynamically
        // Record Type/Title
        if (data['record_type'] != null && data['record_type'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Record Type'),
            pw.SizedBox(height: 8),
            pw.Text(data['record_type'].toString(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Description
        if (data['description'] != null && data['description'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Description'),
            pw.SizedBox(height: 8),
            pw.Text(data['description'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Chief Complaint
        if (data['chief_complaint'] != null && data['chief_complaint'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Chief Complaint'),
            pw.SizedBox(height: 8),
            pw.Text(data['chief_complaint'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Vitals
        if (data['vitals'] != null && data['vitals'] is Map) {
          final vitals = data['vitals'] as Map<String, dynamic>;
          final nonEmptyVitals = vitals.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
          if (nonEmptyVitals.isNotEmpty) {
            widgets.addAll([
              _buildSectionHeader('Vital Signs'),
              pw.SizedBox(height: 8),
              _buildKeyValueTable(Map.fromEntries(nonEmptyVitals.map((e) => MapEntry(e.key, e.value)))),
              pw.SizedBox(height: 16),
            ]);
          }
        }
        // Notes/Comments
        if (data['notes'] != null && data['notes'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Notes'),
            pw.SizedBox(height: 8),
            pw.Text(data['notes'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Clinical Findings
        if (data['findings'] != null && data['findings'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Clinical Findings'),
            pw.SizedBox(height: 8),
            pw.Text(data['findings'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Diagnosis
        if (data['diagnosis'] != null && data['diagnosis'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Diagnosis'),
            pw.SizedBox(height: 8),
            pw.Text(data['diagnosis'].toString(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Treatment
        if (data['treatment'] != null && data['treatment'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Treatment'),
            pw.SizedBox(height: 8),
            pw.Text(data['treatment'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Medications
        if (data['medications'] != null && data['medications'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Medications'),
            pw.SizedBox(height: 8),
            pw.Text(data['medications'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Follow-up
        if (data['follow_up'] != null && data['follow_up'].toString().isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Follow-up Plan'),
            pw.SizedBox(height: 8),
            pw.Text(data['follow_up'].toString(), style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
          ]);
        }
        // Display any other data fields dynamically
        final handledKeys = {'record_type', 'description', 'chief_complaint', 'vitals', 'notes', 'findings', 'diagnosis', 'treatment', 'medications', 'follow_up'};
        final otherData = data.entries.where((e) => !handledKeys.contains(e.key) && e.value != null && e.value.toString().isNotEmpty).toList();
        if (otherData.isNotEmpty) {
          widgets.addAll([
            _buildSectionHeader('Additional Information'),
            pw.SizedBox(height: 8),
            _buildKeyValueTable(Map.fromEntries(otherData.map((e) => MapEntry(e.key, e.value)))),
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
    List<Map<String, dynamic>>? medicationsList, // V5: Pre-loaded from normalized table
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
    
    // V5: Use pre-loaded medications if provided, otherwise parse from itemsJson
    List<dynamic> medications = medicationsList ?? [];
    List<dynamic> labTests = [];
    Map<String, dynamic> followUp = {};
    String notes = '';
    String diagnosis = prescription.diagnosis;
    String chiefComplaint = prescription.chiefComplaint;
    
    // Parse additional data from itemsJson (lab tests, follow-up, notes)
    try {
      final parsed = jsonDecode(prescription.itemsJson);
      if (parsed is List) {
        // Old format: just array of medications
        if (medications.isEmpty) medications = parsed;
      } else if (parsed is Map<String, dynamic>) {
        // New format: full prescription object
        if (medications.isEmpty) {
          medications = (parsed['medications'] as List<dynamic>?) ?? [];
        }
        labTests = (parsed['lab_tests'] as List<dynamic>?) ?? [];
        followUp = (parsed['follow_up'] as Map<String, dynamic>?) ?? {};
        notes = (parsed['notes'] as String?) ?? '';
        // Use from JSON if available (may have more complete data)
        if ((parsed['diagnosis'] as String?)?.isNotEmpty == true) {
          diagnosis = parsed['diagnosis'] as String;
        }
        if ((parsed['symptoms'] as String?)?.isNotEmpty == true) {
          chiefComplaint = parsed['symptoms'] as String;
        }
      }
    } catch (e) {
      log.w('PDF', 'Error parsing prescription itemsJson: $e');
    }

    // Parse vitals from vitalsJson
    Map<String, dynamic> vitals = {};
    try {
      if (prescription.vitalsJson.isNotEmpty && prescription.vitalsJson != '{}') {
        vitals = jsonDecode(prescription.vitalsJson) as Map<String, dynamic>;
      }
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
              pw.SizedBox(height: 12),
              
              // Vitals Section (if available)
              if (vitals.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Vitals:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue800)),
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          // Support both snake_case and camelCase field names
                          if ((vitals['bp'] ?? vitals['blood_pressure']) != null && (vitals['bp'] ?? vitals['blood_pressure']).toString().isNotEmpty && (vitals['bp'] ?? vitals['blood_pressure']).toString() != '-/-')
                            pw.Text('BP: ${vitals['bp'] ?? vitals['blood_pressure']}', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['pulse'] ?? vitals['heart_rate'] ?? vitals['heartRate']) != null && (vitals['pulse'] ?? vitals['heart_rate'] ?? vitals['heartRate']).toString().isNotEmpty && (vitals['pulse'] ?? vitals['heart_rate'] ?? vitals['heartRate']).toString() != '-')
                            pw.Text('Pulse: ${vitals['pulse'] ?? vitals['heart_rate'] ?? vitals['heartRate']} bpm', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['temperature'] ?? vitals['temp']) != null && (vitals['temperature'] ?? vitals['temp']).toString().isNotEmpty && (vitals['temperature'] ?? vitals['temp']).toString() != '-')
                            pw.Text('Temp: ${vitals['temperature'] ?? vitals['temp']}°F', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['respiratory_rate'] ?? vitals['respiratoryRate'] ?? vitals['rr']) != null && (vitals['respiratory_rate'] ?? vitals['respiratoryRate'] ?? vitals['rr']).toString().isNotEmpty && (vitals['respiratory_rate'] ?? vitals['respiratoryRate'] ?? vitals['rr']).toString() != '-')
                            pw.Text('RR: ${vitals['respiratory_rate'] ?? vitals['respiratoryRate'] ?? vitals['rr']}/min', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['spo2'] ?? vitals['oxygenSaturation'] ?? vitals['oxygen_saturation']) != null && (vitals['spo2'] ?? vitals['oxygenSaturation'] ?? vitals['oxygen_saturation']).toString().isNotEmpty && (vitals['spo2'] ?? vitals['oxygenSaturation'] ?? vitals['oxygen_saturation']).toString() != '-')
                            pw.Text('SpO2: ${vitals['spo2'] ?? vitals['oxygenSaturation'] ?? vitals['oxygen_saturation']}%', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['weight'] ?? vitals['wt']) != null && (vitals['weight'] ?? vitals['wt']).toString().isNotEmpty && (vitals['weight'] ?? vitals['wt']).toString() != '-')
                            pw.Text('Wt: ${vitals['weight'] ?? vitals['wt']} kg', style: const pw.TextStyle(fontSize: 10)),
                          if ((vitals['height'] ?? vitals['ht']) != null && (vitals['height'] ?? vitals['ht']).toString().isNotEmpty && (vitals['height'] ?? vitals['ht']).toString() != '-')
                            pw.Text('Ht: ${vitals['height'] ?? vitals['ht']} cm', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Chief Complaint / Symptoms
              if (chiefComplaint.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange200),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.orange50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Chief Complaint:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.orange800)),
                      pw.SizedBox(height: 4),
                      pw.Text(chiefComplaint, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Diagnosis
              if (diagnosis.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.purple50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Diagnosis:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.purple800)),
                      pw.SizedBox(height: 4),
                      pw.Text(diagnosis, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
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
              if (medications.isNotEmpty) ...[
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
                pw.SizedBox(height: 16),
              ],
              
              // Lab Tests / Investigations
              if (labTests.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.teal200),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.teal50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Investigations Advised:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.teal800)),
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: labTests.map((test) {
                          final testName = test is Map ? (test['name'] as String? ?? test.toString()) : test.toString();
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              border: pw.Border.all(color: PdfColors.teal300),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(testName, style: const pw.TextStyle(fontSize: 9)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Instructions / Advice
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
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(prescription.instructions),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Follow-up
              if (followUp.isNotEmpty && followUp['date'] != null) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green200),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.green50,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('Follow-up: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green800)),
                      pw.Text(_formatDate(DateTime.parse(followUp['date'] as String)), style: const pw.TextStyle(fontSize: 11)),
                      if ((followUp['notes'] as String?)?.isNotEmpty == true) ...[
                        pw.Text(' - ', style: const pw.TextStyle(fontSize: 11)),
                        pw.Expanded(child: pw.Text(followUp['notes'] as String, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Clinical Notes (if available)
              if (notes.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Clinical Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(notes, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
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
    List<Map<String, dynamic>>? lineItemsList, // V5: Pre-loaded from normalized table
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
    
    // V5: Use pre-loaded items if provided, otherwise parse from itemsJson
    List<dynamic> items = lineItemsList ?? [];
    if (items.isEmpty) {
      try {
        items = jsonDecode(invoice.itemsJson) as List<dynamic>;
      } catch (_) {}
    }

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
    
    // Get patient age
    String age = '';
    if (patient.age != null) {
      age = '${patient.age} years';
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
