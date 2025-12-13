import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// A reusable form section card with title, icon, and content
/// Provides consistent styling across all medical record forms
/// 
/// Enhanced with:
/// - Completion summaries when collapsed
/// - Risk indicators for high-risk sections
/// - Section keys for scroll navigation
/// - Mini progress indicator
class RecordFormSection extends StatelessWidget {
  const RecordFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
    this.trailing,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.padding,
    this.completionSummary,
    this.isHighRisk = false,
    this.riskBadgeText,
    this.sectionKey,
    this.onToggle,
    this.completedFields,
    this.totalFields,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;
  final Widget? trailing;
  final bool collapsible;
  final bool initiallyExpanded;
  final EdgeInsets? padding;
  /// Summary shown when section is collapsed (e.g., "3 symptoms selected")
  final String? completionSummary;
  /// If true, section gets red styling for risk warning
  final bool isHighRisk;
  /// Optional badge text (e.g., "HIGH RISK", "CRITICAL")
  final String? riskBadgeText;
  /// Key for scroll navigation
  final GlobalKey? sectionKey;
  /// Callback when section is expanded/collapsed, receives new expanded state
  final void Function(bool expanded)? onToggle;
  /// Number of completed fields (for mini progress)
  final int? completedFields;
  /// Total fields in section (for mini progress)
  final int? totalFields;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    if (collapsible) {
      return _CollapsibleSection(
        key: sectionKey,
        title: title,
        icon: icon,
        accentColor: color,
        initiallyExpanded: initiallyExpanded,
        completionSummary: completionSummary,
        isHighRisk: isHighRisk,
        riskBadgeText: riskBadgeText,
        onToggle: onToggle,
        completedFields: completedFields,
        totalFields: totalFields,
        child: child,
      );
    }

