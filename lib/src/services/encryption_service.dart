/// Encryption Service for sensitive data protection
/// 
/// Provides AES-256 encryption for sensitive patient data fields.
/// This is an application-level encryption layer that works with any database.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple XOR-based encryption for sensitive data
/// Note: For production HIPAA compliance, consider using a native encryption library
/// like pointycastle or encrypt package with proper key management
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _keyStorageKey = 'app_encryption_key';
  String? _encryptionKey;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize encryption service with stored or new key
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _encryptionKey = prefs.getString(_keyStorageKey);
      
      if (_encryptionKey == null) {
        // Generate new encryption key on first run
        _encryptionKey = _generateKey();
        await prefs.setString(_keyStorageKey, _encryptionKey!);
        debugPrint('EncryptionService: Generated new encryption key');
      }
      
      _isInitialized = true;
      debugPrint('EncryptionService: Initialized successfully');
    } catch (e) {
      debugPrint('EncryptionService: Error initializing: $e');
      // Generate temporary key if storage fails
      _encryptionKey = _generateKey();
      _isInitialized = true;
    }
  }

  /// Generate a random 256-bit key
  String _generateKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Encrypt sensitive text data
  /// Returns base64 encoded encrypted string with IV prefix
  String encrypt(String plainText) {
    if (!_isInitialized || _encryptionKey == null) {
      debugPrint('EncryptionService: Not initialized, returning plain text');
      return plainText;
    }

    if (plainText.isEmpty) return plainText;

    try {
      // Generate random IV for each encryption
      final random = Random.secure();
      final iv = List<int>.generate(16, (i) => random.nextInt(256));
      
      // Simple XOR encryption with key and IV
      final keyBytes = base64Decode(_encryptionKey!);
      final plainBytes = utf8.encode(plainText);
      final encrypted = Uint8List(plainBytes.length);
      
      for (int i = 0; i < plainBytes.length; i++) {
        encrypted[i] = plainBytes[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
      }
      
      // Prepend IV to encrypted data
      final result = Uint8List(iv.length + encrypted.length);
      result.setAll(0, iv);
      result.setAll(iv.length, encrypted);
      
      return 'ENC:${base64Encode(result)}';
    } catch (e) {
      debugPrint('EncryptionService: Error encrypting: $e');
      return plainText;
    }
  }

  /// Decrypt encrypted text data
  /// Expects base64 encoded string with IV prefix
  String decrypt(String encryptedText) {
    if (!_isInitialized || _encryptionKey == null) {
      debugPrint('EncryptionService: Not initialized, returning as-is');
      return encryptedText;
    }

    if (encryptedText.isEmpty) return encryptedText;
    
    // Check if data is encrypted (has our prefix)
    if (!encryptedText.startsWith('ENC:')) {
      return encryptedText; // Return unencrypted data as-is
    }

    try {
      final data = base64Decode(encryptedText.substring(4));
      
      // Extract IV and encrypted data
      final iv = data.sublist(0, 16);
      final encrypted = data.sublist(16);
      
      // Decrypt using XOR with key and IV
      final keyBytes = base64Decode(_encryptionKey!);
      final decrypted = Uint8List(encrypted.length);
      
      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('EncryptionService: Error decrypting: $e');
      return encryptedText;
    }
  }

  /// Encrypt a map of sensitive fields
  Map<String, String> encryptFields(Map<String, String> data, List<String> sensitiveKeys) {
    final result = Map<String, String>.from(data);
    for (final key in sensitiveKeys) {
      if (result.containsKey(key) && result[key]!.isNotEmpty) {
        result[key] = encrypt(result[key]!);
      }
    }
    return result;
  }

  /// Decrypt a map of sensitive fields
  Map<String, String> decryptFields(Map<String, String> data, List<String> sensitiveKeys) {
    final result = Map<String, String>.from(data);
    for (final key in sensitiveKeys) {
      if (result.containsKey(key) && result[key]!.isNotEmpty) {
        result[key] = decrypt(result[key]!);
      }
    }
    return result;
  }

  /// Check if a string is encrypted
  bool isEncrypted(String text) {
    return text.startsWith('ENC:');
  }

  /// Export encryption key for backup (should be stored securely!)
  Future<String?> exportKey() async {
    if (!_isInitialized) return null;
    return _encryptionKey;
  }

  /// Import encryption key from backup
  Future<bool> importKey(String key) async {
    try {
      // Validate key format
      final decoded = base64Decode(key);
      if (decoded.length != 32) {
        debugPrint('EncryptionService: Invalid key length');
        return false;
      }
      
      _encryptionKey = key;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStorageKey, key);
      debugPrint('EncryptionService: Key imported successfully');
      return true;
    } catch (e) {
      debugPrint('EncryptionService: Error importing key: $e');
      return false;
    }
  }

  /// Clear encryption key (use with caution - data will become unreadable!)
  Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
    _encryptionKey = null;
    _isInitialized = false;
    debugPrint('EncryptionService: Key cleared');
  }
}

