import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// Status options for a clinical finding
enum FindingStatus {
  notExamined,
  normal,
  abnormal,
  notApplicable,
}

extension FindingStatusExtension on FindingStatus {
  String get label {
    switch (this) {
      case FindingStatus.notExamined:
        return 'Not Examined';
      case FindingStatus.normal:
        return 'Normal';
      case FindingStatus.abnormal:
        return 'Abnormal';
      case FindingStatus.notApplicable:
        return 'N/A';
    }
  }

  IconData get icon {
    switch (this) {
      case FindingStatus.notExamined:
        return Icons.remove_circle_outline;
      case FindingStatus.normal:
        return Icons.check_circle;
      case FindingStatus.abnormal:
        return Icons.error;
      case FindingStatus.notApplicable:
        return Icons.block;
    }
  }

  Color get color {
    switch (this) {
      case FindingStatus.notExamined:
        return Colors.grey;
      case FindingStatus.normal:
        return Colors.green;
      case FindingStatus.abnormal:
        return Colors.red;
      case FindingStatus.notApplicable:
        return Colors.grey;
    }
  }
}

/// A row for recording a clinical finding with status (Normal/Abnormal)
/// 
/// Commonly used in physical exam screens to record observations.
/// 
/// Example:
/// ```dart
/// FindingRow(
///   label: 'Heart Sounds',
///   status: _heartSoundsStatus,
///   onStatusChanged: (s) => setState(() => _heartSoundsStatus = s),
///   details: _heartSoundsDetails,
///   onDetailsChanged: (d) => setState(() => _heartSoundsDetails = d),
/// )
/// ```
class FindingRow extends StatelessWidget {
  const FindingRow({
    super.key,
    required this.label,
    required this.status,
    required this.onStatusChanged,
    this.details,
    this.onDetailsChanged,
    this.icon,
    this.showDetails = true,
    this.detailsHint,
    this.detailsMaxLines = 2,
    this.compactMode = false,
  });

  /// Label for the finding
  final String label;
  
  /// Current status
  final FindingStatus status;
  
  /// Callback when status changes
  final ValueChanged<FindingStatus> onStatusChanged;
  
  /// Details/notes for abnormal findings
  final String? details;
  
  /// Callback when details change
  final ValueChanged<String>? onDetailsChanged;
  
  /// Leading icon
  final IconData? icon;
  
  /// Whether to show details field (shown when abnormal)
  final bool showDetails;
  
  /// Hint for details field
  final String? detailsHint;
  
  /// Max lines for details field
  final int detailsMaxLines;
  
