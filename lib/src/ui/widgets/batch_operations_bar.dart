import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Batch operations bar that appears when items are selected
/// Shows selected count and action buttons
class BatchOperationsBar<T> extends StatelessWidget {
  const BatchOperationsBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.actions,
    this.onSelectAll,
    this.onDeselectAll,
    this.showSelectAll = true,
  });

  final int selectedCount;
  final int totalCount;
  final List<BatchAction<T>> actions;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final bool showSelectAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSelected = selectedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection info
            Text(
              '$selectedCount selected',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // Select/Deselect All button
            if (showSelectAll)
              TextButton(
                onPressed: allSelected ? onDeselectAll : onSelectAll,
                child: Text(allSelected ? 'Deselect All' : 'Select All'),
              ),
            
            const Spacer(),
            
            // Action buttons
            ...actions.take(3).map((action) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: _buildActionButton(context, action, isDark),
            )),
            
            // More actions menu if there are more than 3
            if (actions.length > 3)
              PopupMenuButton<BatchAction<T>>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => action.onAction?.call(),
                itemBuilder: (context) => actions.skip(3).map((action) => PopupMenuItem(
                  value: action,
                  child: Row(
                    children: [
                      Icon(action.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(action.label),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, BatchAction<T> action, bool isDark) {
    if (action.isDestructive) {
      return OutlinedButton.icon(
        onPressed: action.onAction,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error),
        ),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: action.onAction,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Represents a batch action
class BatchAction<T> {
  const BatchAction({
    required this.label,
    required this.icon,
    this.onAction,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onAction;
  final bool isDestructive;
}


