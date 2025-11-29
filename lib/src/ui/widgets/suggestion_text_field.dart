import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A text field that shows suggestion chips when focused (inline below the field)
class SuggestionTextField extends StatefulWidget {

  const SuggestionTextField({
    required this.controller, required this.label, required this.suggestions, super.key,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.appendMode = true,
    this.separator = ', ',
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final List<String> suggestions;
  final int maxLines;
  final bool appendMode; // If true, appends to existing text with separator
  final String separator;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _keepOpen = false; // Keeps suggestions open during chip tap

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Delay closing to allow chip tap to register
    if (!_focusNode.hasFocus && !_keepOpen) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus && !_keepOpen) {
          setState(() {
            _isFocused = false;
          });
        }
      });
    } else {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onSuggestionTap(String suggestion) {
    _keepOpen = true;
    if (widget.appendMode) {
      final current = widget.controller.text;
      if (current.isEmpty) {
        widget.controller.text = suggestion;
      } else if (!current.contains(suggestion)) {
        widget.controller.text = '$current${widget.separator}$suggestion';
      }
    } else {
      widget.controller.text = suggestion;
    }
    // Re-focus the text field
    _focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      _keepOpen = false;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            suffixIcon: widget.suggestions.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      if (!_isFocused) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: _isFocused ? AppColors.warning : (isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        // Suggestions appear when focused
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isFocused
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        ...widget.suggestions.map((suggestion) {
                          final isSelected = widget.controller.text.contains(suggestion);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onSuggestionTap(suggestion),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBackground : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A compact version for vital signs with unit toggle
class VitalTextField extends StatefulWidget {

  const VitalTextField({
    required this.controller, required this.label, required this.unit, required this.icon, required this.suggestions, super.key,
    this.showUnitToggle = false,
    this.alternateUnit,
    this.alternateSuggestions,
    this.onUnitChanged,
    this.isAlternateUnit = false,
  });
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final List<String> suggestions;
  final bool showUnitToggle;
  final String? alternateUnit;
  final List<String>? alternateSuggestions;
  final ValueChanged<bool>? onUnitChanged;
  final bool isAlternateUnit;

  @override
  State<VitalTextField> createState() => _VitalTextFieldState();
}

class _VitalTextFieldState extends State<VitalTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  // ignore: unused_field
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<String> get _currentSuggestions {
    if (widget.isAlternateUnit && widget.alternateSuggestions != null) {
      return widget.alternateSuggestions!;
    }
    return widget.suggestions;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkDivider
                      : AppColors.divider,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _currentSuggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onPressed: () {
                          widget.controller.text = suggestion;
                          _focusNode.requestFocus();
                          _showOverlay();
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUnit = widget.isAlternateUnit ? widget.alternateUnit : widget.unit;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.label,
                suffixText: currentUnit,
                prefixIcon: Icon(widget.icon, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                isDense: true,
              ),
            ),
          ),
          if (widget.showUnitToggle && widget.alternateUnit != null) ...[
            const SizedBox(width: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnitButton(widget.unit, !widget.isAlternateUnit),
                  _buildUnitButton(widget.alternateUnit!, widget.isAlternateUnit),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (widget.onUnitChanged != null) {
          widget.onUnitChanged!(unit == widget.alternateUnit);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Shows a bottom sheet with suggestions when tapped
void showSuggestionBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> suggestions,
  required TextEditingController controller,
  bool appendMode = true,
  String separator = ', ',
  String? newLineSeparator,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Suggestions
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((suggestion) {
                  final isSelected = controller.text.contains(suggestion);
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      if (appendMode) {
                        final current = controller.text;
                        final sep = newLineSeparator ?? separator;
                        if (current.isEmpty) {
                          controller.text = suggestion;
                        } else if (!current.contains(suggestion)) {
                          controller.text = '$current$sep$suggestion';
                        }
                      } else {
                        controller.text = suggestion;
                        Navigator.pop(context);
                      }
                    },
                    backgroundColor: isSelected 
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : null,
                    side: BorderSide(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isDark ? AppColors.darkDivider : AppColors.divider),
                    ),
                    avatar: isSelected 
                        ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                        : null,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
