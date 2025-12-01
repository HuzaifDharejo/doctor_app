import 'package:flutter/material.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';

/// Tutorial step definition
class TutorialStep {
  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.direction = TutorialDirection.bottom,
    this.icon,
    this.onComplete,
  });

  final String title;
  final String description;
  final GlobalKey targetKey;
  final TutorialDirection direction;
  final IconData? icon;
  final VoidCallback? onComplete;
}

enum TutorialDirection { top, bottom, left, right }

/// Interactive tutorial overlay
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    required this.steps,
    required this.onComplete,
    this.highlightColor = const Color(0xFF6366F1),
    this.padding = 8.0,
    super.key,
  });

  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final Color highlightColor;
  final double padding;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();

  static void show(
    BuildContext context,
    List<TutorialStep> steps, {
    required VoidCallback onComplete,
    Color highlightColor = const Color(0xFF6366F1),
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => TutorialOverlay(
        steps: steps,
        onComplete: onComplete,
        highlightColor: highlightColor,
      ),
    );
  }
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        widget.steps[_currentStep].onComplete?.call();
        _fadeController.forward();
      });
    } else {
      widget.onComplete();
      Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  void _skip() {
    widget.onComplete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final targetBox = _getTargetRect(step.targetKey);

    return GestureDetector(
      onTap: _nextStep,
      child: Stack(
        children: [
          // Overlay with spotlight
          if (targetBox != null)
            CustomPaint(
              painter: _OverlayPainter(
                highlightArea: targetBox,
                color: Colors.black54,
                padding: widget.padding,
              ),
              child: Container(),
            ),
          // Tutorial content
          if (targetBox != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildTutorialContent(step, targetBox),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorialContent(TutorialStep step, Rect targetBox) {
    final size = MediaQuery.of(context).size;
    final isTop = targetBox.top < size.height / 2;

    return Stack(
      children: [
        // Pulsing highlight around target
        Positioned(
          left: targetBox.left - 8,
          top: targetBox.top - 8,
          width: targetBox.width + 16,
          height: targetBox.height + 16,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.1)
                .animate(_pulseController),
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.highlightColor.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        // Floating tutorial card
        Positioned(
          left: 16,
          right: 16,
          top: isTop ? null : targetBox.bottom + 24,
          bottom: isTop ? size.height - targetBox.top + 24 : null,
          child: _buildTutorialCard(step),
        ),
      ],
    );
  }

  Widget _buildTutorialCard(TutorialStep step) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0)
          .animate(_fadeController),
      alignment: Alignment.center,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  if (step.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: widget.highlightColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        step.icon,
                        color: widget.highlightColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                step.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / widget.steps.length,
                  minHeight: 4,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.highlightColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    AppButton.tertiary(
                      label: '← Back',
                      onPressed: _previousStep,
                    ),
                  const Spacer(),
                  AppButton.tertiary(
                    label: 'Skip',
                    onPressed: _skip,
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: _currentStep == widget.steps.length - 1
                        ? 'Done'
                        : 'Next →',
                    onPressed: _nextStep,
                    backgroundColor: widget.highlightColor,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Step counter
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Step ${_currentStep + 1} of ${widget.steps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  RenderBox? _getTargetRenderBox(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
  }

  Rect? _getTargetRect(GlobalKey key) {
    final renderBox = _getTargetRenderBox(key);
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }
}

/// Paints the overlay with a spotlight effect
class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.highlightArea,
    required this.color,
    this.padding = 8.0,
  });

  final Rect highlightArea;
  final Color color;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color,
    );

    // Clear the highlighted area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightArea.inflate(padding),
        const Radius.circular(12),
      ),
      Paint()..blendMode = BlendMode.clear,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Provider for tutorial state
class TutorialManager {
  static final _instance = TutorialManager._();

  factory TutorialManager() => _instance;

  TutorialManager._();

  bool _tutorialCompleted = false;

  bool get isTutorialCompleted => _tutorialCompleted;

  void markTutorialComplete() {
    _tutorialCompleted = true;
  }

  void resetTutorial() {
    _tutorialCompleted = false;
  }
}

