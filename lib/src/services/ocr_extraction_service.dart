import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Information about a detected section on the prescription pad
class SectionInfo {
  final String type; // 'history', 'diagnosis', 'medications', 'lab_tests', 'radiology', 'advice', 'follow_up'
  final String label; // The actual text label found (e.g., "Labs/Investigations:")
  final double yPosition; // Y coordinate for ordering
  
  SectionInfo({
    required this.type,
    required this.label,
    required this.yPosition,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'yPosition': yPosition,
    };
  }
  
  factory SectionInfo.fromMap(Map<String, dynamic> map) {
    return SectionInfo(
      type: map['type'] as String,
      label: map['label'] as String,
      yPosition: (map['yPosition'] as num).toDouble(),
    );
  }
}

class OcrExtractionService {
  static final _textRecognizer = TextRecognizer();
  
  /// Extract prescription pad structure and data from PDF file path
  /// Note: This extracts text directly from PDF. For scanned PDFs (image-based),
  /// please convert to an image first for better OCR accuracy.
  /// Returns map with: expertIn, workingExperience, clinics, sections
  static Future<Map<String, dynamic>> extractFromPdf(String pdfPath) async {
    try {
      // Read PDF file
      final pdfFile = File(pdfPath);
      final pdfBytes = await pdfFile.readAsBytes();
      return extractFromPdfBytes(pdfBytes);
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }
  
  /// Extract prescription pad structure and data from PDF bytes
  /// Note: This extracts text directly from PDF. For scanned PDFs (image-based),
  /// please convert to an image first for better OCR accuracy.
  /// Returns map with: expertIn, workingExperience, clinics, sections
  static Future<Map<String, dynamic>> extractFromPdfBytes(Uint8List pdfBytes) async {
    try {
      // Extract text from PDF
      final pdfDocument = PdfDocument(inputBytes: pdfBytes);
      if (pdfDocument.pages.count == 0) {
        pdfDocument.dispose();
        throw Exception('PDF has no pages');
      }
      
      // Extract text from first page only
      final textExtractor = PdfTextExtractor(pdfDocument);
      final pageText = textExtractor.extractText(startPageIndex: 0, endPageIndex: 0);
      
      pdfDocument.dispose();
      
      if (pageText.trim().isEmpty) {
        throw Exception('No text found in PDF. If this is a scanned PDF, please convert it to an image first.');
      }
      
      // Parse text-based extraction (without position info, sections detected by text patterns)
      return _extractFromText(pageText);
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }
  
  /// Extract data from plain text (used for PDF text extraction)
  static Map<String, dynamic> _extractFromText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    List<String> expertIn = [];
    String workingExperience = '';
    List<Map<String, String>> clinics = [];
    List<SectionInfo> detectedSections = [];
    
    // Use line numbers as approximate Y positions
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final approximateY = i * 20.0; // Approximate Y position
      
      // Detect sections
      final section = _detectPrescriptionSection(line, approximateY);
      if (section != null) {
        detectedSections.add(section);
      }
      
      // Extract expert in
      if (line.contains(RegExp(r'Expert In', caseSensitive: false))) {
        expertIn = _extractExpertInFromText(lines, i);
      }
      
      // Extract working experience
      if (line.contains(RegExp(r'Working experience', caseSensitive: false))) {
        workingExperience = _extractWorkingExperienceFromText(lines, i);
      }
      
      // Extract clinic info (footer area - last 25% of lines)
      if (i > lines.length * 0.75) {
        final clinicInfo = _extractClinicInfoFromText(line);
        if (clinicInfo != null && !clinics.any((c) => c['name'] == clinicInfo['name'])) {
          clinics.add(clinicInfo);
        }
      }
    }
    
    // Sort sections by line position
    detectedSections.sort((a, b) => a.yPosition.compareTo(b.yPosition));
    
    return {
      'expertIn': expertIn,
      'workingExperience': workingExperience,
      'clinics': clinics,
      'sections': detectedSections.map((s) => s.toMap()).toList(),
    };
  }
  