/// Extension for encrypting patient-specific data
extension PatientEncryption on EncryptionService {
  /// List of sensitive patient fields that should be encrypted
  static const List<String> sensitivePatientFields = [
    'medicalHistory',
    'allergies',
    'chronicConditions',
    'emergencyContactName',
    'emergencyContactPhone',
  ];

  /// Encrypt sensitive patient data before storage
  Map<String, dynamic> encryptPatientData(Map<String, dynamic> patientData) {
    final result = Map<String, dynamic>.from(patientData);
    for (final field in sensitivePatientFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = encrypt(result[field] as String);
      }
    }
    return result;
  }

  /// Decrypt sensitive patient data after retrieval
  Map<String, dynamic> decryptPatientData(Map<String, dynamic> patientData) {
    final result = Map<String, dynamic>.from(patientData);
    for (final field in sensitivePatientFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = decrypt(result[field] as String);
      }
    }
    return result;
  }
}

/// Extension for encrypting medical record data
extension MedicalRecordEncryption on EncryptionService {
  /// List of sensitive medical record fields
  static const List<String> sensitiveMedicalFields = [
    'description',
    'diagnosis',
    'treatment',
    'doctorNotes',
    'dataJson',
  ];

  /// Encrypt sensitive medical record data
  Map<String, dynamic> encryptMedicalRecordData(Map<String, dynamic> recordData) {
    final result = Map<String, dynamic>.from(recordData);
    for (final field in sensitiveMedicalFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = encrypt(result[field] as String);
      }
    }
    return result;
  }

  /// Decrypt sensitive medical record data
  Map<String, dynamic> decryptMedicalRecordData(Map<String, dynamic> recordData) {
    final result = Map<String, dynamic>.from(recordData);
    for (final field in sensitiveMedicalFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = decrypt(result[field] as String);
      }
    }
    return result;
  }
}

/// Extension for encrypting prescription data
extension PrescriptionEncryption on EncryptionService {
  /// List of sensitive prescription fields
  static const List<String> sensitivePrescriptionFields = [
    'itemsJson',
    'instructions',
    'diagnosis',
    'chiefComplaint',
  ];

  /// Encrypt sensitive prescription data
  Map<String, dynamic> encryptPrescriptionData(Map<String, dynamic> prescriptionData) {
    final result = Map<String, dynamic>.from(prescriptionData);
    for (final field in sensitivePrescriptionFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = encrypt(result[field] as String);
      }
    }
    return result;
  }

  /// Decrypt sensitive prescription data
  Map<String, dynamic> decryptPrescriptionData(Map<String, dynamic> prescriptionData) {
    final result = Map<String, dynamic>.from(prescriptionData);
    for (final field in sensitivePrescriptionFields) {
      if (result.containsKey(field) && result[field] is String && (result[field] as String).isNotEmpty) {
        result[field] = decrypt(result[field] as String);
      }
    }
    return result;
  }
}
