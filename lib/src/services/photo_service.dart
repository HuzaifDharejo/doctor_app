import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// Service for handling patient photos
/// Photos are stored as base64 strings in SharedPreferences for web compatibility
class PhotoService {
  static const String _photoPrefix = 'patient_photo_';
  
  /// Save a photo for a patient
  /// Returns the base64 string if successful
  static Future<String?> savePatientPhoto(int patientId, Uint8List imageBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Image = base64Encode(imageBytes);
      await prefs.setString('$_photoPrefix$patientId', base64Image);
      return base64Image;
    } catch (e, stackTrace) {
      log.e('PHOTO', 'Error saving patient photo', error: e, stackTrace: stackTrace, extra: {'patientId': patientId});
      return null;
    }
  }
  
  /// Get a patient's photo as base64 string
  static Future<String?> getPatientPhoto(int patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_photoPrefix$patientId');
    } catch (e, stackTrace) {
      log.e('PHOTO', 'Error getting patient photo', error: e, stackTrace: stackTrace, extra: {'patientId': patientId});
      return null;
    }
  }
  
  /// Get a patient's photo as bytes
  static Future<Uint8List?> getPatientPhotoBytes(int patientId) async {
    final base64 = await getPatientPhoto(patientId);
    if (base64 != null) {
      try {
        return base64Decode(base64);
      } catch (e, stackTrace) {
        log.e('PHOTO', 'Error decoding patient photo', error: e, stackTrace: stackTrace, extra: {'patientId': patientId});
        return null;
      }
    }
    return null;
  }
  
  /// Delete a patient's photo
  static Future<bool> deletePatientPhoto(int patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.remove('$_photoPrefix$patientId');
    } catch (e, stackTrace) {
      log.e('PHOTO', 'Error deleting patient photo', error: e, stackTrace: stackTrace, extra: {'patientId': patientId});
      return false;
    }
  }
  
  /// Check if a patient has a photo
  static Future<bool> hasPhoto(int patientId) async {
    final photo = await getPatientPhoto(patientId);
    return photo != null && photo.isNotEmpty;
  }
  
  /// Compress image if too large (for web storage limits)
  /// This is a simple approach - for production, consider using image package
  static Uint8List? compressIfNeeded(Uint8List imageBytes, {int maxSizeKB = 500}) {
    final sizeKB = imageBytes.length / 1024;
    if (sizeKB <= maxSizeKB) {
      return imageBytes;
    }
    // For now, return as is - in production, use image compression
    // The image package can be used for proper compression
    return imageBytes;
  }
}