  static List<String> _extractExpertInFromText(List<String> lines, int startIndex) {
    final expertIn = <String>[];
    for (int i = startIndex + 1; i < lines.length && i < startIndex + 10; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'Working experience|Patient|Name:', caseSensitive: false))) {
        break;
      }
      final diseases = line.split(RegExp(r'\s*[-–—]\s*'))
          .map((d) => d.trim())
          .where((d) => d.length > 2 && !d.contains(':'))
          .toList();
      expertIn.addAll(diseases);
    }
    return expertIn;
  }
  
  static String _extractWorkingExperienceFromText(List<String> lines, int startIndex) {
    final experience = <String>[];
    for (int i = startIndex + 1; i < lines.length && i < startIndex + 10; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'Patient|Name:', caseSensitive: false))) {
        break;
      }
      if (line.contains(RegExp(r'Hospital|Member|Society|College|University', caseSensitive: false))) {
        experience.add(line.replaceAll(RegExp(r'^[-•]\s*'), '').trim());
      }
    }
    return experience.join('\n');
  }
  
  static Map<String, String>? _extractClinicInfoFromText(String text) {
    final clinicNameMatch = RegExp(
      r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:\s+(?:Medical|Hospital|Clinic|Complex|Center)))',
      caseSensitive: false
    ).firstMatch(text);
    
    if (clinicNameMatch == null) return null;
    
    final clinicName = clinicNameMatch.group(1) ?? '';
    String address = '';
    List<String> phones = [];
    String hours = '';
    
    final addressMatch = RegExp(
      r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Road|Street|Avenue|Boulevard).*?(?:Lahore|Karachi|Islamabad|Rawalpindi))',
      caseSensitive: false
    ).firstMatch(text);
    address = addressMatch?.group(1) ?? '';
    
    final phoneMatches = RegExp(r'(\d{2,3}[-.\s]?\d{7,9})').allMatches(text);
    phones = phoneMatches
        .map((m) => m.group(1)?.replaceAll(RegExp(r'[-.\s]'), '') ?? '')
        .where((p) => p.length >= 10)
        .toList();
    
    final hoursMatch = RegExp(
      r'(\d+\s+to\s+\d+\s+(?:AM|PM).*?(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday).*?(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)?)',
      caseSensitive: false
    ).firstMatch(text);
    hours = hoursMatch?.group(1) ?? '';
    
    return {
      'name': clinicName,
      'address': address,
      'phone1': phones.isNotEmpty ? phones[0] : '',
      'phone2': phones.length > 1 ? phones[1] : '',
      'hours': hours,
    };
  }
  
  /// Extract prescription pad structure and data from image
  /// Returns map with: expertIn, workingExperience, clinics, sections
  static Future<Map<String, dynamic>> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Get image dimensions
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Could not decode image');
    
    final imageHeight = image.height;
    final headerThreshold = imageHeight * 0.25;
    final footerThreshold = imageHeight * 0.75;
    
    // Extract data
    List<String> expertIn = [];
    String workingExperience = '';
    List<Map<String, String>> clinics = [];
    List<SectionInfo> detectedSections = [];
    
    // Process text blocks
    for (final block in recognizedText.blocks) {
      final y = block.boundingBox.top;
      final text = block.text.trim();
      
      if (y < headerThreshold) {
        // HEADER ZONE - Extract Expert In and Working Experience
        if (text.contains(RegExp(r'Expert In', caseSensitive: false))) {
          expertIn = _extractExpertInList(recognizedText, block);
        }
        
        if (text.contains(RegExp(r'Working experience', caseSensitive: false))) {
          workingExperience = _extractWorkingExperience(recognizedText, block);
        }
      }
      else if (y > footerThreshold) {
        // FOOTER ZONE - Extract clinic information
        final clinicInfo = _extractClinicInfo(text, recognizedText, block);
        if (clinicInfo != null) {
          clinics.add(clinicInfo);
        }
      }
      else {
        // BODY ZONE - Detect prescription sections
        final section = _detectPrescriptionSection(text, y);
        if (section != null) {
          detectedSections.add(section);
        }
      }
    }
    
    // Sort sections by Y position (top to bottom)
    detectedSections.sort((a, b) => a.yPosition.compareTo(b.yPosition));
    
    return {
      'expertIn': expertIn,
      'workingExperience': workingExperience,
      'clinics': clinics,
      'sections': detectedSections.map((s) => s.toMap()).toList(),
    };
  }
  
  /// Detect prescription section labels in body zone
  static SectionInfo? _detectPrescriptionSection(String text, double yPosition) {
    // Common section labels found on prescription pads
    final sectionPatterns = {
      'history': RegExp(r'History\s*:', caseSensitive: false),
      'diagnosis': RegExp(r'(Impression|Diagnosis)\s*:', caseSensitive: false),
      'medications': RegExp(r'(Medication|Medicine|Rx|Prescription)\s*:', caseSensitive: false),
      'lab_tests': RegExp(r'(Labs|Lab Tests|Investigations|Lab/Investigations)\s*:', caseSensitive: false),
      'radiology': RegExp(r'Radiology\s*:', caseSensitive: false),
      'advice': RegExp(r'(Advice|Instructions|Note|Remarks)\s*:', caseSensitive: false),
      'follow_up': RegExp(r'(Next Visit|Follow-up|Follow up|Review)\s*:', caseSensitive: false),
    };
    
    for (final entry in sectionPatterns.entries) {
      if (entry.value.hasMatch(text)) {
        // Extract the full label text
        final match = entry.value.firstMatch(text);
        if (match != null) {
          return SectionInfo(
            type: entry.key,
            label: text.substring(0, match.end).trim(),
            yPosition: yPosition,
          );
        }
      }
    }
    
    return null;
  }
  
  static List<String> _extractExpertInList(RecognizedText fullText, TextBlock startBlock) {
    final expertIn = <String>[];
    bool foundStart = false;
    
    for (final block in fullText.blocks) {
      if (block == startBlock) {
        foundStart = true;
        continue;
      }
      
      if (foundStart) {
        final text = block.text.trim();
        // Stop if we hit "Working experience" or "Patient" section
        if (text.contains(RegExp(r'Working experience|Patient|Name:', caseSensitive: false))) {
          break;
        }
        
        // Extract diseases (split by dashes, commas)
        // Format: "Asthma - Allergy - Vaccination - Sleep Disorders..."
        final diseases = text.split(RegExp(r'\s*[-–—]\s*'))
            .map((d) => d.trim())
            .where((d) => d.length > 2 && !d.contains(':'))
            .toList();
        expertIn.addAll(diseases);
      }
    }
    
    return expertIn;
  }
  
  static String _extractWorkingExperience(RecognizedText fullText, TextBlock startBlock) {
    final experience = <String>[];
    bool foundStart = false;
    
    for (final block in fullText.blocks) {
      if (block == startBlock) {
        foundStart = true;
        continue;
      }
      
      if (foundStart) {
        final text = block.text.trim();
        // Stop if we hit "Patient" section
        if (text.contains(RegExp(r'Patient|Name:', caseSensitive: false))) {
          break;
        }
        
        // Extract hospital/position lines
        // Format: "- Govt. Hospital Samanabad Lhr."
        if (text.contains(RegExp(r'^[-•]\s*', caseSensitive: false)) || 
            text.contains(RegExp(r'Hospital|Member|Society|College|University', caseSensitive: false))) {
          experience.add(text.replaceAll(RegExp(r'^[-•]\s*'), '').trim());
        }
      }
    }
    
    return experience.join('\n');
  }
  
  static Map<String, String>? _extractClinicInfo(String text, RecognizedText fullText, TextBlock block) {
    // Look for clinic name patterns
    final clinicNameMatch = RegExp(
      r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:\s+(?:Medical|Hospital|Clinic|Complex|Center)))',
      caseSensitive: false
    ).firstMatch(text);
    
    if (clinicNameMatch == null) return null;
    
    final clinicName = clinicNameMatch.group(1) ?? '';
    String address = '';
    List<String> phones = [];
    String hours = '';
    
    // Extract address (look for road names, city)
    final addressMatch = RegExp(
      r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Road|Street|Avenue|Boulevard).*?(?:Lahore|Karachi|Islamabad|Rawalpindi))',
      caseSensitive: false
    ).firstMatch(text);
    address = addressMatch?.group(1) ?? '';
    
    // Extract phone numbers (Pakistani format)
    // Patterns: 03XX-XXXXXXX, 042-XXXXXXX, 03030308415
    final phoneMatches = RegExp(r'(\d{2,3}[-.\s]?\d{7,9})').allMatches(text);
    phones = phoneMatches
        .map((m) => m.group(1)?.replaceAll(RegExp(r'[-.\s]'), '') ?? '')
        .where((p) => p.length >= 10)
        .toList();
    
    // Extract hours (look for time patterns)
    // Format: "2 to 5 PM (On call) Monday to Saturday"
    final hoursMatch = RegExp(
      r'(\d+\s+to\s+\d+\s+(?:AM|PM).*?(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday).*?(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)?)',
      caseSensitive: false
    ).firstMatch(text);
    hours = hoursMatch?.group(1) ?? '';
    
    return {
      'name': clinicName,
      'address': address,
      'phone1': phones.isNotEmpty ? phones[0] : '',
      'phone2': phones.length > 1 ? phones[1] : '',
      'hours': hours,
    };
  }
  
  static void dispose() {
    _textRecognizer.close();
  }
}

