import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// Model for a quick fill template
class QuickFillTemplateItem {
  const QuickFillTemplateItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.data,
    this.description,
  });

  /// Display label for the template
  final String label;
  
  /// Icon to show on the chip
  final IconData icon;
  
  /// Accent color for the chip
  final Color color;
  
  /// Data map to apply when template is selected
  final Map<String, dynamic> data;
  
  /// Optional description tooltip
  final String? description;
}

/// A unified quick fill template bar for all medical record forms
/// 
/// Displays template chips that can auto-fill form fields when tapped.
/// 
/// Example:
/// ```dart
/// QuickFillTemplateBar(
///   templates: [
///     QuickFillTemplateItem(
///       label: 'MI/ACS',
///       icon: Icons.warning_rounded,
///       color: Colors.red,
///       data: {'chief_complaint': 'Chest pain...', 'symptoms': ['Dyspnea']},
///     ),
///   ],
///   onTemplateSelected: _applyTemplate,
/// )
/// ```
class QuickFillTemplateBar extends StatelessWidget {
  const QuickFillTemplateBar({
    super.key,
    required this.templates,
    required this.onTemplateSelected,
    this.title = 'Quick Fill Templates',
    this.icon = Icons.flash_on_rounded,
    this.iconColor,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  /// List of available templates
  final List<QuickFillTemplateItem> templates;
  
  /// Callback when a template is selected
  final void Function(QuickFillTemplateItem template) onTemplateSelected;
  
  /// Title for the section
  final String title;
  
  /// Icon for the section header
  final IconData icon;
  
  /// Color for the header icon
  final Color? iconColor;
  
  /// Whether the section can be collapsed
  final bool collapsible;
  
  /// Initial expanded state if collapsible
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerIconColor = iconColor ?? Colors.amber.shade600;

    if (collapsible) {
      return _CollapsibleTemplateBar(
        templates: templates,
        onTemplateSelected: onTemplateSelected,
        title: title,
        icon: icon,
        iconColor: headerIconColor,
        initiallyExpanded: initiallyExpanded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: headerIconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: headerIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${templates.length} templates',
                  style: TextStyle(
                    fontSize: 10,
                    color: headerIconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Template chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((template) => _TemplateChip(
              template: template,
              onTap: () => onTemplateSelected(template),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  final QuickFillTemplateItem template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: template.description ?? 'Apply ${template.label} template',
      child: ActionChip(
        avatar: Icon(template.icon, size: 18, color: template.color),
        label: Text(template.label),
        onPressed: onTap,
        backgroundColor: template.color.withValues(alpha: 0.1),
        side: BorderSide(color: template.color.withValues(alpha: 0.3)),
        labelStyle: TextStyle(
          color: template.color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CollapsibleTemplateBar extends StatefulWidget {
  const _CollapsibleTemplateBar({
    required this.templates,
    required this.onTemplateSelected,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.initiallyExpanded,
  });

  final List<QuickFillTemplateItem> templates;
  final void Function(QuickFillTemplateItem template) onTemplateSelected;
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleTemplateBar> createState() => _CollapsibleTemplateBarState();
}

class _CollapsibleTemplateBarState extends State<_CollapsibleTemplateBar> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Header (tappable)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.templates.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.templates.map((template) => _TemplateChip(
                  template: template,
                  onTap: () => widget.onTemplateSelected(template),
                )).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showFirst 
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show template applied snackbar
void showTemplateAppliedSnackbar(BuildContext context, String templateName, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('$templateName template applied'),
        ],
      ),
      backgroundColor: color ?? AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}
