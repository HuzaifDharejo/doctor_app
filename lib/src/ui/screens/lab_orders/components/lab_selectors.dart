/// Lab Test Selector Components
/// 
/// Chip-based selectors for lab test categories, specimen types,
/// urgency levels, and status filters.

import 'package:flutter/material.dart';
import 'lab_models.dart';
import 'lab_theme.dart';

/// Category chip selector for filtering tests
class LabCategorySelector extends StatelessWidget {
  const LabCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.categories,
    this.scrollDirection = Axis.horizontal,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;
  final List<String>? categories;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cats = categories ?? LabCategory.values.map((c) => c.label).toList();
    
    final chips = cats.map((category) {
      final isSelected = selected == category;
      return Padding(
        padding: EdgeInsets.only(
          right: scrollDirection == Axis.horizontal ? 8 : 0,
          bottom: scrollDirection == Axis.vertical ? 8 : 0,
        ),
        child: FilterChip(
          label: Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? LabColors.darkTextPrimary : LabColors.textPrimary),
            ),
          ),
          selected: isSelected,
          onSelected: (sel) => onChanged(sel ? category : null),
          backgroundColor: isDark ? LabColors.darkBackground : Colors.white,
          selectedColor: LabColors.primary,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(
            color: isSelected 
                ? LabColors.primary
                : (isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
      );
    }).toList();

    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: chips,
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

/// Specimen type selector
class LabSpecimenSelector extends StatelessWidget {
  const LabSpecimenSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final LabSpecimenType selected;
  final ValueChanged<LabSpecimenType> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LabSpecimenType.values.map((specimen) {
        final isSelected = selected == specimen;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSpecimenIcon(specimen),
                size: compact ? 14 : 16,
                color: isSelected 
                    ? Colors.white 
                    : LabColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                specimen.label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? LabColors.darkTextPrimary : LabColors.textPrimary),
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(specimen),
          backgroundColor: isDark ? LabColors.darkBackground : Colors.white,
          selectedColor: LabColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(
            color: isSelected 
                ? LabColors.primary
                : (isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        );
      }).toList(),
    );
  }
  
  IconData _getSpecimenIcon(LabSpecimenType type) {
    switch (type) {
      case LabSpecimenType.blood:
        return Icons.bloodtype;
      case LabSpecimenType.urine:
        return Icons.water_drop;
      case LabSpecimenType.stool:
        return Icons.science;
      case LabSpecimenType.swab:
        return Icons.sanitizer;
      case LabSpecimenType.tissue:
        return Icons.medical_services;
      case LabSpecimenType.csf:
        return Icons.opacity;
      case LabSpecimenType.sputum:
        return Icons.air;
      case LabSpecimenType.other:
        return Icons.more_horiz;
    }
  }
}

/// Priority/urgency selector
class LabPrioritySelector extends StatelessWidget {
  const LabPrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.horizontal = true,
  });

  final LabPriority selected;
  final ValueChanged<LabPriority> onChanged;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final chips = LabPriority.values.map((priority) {
      final isSelected = selected == priority;
      final color = LabColors.getPriorityColor(priority.value);
      
      return Padding(
        padding: EdgeInsets.only(right: horizontal ? 8 : 0, bottom: horizontal ? 0 : 8),
        child: ChoiceChip(
          label: Text(
            priority.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(priority),
          backgroundColor: isDark 
              ? color.withValues(alpha: 0.1) 
              : color.withValues(alpha: 0.08),
          selectedColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(
            color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
          ),
        ),
      );
    }).toList();

    if (horizontal) {
      return Row(mainAxisSize: MainAxisSize.min, children: chips);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: chips,
    );
  }
}

/// Status filter tab bar
class LabStatusTabBar extends StatelessWidget {
  const LabStatusTabBar({
    super.key,
    required this.controller,
    this.tabs = const ['All', 'Pending', 'In Progress', 'Completed', 'Results'],
  });

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        labelColor: LabColors.primary,
        unselectedLabelColor: isDark 
            ? LabColors.darkTextSecondary 
            : LabColors.textSecondary,
        indicatorColor: LabColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

/// Quick panel selector chips
class LabQuickPanelSelector extends StatelessWidget {
  const LabQuickPanelSelector({
    super.key,
    required this.panels,
    required this.onSelected,
  });

  final List<LabTestPanel> panels;
  final ValueChanged<LabTestPanel> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: panels.map((panel) {
        return ActionChip(
          avatar: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: LabColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPanelIcon(panel.name),
              size: 14,
              color: LabColors.primary,
            ),
          ),
          label: Text(
            panel.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? LabColors.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () => onSelected(panel),
        );
      }).toList(),
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

/// Test template chip for quick selection
class LabTestTemplateChip extends StatelessWidget {
  const LabTestTemplateChip({
    super.key,
    required this.template,
    required this.onTap,
    this.isSelected = false,
    this.showCheckbox = true,
  });

  final LabTestTemplate template;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? LabColors.primary.withValues(alpha: 0.1)
              : (isDark ? LabColors.darkBackground : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected 
                ? LabColors.primary.withValues(alpha: 0.5)
                : (isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabTestIcon(
              testName: template.name,
              size: 16,
              color: isSelected ? LabColors.primary : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                template.name.length > 20 
                    ? '${template.name.substring(0, 17)}...' 
                    : template.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showCheckbox) ...[
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isSelected 
                    ? LabColors.primary 
                    : (isDark 
                        ? LabColors.darkTextSecondary 
                        : LabColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Toggle buttons for switching views (panels vs individual)
class LabViewToggle extends StatelessWidget {
  const LabViewToggle({
    super.key,
    required this.showPanels,
    required this.onToggle,
  });

  final bool showPanels;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'Quick Panels',
            icon: Icons.dashboard,
            isSelected: showPanels,
            onTap: () => onToggle(true),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleButton(
            label: 'Individual Tests',
            icon: Icons.list,
            isSelected: !showPanels,
            onTap: () => onToggle(false),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LabColors.primary.withValues(alpha: 0.1)
              : (isDark ? LabColors.darkSurface : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? LabColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? LabColors.primary 
                  : (isDark ? LabColors.darkTextSecondary : LabColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? LabColors.primary 
                    : (isDark ? LabColors.darkTextPrimary : LabColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