  /// Use compact vertical layout
  final bool compactMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey.shade800.withValues(alpha: 0.3) 
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status == FindingStatus.abnormal
              ? Colors.red.withValues(alpha: 0.5)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: status == FindingStatus.abnormal ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: status.color,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              if (compactMode) ...[
                // Compact dropdown
                DropdownButton<FindingStatus>(
                  value: status,
                  onChanged: (s) => onStatusChanged(s!),
                  underline: const SizedBox(),
                  isDense: true,
                  items: FindingStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 16, color: s.color),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: TextStyle(fontSize: 12, color: s.color),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ] else ...[
                // Segmented button
                _StatusButtons(
                  status: status,
                  onChanged: onStatusChanged,
                ),
              ],
            ],
          ),
          // Details field for abnormal
          if (showDetails && 
              status == FindingStatus.abnormal && 
              onDetailsChanged != null) ...[
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: details),
              onChanged: onDetailsChanged,
              maxLines: detailsMaxLines,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                hintText: detailsHint ?? 'Describe the abnormal finding...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.notes, size: 18),
                filled: true,
                fillColor: isDark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusButtons extends StatelessWidget {
  const _StatusButtons({
    required this.status,
    required this.onChanged,
  });

  final FindingStatus status;
  final ValueChanged<FindingStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusButton(
          label: 'N',
          tooltip: 'Normal',
          isSelected: status == FindingStatus.normal,
          color: Colors.green,
          onTap: () => onChanged(FindingStatus.normal),
        ),
        const SizedBox(width: 4),
        _StatusButton(
          label: 'A',
          tooltip: 'Abnormal',
          isSelected: status == FindingStatus.abnormal,
          color: Colors.red,
          onTap: () => onChanged(FindingStatus.abnormal),
        ),
        const SizedBox(width: 4),
        _StatusButton(
          label: '—',
          tooltip: 'Not Examined',
          isSelected: status == FindingStatus.notExamined,
          color: Colors.grey,
          onTap: () => onChanged(FindingStatus.notExamined),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A group of findings in a card
/// 
/// Example:
/// ```dart
/// FindingsGroup(
///   title: 'Cardiovascular Exam',
///   icon: Icons.favorite,
///   findings: [
///     FindingData(label: 'Heart Rate', status: _hrStatus),
///     FindingData(label: 'Heart Sounds', status: _hsStatus),
///   ],
///   onStatusChanged: (index, status) => ...,
/// )
/// ```
class FindingsGroup extends StatelessWidget {
  const FindingsGroup({
    super.key,
    required this.findings,
    required this.onStatusChanged,
    this.title,
    this.icon,
    this.accentColor,
    this.showAllNormal = true,
    this.onDetailsChanged,
  });

  final List<FindingData> findings;
  final void Function(int index, FindingStatus status) onStatusChanged;
  final void Function(int index, String details)? onDetailsChanged;
  final String? title;
  final IconData? icon;
  final Color? accentColor;
  final bool showAllNormal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = accentColor ?? Theme.of(context).primaryColor;
    
    final normalCount = findings.where(
      (f) => f.status == FindingStatus.normal
    ).length;
    final abnormalCount = findings.where(
      (f) => f.status == FindingStatus.abnormal
    ).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: abnormalCount > 0
              ? Colors.red.withValues(alpha: 0.5)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: effectiveColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
                  ),
                  const Spacer(),
                  // Summary badges
                  if (normalCount > 0)
                    _CountBadge(
                      count: normalCount,
                      label: 'Normal',
                      color: Colors.green,
                    ),
                  if (abnormalCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(
                      count: abnormalCount,
                      label: 'Abnormal',
                      color: Colors.red,
                    ),
                  ],
                  if (showAllNormal) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('All Normal', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        for (var i = 0; i < findings.length; i++) {
                          onStatusChanged(i, FindingStatus.normal);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          if (title != null)
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          // Findings list
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: findings.asMap().entries.map((entry) {
                final index = entry.key;
                final finding = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FindingRow(
                    label: finding.label,
                    status: finding.status,
                    onStatusChanged: (s) => onStatusChanged(index, s),
                    details: finding.details,
                    onDetailsChanged: onDetailsChanged != null
                        ? (d) => onDetailsChanged!(index, d)
                        : null,
                    icon: finding.icon,
                    compactMode: finding.compactMode,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Data class for a finding
class FindingData {
  const FindingData({
    required this.label,
    this.status = FindingStatus.notExamined,
    this.details,
    this.icon,
    this.compactMode = false,
  });

  final String label;
  final FindingStatus status;
  final String? details;
  final IconData? icon;
  final bool compactMode;

  FindingData copyWith({
    String? label,
    FindingStatus? status,
    String? details,
    IconData? icon,
    bool? compactMode,
  }) {
    return FindingData(
      label: label ?? this.label,
      status: status ?? this.status,
      details: details ?? this.details,
      icon: icon ?? this.icon,
      compactMode: compactMode ?? this.compactMode,
    );
  }
}

/// Quick observation row for simple present/absent findings
/// 
/// Example:
/// ```dart
/// ObservationRow(
///   label: 'Edema',
///   isPresent: _edemaPresent,
///   onChanged: (v) => setState(() => _edemaPresent = v),
/// )
/// ```
class ObservationRow extends StatelessWidget {
  const ObservationRow({
    super.key,
    required this.label,
    required this.isPresent,
    required this.onChanged,
    this.icon,
    this.presentIcon = Icons.check,
    this.absentIcon = Icons.close,
    this.presentColor,
    this.absentColor,
  });

  final String label;
  final bool? isPresent;
  final ValueChanged<bool?> onChanged;
  final IconData? icon;
  final IconData presentIcon;
  final IconData absentIcon;
  final Color? presentColor;
  final Color? absentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePresentColor = presentColor ?? Colors.red.shade600;
    final effectiveAbsentColor = absentColor ?? Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                icon: absentIcon,
                label: 'No',
                isSelected: isPresent == false,
                color: effectiveAbsentColor,
                onTap: () => onChanged(isPresent == false ? null : false),
              ),
              const SizedBox(width: 6),
              _ToggleButton(
                icon: presentIcon,
                label: 'Yes',
                isSelected: isPresent == true,
                color: effectivePresentColor,
                onTap: () => onChanged(isPresent == true ? null : true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: isSelected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
