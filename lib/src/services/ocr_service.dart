import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting text from images and PDFs
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  TextRecognizer? _textRecognizer;

  /// Initialize the text recognizer
  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Extract text from an image file
  /// Returns the extracted text or null if extraction fails
  Future<OcrResult> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      return OcrResult(
        success: false,
        errorMessage: 'OCR is not supported on web platform. Please use the mobile app.',
      );
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return OcrResult(
          success: false,
          errorMessage: 'No text found in the image. Please ensure the image is clear and contains readable text.',
        );
      }

      // Parse the recognized text to extract structured data
      final parsedData = _parseExtractedText(recognizedText.text);

      return OcrResult(
        success: true,
        rawText: recognizedText.text,
        parsedData: parsedData,
        blocks: recognizedText.blocks.map((block) => TextBlockInfo(
          text: block.text,
          confidence: block.lines.isNotEmpty 
              ? block.lines.map((l) => l.confidence ?? 0.0).reduce((a, b) => a + b) / block.lines.length
              : 0.0,
        )).toList(),
      );
    } catch (e) {
      return OcrResult(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  /// Extract text from image bytes (for web or memory-based images)
  Future<OcrResult> extractTextFromImageBytes(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      return OcrResult(
        success: false,
        errorMessage: 'OCR is not supported on web platform. Please use the mobile app.',
      );
    }

    try {
      // Create a temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      final result = await extractTextFromImage(tempFile.path);

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      return result;
    } catch (e) {
      return OcrResult(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  /// Extract text from a PDF file
  Future<OcrResult> extractTextFromPdf(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      return extractTextFromPdfBytes(bytes);
    } catch (e) {
      return OcrResult(
        success: false,
        errorMessage: 'Failed to read PDF file: ${e.toString()}',
      );
    }
  }

  /// Extract text from PDF bytes
  Future<OcrResult> extractTextFromPdfBytes(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final StringBuffer extractedText = StringBuffer();

      // Extract text from all pages
      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.isNotEmpty) {
          extractedText.writeln('--- Page ${i + 1} ---');
          extractedText.writeln(pageText);
          extractedText.writeln();
        }
      }

      document.dispose();

      final text = extractedText.toString().trim();

      if (text.isEmpty || text == '--- Page 1 ---') {
        return OcrResult(
          success: false,
          errorMessage: 'No text found in the PDF. The PDF might be image-based or encrypted.',
        );
      }

      final parsedData = _parseExtractedText(text);

      return OcrResult(
        success: true,
        rawText: text,
        parsedData: parsedData,
      );
    } catch (e) {
      return OcrResult(
        success: false,
        errorMessage: 'Failed to process PDF: ${e.toString()}',
      );
    }
  }

  /// Parse extracted text to identify medical data
  Map<String, String> _parseExtractedText(String text) {
    final Map<String, String> data = {};
    final lines = text.split('\n');

    // Common patterns to look for in medical documents
    final patterns = {
      'patient_name': RegExp(r'(?:patient\s*name|name)\s*[:\-]?\s*(.+)', caseSensitive: false),
      'date': RegExp(r'(?:date|dated?)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      'diagnosis': RegExp(r'(?:diagnosis|dx|impression)\s*[:\-]?\s*(.+)', caseSensitive: false),
      'blood_pressure': RegExp(r'(?:bp|blood\s*pressure)\s*[:\-]?\s*(\d{2,3}\/\d{2,3})', caseSensitive: false),
      'pulse': RegExp(r'(?:pulse|heart\s*rate|hr)\s*[:\-]?\s*(\d{2,3})', caseSensitive: false),
      'temperature': RegExp(r'(?:temp|temperature)\s*[:\-]?\s*([\d\.]+)\s*(?:°?[CF])?', caseSensitive: false),
      'weight': RegExp(r'(?:weight|wt)\s*[:\-]?\s*([\d\.]+)\s*(?:kg|lbs?)?', caseSensitive: false),
      'hemoglobin': RegExp(r'(?:hb|hemoglobin|haemoglobin)\s*[:\-]?\s*([\d\.]+)', caseSensitive: false),
      'blood_sugar': RegExp(r'(?:blood\s*sugar|glucose|bs|fbs|rbs)\s*[:\-]?\s*([\d\.]+)', caseSensitive: false),
      'cholesterol': RegExp(r'(?:cholesterol|total\s*cholesterol)\s*[:\-]?\s*([\d\.]+)', caseSensitive: false),
      'creatinine': RegExp(r'(?:creatinine|serum\s*creatinine)\s*[:\-]?\s*([\d\.]+)', caseSensitive: false),
      'treatment': RegExp(r'(?:treatment|rx|prescription|medications?)\s*[:\-]?\s*(.+)', caseSensitive: false),
      'test_name': RegExp(r'(?:test\s*name|investigation|procedure)\s*[:\-]?\s*(.+)', caseSensitive: false),
      'result': RegExp(r'(?:result|value|reading)\s*[:\-]?\s*(.+)', caseSensitive: false),
      'reference_range': RegExp(r'(?:reference\s*range|normal\s*range|ref\.?\s*range)\s*[:\-]?\s*(.+)', caseSensitive: false),
    };

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      for (final entry in patterns.entries) {
        final match = entry.value.firstMatch(trimmedLine);
        if (match != null && match.group(1) != null) {
          final value = match.group(1)!.trim();
          if (value.isNotEmpty && !data.containsKey(entry.key)) {
            data[entry.key] = value;
          }
        }
      }
    }

    // Also store the full text for reference
    data['full_text'] = text;

    return data;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

/// Result of OCR extraction
class OcrResult {
  final bool success;
  final String? rawText;
  final Map<String, String>? parsedData;
  final List<TextBlockInfo>? blocks;
  final String? errorMessage;

  OcrResult({
    required this.success,
    this.rawText,
    this.parsedData,
    this.blocks,
    this.errorMessage,
  });

  /// Get a specific parsed field
  String? getField(String key) => parsedData?[key];

  /// Check if a field exists
  bool hasField(String key) => parsedData?.containsKey(key) ?? false;
}

/// Information about a text block
class TextBlockInfo {
  final String text;
  final double confidence;

  TextBlockInfo({
    required this.text,
    required this.confidence,
  });
}
