/// Lab Test Card Components
/// 
/// Card widgets for displaying lab orders, results, and panels
/// with consistent styling and actions.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'lab_models.dart';
import 'lab_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Full lab order card with all details and actions
class LabOrderCard extends StatelessWidget {
  const LabOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onStatusUpdate,
    this.onCancel,
    this.onEnterResults,
    this.showActions = true,
  });

  final LabTestData order;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;
  final VoidCallback? onCancel;
  final VoidCallback? onEnterResults;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = LabColors.getStatusColor(order.status.value);
    final urgencyColor = LabColors.getPriorityColor(order.priority.value);
    final hasAbnormal = order.isAbnormal || order.isCritical;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: LabContainerStyle.card(isDark: isDark, hasAbnormal: hasAbnormal),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.2),
                            statusColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: LabTestIcon(
                        testName: order.name,
                        size: 24,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark 
                                        ? LabColors.darkTextPrimary 
                                        : LabColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (hasAbnormal)
                                AbnormalBadge(isCritical: order.isCritical),
                            ],
                          ),
                          if (order.testCode != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Code: ${order.testCode}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? LabColors.darkTextSecondary 
                                      : LabColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    LabStatusTag(status: order.status.value),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Info chips row
                Row(
                  children: [
                    LabPriorityTag(priority: order.priority.value, compact: true),
                    const SizedBox(width: 8),
                    if (order.labName != null)
                      Flexible(
                        child: _InfoChip(
                          icon: Icons.business_rounded,
                          label: order.labName!,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (order.orderDate != null)
                      _DateChip(date: order.orderDate!, isDark: isDark),
                  ],
                ),
                
                // Results summary if completed
                if (order.status == LabOrderStatus.completed && order.result != null) ...[
                  const SizedBox(height: 14),
                  _ResultsSummary(
                    result: order.result!,
                    isAbnormal: hasAbnormal,
                    isDark: isDark,
                  ),
                ],
                
                // Action buttons
                if (showActions && _canShowActions) ...[
                  const SizedBox(height: 14),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  bool get _canShowActions {
    return order.status == LabOrderStatus.ordered || 
           order.status == LabOrderStatus.collected ||
           order.status == LabOrderStatus.inProgress;
  }
  
  Widget _buildActions(BuildContext context) {
    if (order.status == LabOrderStatus.inProgress) {
      return LabGradientButton(
        onPressed: onEnterResults,
        label: 'Enter Results',
        icon: Icons.add_chart_rounded,
      );
    }
    
    return Row(
      children: [
        if (onCancel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LabColors.cancelled,
                side: const BorderSide(color: LabColors.cancelled),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (onCancel != null && onStatusUpdate != null)
          const SizedBox(width: 12),
        if (onStatusUpdate != null)
          Expanded(
            child: LabGradientButton(
              onPressed: onStatusUpdate,
              label: order.status == LabOrderStatus.ordered 
                  ? 'Mark Collected' 
                  : 'Mark In Progress',
              icon: Icons.update_rounded,
            ),
          ),
      ],
    );
  }
}

/// Compact lab result card for lists
class LabResultCard extends StatelessWidget {
  const LabResultCard({
    super.key,
    required this.testName,
    required this.category,
    required this.date,
    this.resultStatus = 'Normal',
    this.onTap,
  });

  final String testName;
  final String category;
  final DateTime date;
  final String resultStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    final isAbnormal = resultStatus.toLowerCase() != 'normal';
    final statusColor = LabColors.getResultColor(resultStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: isAbnormal 
              ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LabColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LabTestIcon(testName: testName, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? LabColors.darkTextPrimary 
                                : LabColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? LabColors.darkTextSecondary 
                                : LabColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LabResultTag(status: resultStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark 
                        ? LabColors.darkTextSecondary 
                        : LabColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark 
                          ? LabColors.darkTextSecondary 
                          : LabColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: isDark 
                        ? LabColors.darkTextSecondary 
                        : LabColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel card showing test panel details
class LabPanelCard extends StatelessWidget {
  const LabPanelCard({
    super.key,
    required this.panel,
    required this.onTap,
    this.onOrder,
  });

  final LabTestPanel panel;
  final VoidCallback onTap;
  final VoidCallback? onOrder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LabColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPanelIcon(panel.name),
                  color: LabColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      panel.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark 
                            ? LabColors.darkTextPrimary 
                            : LabColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      panel.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark 
                            ? LabColors.darkTextSecondary 
                            : LabColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${panel.testCount} tests included',
                      style: const TextStyle(
                        fontSize: 11,
                        color: LabColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOrder != null)
                IconButton(
                  onPressed: onOrder,
                  icon: const Icon(Icons.add_circle_outline, color: LabColors.primary),
                  tooltip: 'Order Panel',
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark 
                      ? LabColors.darkTextSecondary 
                      : LabColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getPanelIcon(String panelName) {
    final lower = panelName.toLowerCase();
    if (lower.contains('diabetic')) return Icons.monitor_heart;
    if (lower.contains('cardiac')) return Icons.favorite;
    if (lower.contains('thyroid')) return Icons.biotech;
    if (lower.contains('anemia')) return Icons.bloodtype;
    if (lower.contains('liver')) return Icons.medical_services;
    if (lower.contains('operative') || lower.contains('surgery')) return Icons.local_hospital;
    if (lower.contains('pregnancy')) return Icons.pregnant_woman;
    if (lower.contains('fever')) return Icons.thermostat;
    if (lower.contains('arthritis')) return Icons.accessibility_new;
    if (lower.contains('routine') || lower.contains('checkup')) return Icons.health_and_safety;
    return Icons.science;
  }
}

/// Summary card for lab order (backward compatible with individual fields)
class LabOrderSummaryCard extends StatelessWidget {
  const LabOrderSummaryCard({
    super.key,
    this.order,
    // Individual field API for backward compatibility
    this.testName,
    this.testCode,
    this.status,
    this.urgency,
    this.labName,
    this.orderDate,
    this.isAbnormal,
    this.onTap,
    this.onRemove,
  });

  /// Full LabTestData object (preferred API)
  final LabTestData? order;
  
  // Individual fields for backward compatibility
  final String? testName;
  final String? testCode;
  final String? status;
  final String? urgency;
  final String? labName;
  final DateTime? orderDate;
  final bool? isAbnormal;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Resolve values from order object or individual fields
    final effectiveTestName = order?.name ?? testName ?? 'Unknown Test';
    final effectiveTestCode = order?.testCode ?? testCode;
    final effectiveStatus = order?.status.value ?? status ?? 'ordered';
    final effectiveUrgency = order?.priority.value ?? urgency ?? 'routine';
    final effectiveLabName = order?.labName ?? labName;
    final effectiveOrderDate = order?.orderDate ?? orderDate;
    final effectiveIsAbnormal = order?.isAbnormal ?? isAbnormal ?? false;
    
    final statusColor = LabColors.getStatusColor(effectiveStatus);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: effectiveIsAbnormal 
            ? BorderSide(color: LabColors.abnormal.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LabTestIcon(testName: effectiveTestName, size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            effectiveTestName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? LabColors.darkTextPrimary 
                                  : LabColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (effectiveIsAbnormal)
                          const AbnormalBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (effectiveTestCode != null)
                          Text(
                            effectiveTestCode,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark 
                                  ? LabColors.darkTextSecondary 
                                  : LabColors.textSecondary,
                            ),
                          ),
                        if (effectiveTestCode != null && effectiveLabName != null)
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark 
                                  ? LabColors.darkTextSecondary 
                                  : LabColors.textSecondary,
                            ),
                          ),
                        if (effectiveLabName != null)
                          Flexible(
                            child: Text(
                              effectiveLabName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark 
                                    ? LabColors.darkTextSecondary 
                                    : LabColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LabStatusTag(status: effectiveStatus, compact: true),
                  if (effectiveOrderDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d').format(effectiveOrderDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark 
                            ? LabColors.darkTextSecondary 
                            : LabColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: LabColors.cancelled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget for lab orders
class EmptyLabOrdersState extends StatelessWidget {
  const EmptyLabOrdersState({
    super.key,
    this.message = 'No lab orders',
    this.subtitle = 'Create a new lab order to get started',
    this.onCreateOrder,
    this.icon = Icons.science_rounded,
  });

  final String message;
  final String subtitle;
  final VoidCallback? onCreateOrder;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: LabColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 64,
                color: LabColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
              ),
            ),
            if (onCreateOrder != null) ...[
              const SizedBox(height: 24),
              LabGradientButton(
                onPressed: onCreateOrder,
                label: 'Create Lab Order',
                icon: Icons.add_rounded,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Select patient state widget
class SelectPatientState extends StatelessWidget {
  const SelectPatientState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: Colors.orange.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Patient',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open this screen from a patient\'s profile\nto view and create lab orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Private helper widgets =====================

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isDark,
  });

  final DateTime date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 12,
            color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({
    required this.result,
    required this.isAbnormal,
    required this.isDark,
  });

  final String result;
  final bool isAbnormal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isAbnormal ? LabColors.abnormal : LabColors.completed;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isAbnormal ? Icons.warning_rounded : Icons.check_circle_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
