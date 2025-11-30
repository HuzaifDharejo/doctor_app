import 'package:flutter/material.dart';

/// Floating help button that appears on screens
class HelpButton extends StatefulWidget {
  const HelpButton({
    required this.onPressed,
    this.tooltip = 'Show Help',
    this.position = const Alignment(0.95, 0.85),
    super.key,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Alignment position;

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 100,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.tooltip,
          child: FloatingActionButton.extended(
            onPressed: widget.onPressed,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text('Help'),
          ),
        ),
      ),
    );
  }
}

/// Info card to be shown inline on screens
class HelpCard extends StatelessWidget {
  const HelpCard({
    required this.title,
    required this.description,
    this.icon = Icons.info_outline_rounded,
    this.onDismiss,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.blue.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.blue.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Contextual tooltip that shows on tap
class ContextualHelp extends StatefulWidget {
  const ContextualHelp({
    required this.child,
    required this.helpText,
    this.helpTitle,
    this.icon,
    super.key,
  });

  final Widget child;
  final String helpText;
  final String? helpTitle;
  final IconData? icon;

  @override
  State<ContextualHelp> createState() => _ContextualHelpState();
}

class _ContextualHelpState extends State<ContextualHelp> {
  late OverlayEntry _overlayEntry;
  bool _isShowing = false;

  void _showHelp() {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: GestureDetector(
          onTap: _hideHelp,
          child: Material(
            color: Colors.black54,
            child: Center(
              child: ScaleTransition(
                scale: AlwaysStoppedAnimation<double>(1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 24,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              widget.helpTitle ?? 'Tip',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _hideHelp,
                            child: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.helpText,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _hideHelp,
                          child: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry);
  }

  void _hideHelp() {
    if (_isShowing) {
      _overlayEntry.remove();
      _isShowing = false;
    }
  }

  @override
  void dispose() {
    if (_isShowing) {
      _overlayEntry.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showHelp,
      child: Tooltip(
        message: widget.helpText,
        child: widget.child,
      ),
    );
  }
}
