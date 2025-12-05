/// App Lock Service for biometric/PIN authentication
/// 
/// Provides secure app access protection using:
/// - Biometric authentication (fingerprint, face ID)
/// - PIN code fallback
/// - Auto-lock on app background
import 'dart:convert';
import 'dart:ui' show AppLifecycleState;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Check if biometrics are supported on this platform
bool get _isBiometricsSupported => !kIsWeb;

/// Supported authentication methods
enum AuthMethod {
  none,
  biometric,
  pin,
  both, // Biometric with PIN fallback
}

/// App lock configuration
class AppLockSettings {
  const AppLockSettings({
    this.isEnabled = false,
    this.authMethod = AuthMethod.none,
    this.autoLockDelay = 0, // 0 = immediate, in seconds
    this.pinHash, // Hashed PIN for security
    this.lockOnBackground = true,
    this.requireAuthOnStart = true,
  });

  factory AppLockSettings.fromJson(Map<String, dynamic> json) {
    return AppLockSettings(
      isEnabled: (json['isEnabled'] as bool?) ?? false,
      authMethod: AuthMethod.values[(json['authMethod'] as int?) ?? 0],
      autoLockDelay: (json['autoLockDelay'] as int?) ?? 0,
      pinHash: json['pinHash'] as String?,
      lockOnBackground: (json['lockOnBackground'] as bool?) ?? true,
      requireAuthOnStart: (json['requireAuthOnStart'] as bool?) ?? true,
    );
  }

  final bool isEnabled;
  final AuthMethod authMethod;
  final int autoLockDelay; // Seconds before auto-lock
  final String? pinHash;
  final bool lockOnBackground;
  final bool requireAuthOnStart;

  AppLockSettings copyWith({
    bool? isEnabled,
    AuthMethod? authMethod,
    int? autoLockDelay,
    String? pinHash,
    bool? lockOnBackground,
    bool? requireAuthOnStart,
  }) {
    return AppLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      authMethod: authMethod ?? this.authMethod,
      autoLockDelay: autoLockDelay ?? this.autoLockDelay,
      pinHash: pinHash ?? this.pinHash,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      requireAuthOnStart: requireAuthOnStart ?? this.requireAuthOnStart,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'authMethod': authMethod.index,
    'autoLockDelay': autoLockDelay,
    'pinHash': pinHash,
    'lockOnBackground': lockOnBackground,
    'requireAuthOnStart': requireAuthOnStart,
  };
}

/// App Lock Service
class AppLockService extends ChangeNotifier {
  static const String _storageKey = 'app_lock_settings';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  AppLockSettings _settings = const AppLockSettings();
  bool _isLocked = true; // Start locked
  bool _isLoaded = false;
  DateTime? _lastActiveTime;
  List<BiometricType> _availableBiometrics = [];
  bool _canCheckBiometrics = false;

  AppLockSettings get settings => _settings;
  bool get isLocked => _isLocked && _settings.isEnabled;
  bool get isLoaded => _isLoaded;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get canUseBiometrics => _canCheckBiometrics && _availableBiometrics.isNotEmpty;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
    await _checkBiometricCapabilities();
    
    // If app lock is enabled, start locked
    if (_settings.isEnabled && _settings.requireAuthOnStart) {
      _isLocked = true;
    } else {
      _isLocked = false;
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  /// Check device biometric capabilities
  Future<void> _checkBiometricCapabilities() async {
    // Biometrics not supported on web platform
    if (!_isBiometricsSupported) {
      _canCheckBiometrics = false;
      _availableBiometrics = [];
      return;
    }
    
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (_canCheckBiometrics) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      _canCheckBiometrics = false;
      _availableBiometrics = [];
    } on MissingPluginException catch (e) {
      // Plugin not available on this platform (e.g., web)
      debugPrint('Biometrics not supported on this platform: $e');
      _canCheckBiometrics = false;
      _availableBiometrics = [];
    } catch (e) {
      // Catch any other errors
      debugPrint('Unexpected error checking biometrics: $e');
      _canCheckBiometrics = false;
      _availableBiometrics = [];
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          const JsonDecoder().convert(jsonString) as Map,
        );
        _settings = AppLockSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading app lock settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = const JsonEncoder().convert(_settings.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving app lock settings: $e');
    }
  }

