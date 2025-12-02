/// App search bar widget with consistent styling
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../extensions/context_extensions.dart';
import '../theme/design_tokens.dart';

class AppSearchBar extends StatelessWidget {

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.value,
    this.onChanged,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });
  final TextEditingController? controller;
  final String? hintText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isCompact = context.isCompact;
    
    // Use value to create an internal controller if no controller provided
    final effectiveController = controller ?? 
        (value != null ? (TextEditingController(text: value)..selection = TextSelection.fromPosition(
            TextPosition(offset: value!.length),)) : null);
    
    // Show clear button if there's text and onClear is provided
    final showClear = (value?.isNotEmpty ?? effectiveController?.text.isNotEmpty ?? false) && onClear != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
        boxShadow: AppShadow.small,
      ),
      child: TextField(
        controller: effectiveController,
        focusNode: focusNode,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: isCompact ? AppFontSize.md : AppFontSize.lg),
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          hintStyle: TextStyle(
            fontSize: isCompact ? AppFontSize.md : AppFontSize.lg,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
          ),
          prefixIcon: prefix ?? Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
            size: isCompact ? AppIconSize.smCompact : AppIconSize.md,
          ),
          suffixIcon: showClear 
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    size: isCompact ? AppIconSize.smCompact : AppIconSize.md,
                  ),
                  onPressed: onClear,
                )
              : suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: isCompact ? AppSpacing.md : AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}

/// Animated search bar that expands/collapses
class ExpandableSearchBar extends StatefulWidget {

  const ExpandableSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.initiallyExpanded = false,
  });
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool initiallyExpanded;

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _textController = widget.controller ?? TextEditingController();
    _controller = AnimationController(
      duration: AppDuration.normal,
      vsync: this,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    if (widget.controller == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        _focusNode.requestFocus();
      } else {
        _controller.reverse();
        _textController.clear();
        widget.onClear?.call();
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded ? 200 + (100 * _widthAnimation.value) : 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(
              _isExpanded ? AppRadius.md : AppRadius.full,
            ),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.close : Icons.search,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                onPressed: _toggle,
              ),
              if (_isExpanded)
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Search...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(right: AppSpacing.lg),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
