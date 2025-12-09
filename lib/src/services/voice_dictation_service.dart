import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart' show SpeechListenOptions;

/// Service for voice-to-text dictation
/// 
/// Enables doctors to dictate notes hands-free during patient exams.
/// Supports continuous listening for longer dictation sessions.
/// 
/// Usage:
/// ```dart
/// final service = VoiceDictationService();
/// await service.initialize();
/// 
/// service.startListening(
///   onResult: (text) => print('Transcribed: $text'),
///   onError: (error) => print('Error: $error'),
/// );
/// ```
class VoiceDictationService {
  VoiceDictationService();

  final SpeechToText _speechToText = SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocaleId = 'en_US';
  
  // Callbacks
  void Function(String text)? _onResult;
  void Function(String error)? _onError;
  void Function(bool isListening)? _onStatusChange;

  /// Whether voice dictation is available on this device
  bool get isAvailable => _isInitialized;
  
  /// Whether currently listening for speech
  bool get isListening => _isListening;
  
  /// The last transcribed words
  String get lastWords => _lastWords;
  
  /// Current locale being used
  String get currentLocale => _currentLocaleId;

  /// Initialize the speech recognition service
  /// 
  /// Must be called before using any other methods.
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Web platform doesn't support speech_to_text well
    if (kIsWeb) {
      debugPrint('VoiceDictationService: Speech recognition not fully supported on web');
      return false;
    }
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('VoiceDictationService error: ${error.errorMsg}');
          _onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('VoiceDictationService status: $status');
          _isListening = status == 'listening';
          _onStatusChange?.call(_isListening);
        },
        debugLogging: false,
      );
      
      if (_isInitialized) {
        // Get available locales and prefer English
        final locales = await _speechToText.locales();
        final englishLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('en'),
          orElse: () => locales.isNotEmpty ? locales.first : LocaleName('en_US', 'English'),
        );
        _currentLocaleId = englishLocale.localeId;
        debugPrint('VoiceDictationService: Initialized with locale $_currentLocaleId');
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('VoiceDictationService: Failed to initialize: $e');
      return false;
    }
  }

  /// Start listening for speech
  /// 
  /// [onResult] - Called with transcribed text (called multiple times as speech is recognized)
  /// [onError] - Called when an error occurs
  /// [onStatusChange] - Called when listening status changes
  /// [continuous] - If true, keeps listening after pauses (for longer dictation)
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(String error)? onError,
    void Function(bool isListening)? onStatusChange,
    bool continuous = true,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onError?.call('Speech recognition not available on this device');
        return;
      }
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    _onResult = onResult;
    _onError = onError;
    _onStatusChange = onStatusChange;
    _lastWords = '';
    
    try {
      await _speechToText.listen(
        onResult: _handleResult,
        listenFor: continuous ? const Duration(minutes: 5) : const Duration(seconds: 30),
        pauseFor: continuous ? const Duration(seconds: 5) : const Duration(seconds: 3),
        localeId: _currentLocaleId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: continuous ? ListenMode.dictation : ListenMode.confirmation,
        ),
      );
      
      _isListening = true;
      _onStatusChange?.call(true);
    } catch (e) {
      debugPrint('VoiceDictationService: Failed to start listening: $e');
      _onError?.call('Failed to start speech recognition');
    }
  }

  /// Handle speech recognition results
  void _handleResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    
    if (result.finalResult) {
      // Final result - add to text
      _onResult?.call(_lastWords);
    } else {
      // Partial result - update in real-time
      _onResult?.call(_lastWords);
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
      _isListening = false;
      _onStatusChange?.call(false);
    } catch (e) {
      debugPrint('VoiceDictationService: Failed to stop listening: $e');
    }
  }

  /// Cancel speech recognition without processing
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      _onStatusChange?.call(false);
    } catch (e) {
      debugPrint('VoiceDictationService: Failed to cancel: $e');
    }
  }

  /// Get list of available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Set the locale for speech recognition
  Future<void> setLocale(String localeId) async {
    _currentLocaleId = localeId;
    if (_isListening) {
      await stopListening();
      // Restart with new locale if was listening
      if (_onResult != null) {
        await startListening(
          onResult: _onResult!,
          onError: _onError,
          onStatusChange: _onStatusChange,
        );
      }
    }
  }

  /// Check if speech recognition has required permissions
  Future<bool> hasPermission() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _speechToText.hasPermission;
  }

  /// Dispose of resources
  void dispose() {
    stopListening();
    _onResult = null;
    _onError = null;
    _onStatusChange = null;
  }
}

/// Voice dictation state for UI
enum VoiceDictationState {
  /// Not initialized or unavailable
  unavailable,
  /// Ready to start listening
  ready,
  /// Currently listening for speech
  listening,
  /// Processing speech
  processing,
  /// Error occurred
  error,
}
