/// Lock Screen Widget
/// 
/// Displays when app is locked, providing:
/// - Biometric authentication button
/// - PIN entry keypad
/// - Smooth animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.appLockService,
    required this.onUnlocked,
  });

  final AppLockService appLockService;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final List<String> _pinDigits = [];
  bool _isAuthenticating = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Try biometric auth on start if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.appLockService.settings.authMethod == AuthMethod.biometric ||
          widget.appLockService.settings.authMethod == AuthMethod.both) {
        _authenticateWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.appLockService.authenticateWithBiometrics();
      if (success) {
        widget.onUnlocked();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    
    if (_pinDigits.length >= 6) return;
    
    setState(() {
      _pinDigits.add(digit);
      _errorMessage = null;
    });

    // Auto-submit when PIN is complete (4-6 digits)
    if (_pinDigits.length >= 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    HapticFeedback.lightImpact();
    
    if (_pinDigits.isEmpty) return;
    
    setState(() {
      _pinDigits.removeLast();
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final pin = _pinDigits.join();
    final success = widget.appLockService.authenticateWithPin(pin);
    
    if (success) {
      widget.onUnlocked();
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _pinDigits.clear();
        _errorMessage = 'Incorrect PIN';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.appLockService.settings;
    final showPinPad = settings.authMethod == AuthMethod.pin || 
                       settings.authMethod == AuthMethod.both;
    final showBiometric = (settings.authMethod == AuthMethod.biometric || 
                          settings.authMethod == AuthMethod.both) &&
                          widget.appLockService.canUseBiometrics;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // App Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Doctor App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Enter PIN to unlock',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // PIN Dots
              if (showPinPad) ...[
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value * 
                            ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pinDigits.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: isFilled ? 16 : 14,
                        height: isFilled ? 16 : 14,
                        decoration: BoxDecoration(
                          color: isFilled 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: isFilled 
                              ? null 
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                        ),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Error Message
                AnimatedOpacity(
                  opacity: _errorMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _errorMessage ?? '',
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Biometric Button
              if (showBiometric) ...[
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: _isAuthenticating
                        ? SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          )
                        : Icon(
                            _getBiometricIcon(),
                            size: 32,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  widget.appLockService.getBiometricDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
              
              // PIN Keypad
              if (showPinPad) _buildKeypad(isDark),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    final biometrics = widget.appLockService.availableBiometrics;
    if (biometrics.contains(BiometricType.face)) {
      return Icons.face_rounded;
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint_rounded;
    }
    return Icons.lock_open_rounded;
  }

  Widget _buildKeypad(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildKeypadRow(['', '0', 'backspace']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        
        if (key == 'backspace') {
          return _buildKeypadButton(
            onTap: _onBackspacePressed,
            child: Icon(
              Icons.backspace_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
          );
        }
        
        return _buildKeypadButton(
          onTap: () => _onDigitPressed(key),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
