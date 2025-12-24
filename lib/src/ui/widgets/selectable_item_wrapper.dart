import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Wrapper widget that makes any widget selectable
/// Used for batch operations mode
class SelectableItemWrapper<T> extends StatelessWidget {
  const SelectableItemWrapper({
    super.key,
    required this.item,
    required this.child,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSelectionMode = false,
  });

  final T item;
  final Widget child;
  final bool isSelected;
  final Function(T item, bool selected) onSelectionChanged;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    if (!isSelectionMode) {
      return child;
    }

    return InkWell(
      onTap: () => onSelectionChanged(item, !isSelected),
      child: Stack(
        children: [
          child,
          // Selection overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Selection checkbox
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}


