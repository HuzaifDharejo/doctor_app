import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'medication_models.dart';
import 'medication_theme.dart';

/// Selector component for medication frequency (OD, BD, TDS, etc.)
class FrequencySelector extends StatelessWidget {
  const FrequencySelector({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.showDescription = false,
    this.compact = false,
  });

  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool showDescription;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (compact) {
      return DropdownButtonFormField<String>(
        value: selectedValue.isNotEmpty ? selectedValue : 'OD',
        decoration: MedicationInputDecoration.build(
          isDark: isDark,
          hintText: 'Frequency',
        ),
        items: MedicationFrequency.codes
            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            .toList(),
        onChanged: (v) => onChanged(v ?? 'OD'),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicationFrequency.all.map((freq) {
        final isSelected = selectedValue == freq.code;
        return Tooltip(
          message: freq.description,
          child: InkWell(
            onTap: () => onChanged(freq.code),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? const LinearGradient(colors: [MedColors.accent, MedColors.secondary])
                    : null,
                color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    showDescription ? freq.description : freq.code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Selector component for medication timing (Before Food, After Food, etc.)
class TimingSelector extends StatelessWidget {
  const TimingSelector({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.showIcons = true,
  });

  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool showIcons;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicationTiming.all.map((timing) {
        final isSelected = selectedValue == timing.value;
        return InkWell(
          onTap: () => onChanged(timing.value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? const LinearGradient(colors: [MedColors.success, Color(0xFF059669)])
                  : null,
              color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                if (showIcons && timing.icon != null && !isSelected) ...[
                  Text(timing.icon!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                ],
                Text(
                  timing.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? Colors.white 
                        : (isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Quick pick chips for medication duration
class DurationQuickPicks extends StatelessWidget {
  const DurationQuickPicks({
    super.key,
    required this.currentValue,
    required this.onSelected,
    this.showExtended = false,
  });

  final String currentValue;
  final ValueChanged<String> onSelected;
  final bool showExtended;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final durations = showExtended 
        ? MedicationDuration.quickPicks 
        : MedicationDuration.quickPicks.take(6).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = currentValue == duration.value;
        return InkWell(
          onTap: () => onSelected(duration.value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? MedColors.primary.withValues(alpha: 0.15)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
              border: isSelected 
                  ? Border.all(color: MedColors.primary.withValues(alpha: 0.5))
                  : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Text(
              duration.label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? MedColors.primary 
                    : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dropdown selector for medication frequency 
class FrequencyDropdown extends StatelessWidget {
  const FrequencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : 'OD',
      decoration: MedicationInputDecoration.build(
        isDark: isDark,
        hintText: 'Frequency',
      ),
      items: MedicationFrequency.codes
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'OD'),
    );
  }
}

/// Quick prescription template selector
class QuickPrescriptionSelector extends StatelessWidget {
  const QuickPrescriptionSelector({
    super.key,
    required this.onSelect,
    this.showAll = false,
    this.compact = false,
  });

  final void Function(PrescriptionTemplate template) onSelect;
  final bool showAll;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = showAll 
        ? PrescriptionTemplates.all 
        : PrescriptionTemplates.all.take(6).toList();

    if (compact) {
      return SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: templates.length + (showAll ? 0 : 1),
          itemBuilder: (context, index) {
            if (!showAll && index == templates.length) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _MoreTemplatesChip(
                  isDark: isDark,
                  onTap: () => _showAllTemplates(context),
                ),
              );
            }
            final template = templates[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TemplateChip(
                template: template,
                isDark: isDark,
                onTap: () => onSelect(template),
              ),
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...templates.map((template) => _TemplateCard(
          template: template,
          isDark: isDark,
          onTap: () => onSelect(template),
        )),
        if (!showAll)
          _MoreTemplatesCard(
            isDark: isDark,
            count: PrescriptionTemplates.all.length - 6,
            onTap: () => _showAllTemplates(context),
          ),
      ],
    );
  }

  void _showAllTemplates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllTemplatesSheet(onSelect: onSelect),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.isDark,
    required this.onTap,
  });

  final PrescriptionTemplate template;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color ?? MedColors.primary.value);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${template.medicationCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTemplatesChip extends StatelessWidget {
  const _MoreTemplatesChip({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MedColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: MedColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, size: 18, color: MedColors.primary),
            const SizedBox(width: 6),
            Text(
              'More',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MedColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isDark,
    required this.onTap,
  });

  final PrescriptionTemplate template;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color ?? MedColors.primary.value);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.2),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(template.icon, style: const TextStyle(fontSize: 18)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${template.medicationCount} meds',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTemplatesCard extends StatelessWidget {
  const _MoreTemplatesCard({
    required this.isDark,
    required this.count,
    required this.onTap,
  });

  final bool isDark;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MedColors.primary.withValues(alpha: 0.1),
              MedColors.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: MedColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'View All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MedColors.primary,
              ),
            ),
            Text(
              '+$count more templates',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllTemplatesSheet extends StatelessWidget {
  const _AllTemplatesSheet({required this.onSelect});

  final void Function(PrescriptionTemplate template) onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: MedColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Templates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${PrescriptionTemplates.all.length} templates available',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: EdgeInsets.all(context.responsivePadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.responsive(
                      compact: 2,
                      medium: 3,
                      expanded: 4,
                    ),
                    childAspectRatio: context.responsive(
                      compact: 1.2,
                      medium: 1.3,
                      expanded: 1.4,
                    ),
                    crossAxisSpacing: context.responsiveItemSpacing,
                    mainAxisSpacing: context.responsiveItemSpacing,
                  ),
                  itemCount: PrescriptionTemplates.all.length,
                  itemBuilder: (context, index) {
                    final template = PrescriptionTemplates.all[index];
                    return _TemplateGridItem(
                      template: template,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(template);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      );
    }
  }

class _TemplateGridItem extends StatelessWidget {
  const _TemplateGridItem({
    required this.template,
    required this.isDark,
    required this.onTap,
  });

  final PrescriptionTemplate template;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(template.color ?? MedColors.primary.value);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.2),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(template.icon, style: const TextStyle(fontSize: 20)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MedColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: MedColors.success, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${template.medicationCount} medications',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