  /// Enable app lock with specified method
  Future<bool> enableAppLock({
    required AuthMethod method,
    String? pin,
    int autoLockDelay = 0,
    bool lockOnBackground = true,
  }) async {
    // Validate PIN if required
    if ((method == AuthMethod.pin || method == AuthMethod.both) && 
        (pin == null || pin.length < 4)) {
      return false;
    }

    // Verify biometric availability if required
    if ((method == AuthMethod.biometric || method == AuthMethod.both) && 
        !canUseBiometrics) {
      return false;
    }

    _settings = _settings.copyWith(
      isEnabled: true,
      authMethod: method,
      autoLockDelay: autoLockDelay,
      pinHash: pin != null ? _hashPin(pin) : _settings.pinHash,
      lockOnBackground: lockOnBackground,
      requireAuthOnStart: true,
    );

    await _saveSettings();
    _isLocked = false; // Unlock after enabling (user just authenticated)
    notifyListeners();
    return true;
  }

  /// Disable app lock
  Future<void> disableAppLock() async {
    _settings = const AppLockSettings();
    _isLocked = false;
    await _saveSettings();
    notifyListeners();
  }

  /// Update PIN
  Future<bool> updatePin(String newPin) async {
    if (newPin.length < 4) return false;
    
    _settings = _settings.copyWith(
      pinHash: _hashPin(newPin),
    );
    await _saveSettings();
    notifyListeners();
    return true;
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    // Biometrics not supported on web platform
    if (!_isBiometricsSupported || !canUseBiometrics) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Doctor App',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _unlock();
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('Biometrics not supported on this platform: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected biometric auth error: $e');
      return false;
    }
  }

  /// Authenticate with PIN
  bool authenticateWithPin(String pin) {
    if (_settings.pinHash == null) return false;
    
    final inputHash = _hashPin(pin);
    final authenticated = inputHash == _settings.pinHash;
    
    if (authenticated) {
      _unlock();
    }
    return authenticated;
  }

  /// Authenticate (tries biometric first, then PIN)
  Future<bool> authenticate({String? pin}) async {
    if (!_settings.isEnabled) {
      _unlock();
      return true;
    }

    switch (_settings.authMethod) {
      case AuthMethod.none:
        _unlock();
        return true;
        
      case AuthMethod.biometric:
        return await authenticateWithBiometrics();
        
      case AuthMethod.pin:
        if (pin != null) {
          return authenticateWithPin(pin);
        }
        return false;
        
      case AuthMethod.both:
        // Try biometric first
        final biometricResult = await authenticateWithBiometrics();
        if (biometricResult) return true;
        
        // Fall back to PIN
        if (pin != null) {
          return authenticateWithPin(pin);
        }
        return false;
    }
  }

  /// Lock the app
  void lock() {
    if (_settings.isEnabled) {
      _isLocked = true;
      _lastActiveTime = DateTime.now();
      notifyListeners();
    }
  }

  /// Unlock the app
  void _unlock() {
    _isLocked = false;
    _lastActiveTime = DateTime.now();
    notifyListeners();
  }

  /// Handle app lifecycle changes
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (!_settings.isEnabled) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (_settings.lockOnBackground) {
          _lastActiveTime = DateTime.now();
        }
        break;
        
      case AppLifecycleState.resumed:
        if (_settings.lockOnBackground && _lastActiveTime != null) {
          final elapsed = DateTime.now().difference(_lastActiveTime!).inSeconds;
          if (elapsed >= _settings.autoLockDelay) {
            lock();
          }
        }
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated
        break;
    }
  }

  /// Simple hash function for PIN (in production, use a proper crypto library)
  String _hashPin(String pin) {
    // Simple hash - in production use bcrypt or similar
    var hash = 0;
    for (var i = 0; i < pin.length; i++) {
      hash = ((hash << 5) - hash) + pin.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return hash.toRadixString(16);
  }

  /// Get biometric type description
  String getBiometricDescription() {
    if (_availableBiometrics.isEmpty) return 'Not available';
    
    final types = <String>[];
    if (_availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Fingerprint');
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }
    if (_availableBiometrics.contains(BiometricType.strong)) {
      types.add('Biometric');
    }
    if (_availableBiometrics.contains(BiometricType.weak)) {
      types.add('Device Lock');
    }
    
    return types.join(', ');
  }
}