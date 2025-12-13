import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/voice_dictation_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// A button that enables voice-to-text dictation
/// 
/// Can be used as a suffix icon in text fields or as a standalone button.
/// Shows visual feedback while listening and displays transcribed text.
/// 
/// Example usage in a TextField:
/// ```dart
/// TextField(
///   controller: _controller,
///   decoration: InputDecoration(
///     suffixIcon: VoiceDictationButton(
///       onTextReceived: (text) {
///         _controller.text += text;
///       },
///     ),
///   ),
/// )
/// ```
class VoiceDictationButton extends StatefulWidget {
  const VoiceDictationButton({
    super.key,
    required this.onTextReceived,
    this.appendText = true,
    this.iconSize = 24,
    this.showTooltip = true,
    this.activeColor,
    this.inactiveColor,
  });

  /// Called when speech is transcribed to text
  final void Function(String text) onTextReceived;
  
  /// If true, appends text with a space. If false, replaces entirely.
  final bool appendText;
  
  /// Size of the microphone icon
  final double iconSize;
  
  /// Whether to show tooltip on hover
  final bool showTooltip;
  
  /// Color when actively listening
  final Color? activeColor;
  
  /// Color when not listening
  final Color? inactiveColor;

  @override
  State<VoiceDictationButton> createState() => _VoiceDictationButtonState();
}

class _VoiceDictationButtonState extends State<VoiceDictationButton>
    with SingleTickerProviderStateMixin {
  final _dictationService = VoiceDictationService();
  bool _isListening = false;
  bool _isAvailable = false;
  String _currentText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDictation();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed && _isListening) {
        _pulseController.forward();
      }
    });
  }

  Future<void> _initializeDictation() async {
    final available = await _dictationService.initialize();
    if (mounted) {
      setState(() => _isAvailable = available);
    }
  }

  @override
  void dispose() {
    _dictationService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _currentText = '';
    });
    _pulseController.forward();
    
    await _dictationService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() => _currentText = text);
        }
      },
      onError: (error) {
        if (mounted) {
          _showError(error);
          _stopListening();
        }
      },
      onStatusChange: (isListening) {
        // Status change is handled in _stopListening
        // Don't send text here to avoid race condition
        debugPrint('VoiceDictation status: $isListening, text: $_currentText');
      },
    );
  }

  Future<void> _stopListening() async {
    // Capture the current text before stopping
    final textToSend = _currentText;
    
    await _dictationService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    
    // Send the captured text if not empty
    if (textToSend.isNotEmpty) {
      final finalText = widget.appendText ? '$textToSend ' : textToSend;
      widget.onTextReceived(finalText);
    }
    
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentText = '';
      });
    }
  }

  void _sendText() {
    if (_currentText.isEmpty) return;
    
    final textToSend = widget.appendText ? '$_currentText ' : _currentText;
    widget.onTextReceived(textToSend);
    // Don't clear _currentText here, let the caller handle it
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ?? AppColors.error;
    final inactiveColor = widget.inactiveColor ?? 
        (isDark ? Colors.white70 : Colors.grey.shade600);

    final button = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: IconButton(
            onPressed: _toggleListening,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: widget.iconSize,
              color: _isListening ? activeColor : inactiveColor,
            ),
            tooltip: widget.showTooltip 
                ? (_isListening ? 'Stop dictation' : 'Start voice dictation')
                : null,
          ),
        );
      },
    );

    if (_isListening && _currentText.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentText,
                style: TextStyle(
                  fontSize: 12,
                  color: activeColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          button,
        ],
      );
    }

    return button;
  }
}

/// A text field with integrated voice dictation support
/// 
/// Provides a convenient wrapper around TextField with a built-in
/// voice dictation button that automatically appends transcribed text.
class VoiceTextField extends StatefulWidget {
  const VoiceTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.focusNode,
    this.style,
    this.decoration,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final TextStyle? style;
  final InputDecoration? decoration;

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  late TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _appendVoiceText(String text) {
    final currentText = _controller.text;
    final selection = _controller.selection;
    
    // Insert at cursor position or append at end
    if (selection.isValid && selection.baseOffset >= 0) {
      final before = currentText.substring(0, selection.baseOffset);
      final after = currentText.substring(selection.extentOffset);
      _controller.text = '$before$text$after';
      _controller.selection = TextSelection.collapsed(
        offset: selection.baseOffset + text.length,
      );
    } else {
      // Append at end with space if needed
      if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
        _controller.text = '$currentText $text';
      } else {
        _controller.text = '$currentText$text';
      }
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultDecoration = InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.enabled && !widget.readOnly
          ? VoiceDictationButton(
              onTextReceived: _appendVoiceText,
              iconSize: 22,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
    );

    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration?.copyWith(
        suffixIcon: widget.enabled && !widget.readOnly
            ? VoiceDictationButton(
                onTextReceived: _appendVoiceText,
                iconSize: 22,
              )
            : widget.decoration?.suffixIcon,
      ) ?? defaultDecoration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      style: widget.style,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}
