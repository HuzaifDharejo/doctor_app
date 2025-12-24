import 'package:flutter/material.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';

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
    // Use Navigator with a full-screen route for proper coverage
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TutorialOverlay(
            steps: steps,
            onComplete: onComplete,
            highlightColor: highlightColor,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  int _retryCount = 0;
  static const int _maxRetries = 5;

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
    
    // Schedule a check in case widgets aren't rendered yet
    _scheduleRetry();
  }
  
  void _scheduleRetry() {
    if (_retryCount < _maxRetries) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _retryCount++;
          setState(() {}); // Rebuild to check if target is now available
          if (_getTargetRect(widget.steps[_currentStep].targetKey) == null) {
            _scheduleRetry();
          }
        }
      });
    }
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
        if (!mounted) return;
        setState(() => _currentStep++);
        widget.steps[_currentStep].onComplete?.call();
        // Auto-scroll to make the target visible
        _scrollToTarget(widget.steps[_currentStep].targetKey);
        if (mounted) {
          _fadeController.forward();
        }
      });
    } else {
      widget.onComplete();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentStep--);
        // Auto-scroll to make the target visible
        _scrollToTarget(widget.steps[_currentStep].targetKey);
        if (mounted) {
          _fadeController.forward();
        }
      });
    }
  }
  
  void _scrollToTarget(GlobalKey targetKey) {
    // Wait a frame for state to update, then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = targetKey.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5, // Center the target in the viewport
        );
        // Rebuild after scroll to update spotlight position
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _skip() {
    widget.onComplete();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final targetBox = _getTargetRect(step.targetKey);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: _nextStep,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: screenSize.width,
            height: screenSize.height,
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Full screen overlay with spotlight hole
                Positioned(
                  top: -topPadding,
                  left: 0,
                  right: 0,
                  bottom: -bottomPadding,
                  child: CustomPaint(
                    size: Size(screenSize.width, screenSize.height + topPadding + bottomPadding),
                    painter: _OverlayPainter(
                      highlightArea: targetBox,
                      color: Colors.black.withValues(alpha: 0.8),
                      padding: widget.padding,
                      screenSize: Size(screenSize.width, screenSize.height + topPadding + bottomPadding),
                    ),
                  ),
                ),
                // Tutorial content
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: targetBox != null 
                        ? _buildTutorialContent(step, targetBox)
                        : _buildCenteredTutorialContent(step),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCenteredTutorialContent(TutorialStep step) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
          child: _buildTutorialCard(step),
        ),
      ),
    );
  }

  Widget _buildTutorialContent(TutorialStep step, Rect targetBox) {
    final size = MediaQuery.of(context).size;
    final viewPadding = MediaQuery.of(context).viewPadding;
    
    // Determine if target is in top half - if so, show card below; otherwise show card above
    final isTargetInTopHalf = targetBox.center.dy < size.height / 2;
    
    // Minimum safe margins from screen edges
    final minTopMargin = viewPadding.top + 16;
    final minBottomMargin = viewPadding.bottom + 16;
    const cardEstimatedHeight = 200.0;
    
    double? cardTop;
    double? cardBottom;
    
    if (isTargetInTopHalf) {
      // Target is in top half - place card BELOW the target
      cardTop = (targetBox.bottom + 24).clamp(minTopMargin, size.height - cardEstimatedHeight - minBottomMargin);
      cardBottom = null;
    } else {
      // Target is in bottom half - place card ABOVE the target
      cardTop = null;
      final spaceAboveTarget = targetBox.top - 24;
      cardBottom = (size.height - spaceAboveTarget).clamp(minBottomMargin, size.height - cardEstimatedHeight - minTopMargin);
    }

    return Stack(
      clipBehavior: Clip.none,
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
        // Floating tutorial card with safe positioning
        Positioned(
          left: 16,
          right: 16,
          top: cardTop,
          bottom: cardBottom,
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
    required this.screenSize,
    this.padding = 8.0,
  });

  final Rect? highlightArea;
  final Color color;
  final double padding;
  final Size screenSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    
    if (highlightArea == null) {
      // No highlight - just draw full overlay
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }
    
    // Create a path that covers the entire screen
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create a path for the spotlight hole
    final spotlightRect = highlightArea!.inflate(padding);
    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(spotlightRect, const Radius.circular(12)));
    
    // Subtract the spotlight from the full overlay using Path.combine
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      spotlightPath,
    );
    
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return highlightArea != oldDelegate.highlightArea ||
           color != oldDelegate.color ||
           padding != oldDelegate.padding;
  }
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