    return Container(
      key: sectionKey,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isHighRisk
            ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighRisk
              ? (isDark ? Colors.red.shade700 : Colors.red.shade300)
              : (isDark 
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1)),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              // Risk badge
              if (isHighRisk && riskBadgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riskBadgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Mini progress indicator
              if (completedFields != null && totalFields != null && totalFields! > 0) ...[
                _MiniProgressIndicator(
                  completed: completedFields!,
                  total: totalFields!,
                  color: color,
                ),
                const SizedBox(width: 8),
              ],
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Mini progress indicator for section headers
class _MiniProgressIndicator extends StatelessWidget {
  const _MiniProgressIndicator({
    required this.completed,
    required this.total,
    required this.color,
  });

  final int completed;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final isComplete = completed >= total;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.success : color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$completed/$total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isComplete ? AppColors.success : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible version of the section with enhanced features
class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.accentColor,
    required this.initiallyExpanded,
    this.completionSummary,
    this.isHighRisk = false,
    this.riskBadgeText,
    this.onToggle,
    this.completedFields,
    this.totalFields,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final bool initiallyExpanded;
  final String? completionSummary;
  final bool isHighRisk;
  final String? riskBadgeText;
  final void Function(bool expanded)? onToggle;
  final int? completedFields;
  final int? totalFields;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onToggle?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isHighRisk ? Colors.red : widget.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: widget.isHighRisk
            ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isHighRisk
              ? (isDark ? Colors.red.shade700 : Colors.red.shade300)
              : (isDark 
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Header (always visible, tappable)
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        // Completion summary when collapsed
                        if (!_isExpanded && widget.completionSummary != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.completionSummary!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Risk badge
                  if (widget.isHighRisk && widget.riskBadgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.riskBadgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Mini progress indicator
                  if (widget.completedFields != null && widget.totalFields != null && widget.totalFields! > 0) ...[
                    _MiniProgressIndicator(
                      completed: widget.completedFields!,
                      total: widget.totalFields!,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content (animated)
          ClipRect(
            child: AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: widget.child,
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick access section header (simpler, no card)
class RecordSectionHeader extends StatelessWidget {
  const RecordSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.accentColor,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color? accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A scaffold widget for medical record forms with gradient header
/// Provides consistent layout structure across all record screens
class RecordFormScaffold extends StatefulWidget {
  const RecordFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
    this.gradientColors,
    this.scrollController,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;
  final List<Color>? gradientColors;
  final ScrollController? scrollController;
  final Widget? trailing;

  @override
  State<RecordFormScaffold> createState() => _RecordFormScaffoldState();
}

class _RecordFormScaffoldState extends State<RecordFormScaffold> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;
    
    final colors = widget.gradientColors ?? [AppColors.primary, AppColors.primaryDark];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: _buildGradientHeader(context, colors, isCompact),
          ),
          // Body Content
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([widget.body]),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.pop(context);
  }

  Widget _buildGradientHeader(BuildContext context, List<Color> colors, bool isCompact) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: isCompact ? 16 : 24,
        right: isCompact ? 16 : 24,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => _handleBackNavigation(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Icon with enhanced shadow
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded, 
                      color: Colors.white.withValues(alpha: 0.85), 
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trailing widget (e.g., auto-save indicator)
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

/// Section info model for navigation bar
/// 
/// Supports two usage patterns:
/// 1. String key-based: Use [key] as unique identifier, [title] for display
/// 2. Legacy: Use [name] for both identifier and display
class SectionInfo {
  const SectionInfo({
    this.key,
    this.title,
    this.name,
    required this.icon,
    this.isComplete = false,
    this.isExpanded = true,
    this.isHighRisk = false,
  }) : assert(key != null || name != null, 'Either key or name must be provided');

  /// Unique string key for the section (used for navigation)
  final String? key;
  
  /// Display title for the section (falls back to name if not provided)
  final String? title;
  
  /// Legacy: section name (used as both key and display if key/title not provided)
  final String? name;
  
  /// Icon for the section
  final IconData icon;
  
  /// Whether this section is complete
  final bool isComplete;
  
  /// Whether this section is currently expanded
  final bool isExpanded;
  
  /// Whether this section represents high risk (shows red styling)
  final bool isHighRisk;
  
  /// Get the display name for this section
  String get displayName => title ?? name ?? key ?? '';
  
  /// Get the unique key for this section
  String get sectionKey => key ?? name ?? '';
}

/// A horizontal scrollable navigation bar for jumping between form sections
/// 
/// Shows pill-shaped buttons for each section with:
/// - Section icon and name
/// - Completion checkmark for completed sections
/// - Gradient highlighting for active/expanded sections
/// - Red styling for high-risk sections
/// 
/// Supports two callback patterns:
/// - [onSectionTap]: Called with section key (String) when tapped
/// - Index-based: Use sections[index].sectionKey to get the key
class SectionNavigationBar extends StatelessWidget {
  const SectionNavigationBar({
    super.key,
    required this.sections,
    required this.onSectionTap,
    this.accentColor,
  });

  final List<SectionInfo> sections;
  /// Called with the section key when a section is tapped
  final void Function(String sectionKey) onSectionTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = accentColor ?? AppColors.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(sections.length, (index) {
          final section = sections[index];
          final isExpanded = section.isExpanded;
          final isComplete = section.isComplete;
          final isRisk = section.isHighRisk;
          
          return Padding(
            padding: EdgeInsets.only(right: index < sections.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSectionTap(section.sectionKey),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isExpanded
                        ? LinearGradient(
                            colors: isRisk
                                ? [Colors.red, Colors.red.shade700]
                                : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                          )
                        : null,
                    color: isExpanded
                        ? null
                        : (isDark 
                            ? Colors.grey.shade800.withValues(alpha: 0.5) 
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: isComplete && !isExpanded
                        ? Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section.icon,
                        size: 16,
                        color: isExpanded
                            ? Colors.white
                            : (isRisk
                                ? Colors.red
                                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        section.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                      ),
                      if (isComplete) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: isExpanded ? Colors.white.withValues(alpha: 0.8) : AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Risk level indicator badge with color coding
class RiskIndicatorBadge extends StatelessWidget {
  const RiskIndicatorBadge({
    super.key,
    required this.level,
    this.animated = false,
  });

  final RiskLevel level;
  final bool animated;

  Color get color {
    switch (level) {
      case RiskLevel.none:
        return AppColors.success;
      case RiskLevel.low:
        return Colors.amber;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.critical:
        return Colors.red.shade900;
    }
  }

  IconData get icon {
    switch (level) {
      case RiskLevel.none:
        return Icons.shield_rounded;
      case RiskLevel.low:
        return Icons.info_outline;
      case RiskLevel.moderate:
        return Icons.warning_amber;
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.critical:
        return Icons.dangerous;
    }
  }

  String get label {
    switch (level) {
      case RiskLevel.none:
        return 'LOW RISK';
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum RiskLevel { none, low, moderate, high, critical }
