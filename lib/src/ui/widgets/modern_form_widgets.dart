import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';

/// Modern UI widgets for medical forms with animations, glass-morphism, and quick actions
class ModernFormWidgets {
  ModernFormWidgets._();

  // ============= ANIMATED SECTION CARD =============
  
  /// Animated expandable section with glass-morphic design
  static Widget buildAnimatedSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isExpanded,
    required VoidCallback onToggle,
    Color? accentColor,
    String? badge,
    List<Widget>? quickActions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSurface.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded 
              ? color.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded ? [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon with animated background
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isExpanded 
                            ? LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isExpanded ? null : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: isExpanded ? Colors.white : color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quick actions
                    if (quickActions != null && isExpanded) ...quickActions,
                    // Expand icon
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.5 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                  const SizedBox(height: 8),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= QUICK FILL CHIPS =============
  
  /// Quick fill chips for common values with haptic feedback
  static Widget buildQuickFillChips({
    required BuildContext context,
    required List<String> options,
    required TextEditingController controller,
    String? label,
    Color? color,
    bool showClearButton = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...options.map((option) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.text = option;
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: controller.text == option 
                            ? chipColor 
                            : chipColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: controller.text == option 
                              ? chipColor 
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: controller.text == option 
                              ? Colors.white 
                              : chipColor,
                        ),
                      ),
                    ),
                  ),
                ),
              )),
              if (showClearButton && controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============= MODERN TEXT FIELD =============
  
  /// Modern text field with label, suggestions, and animations
  static Widget buildModernTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<String>? suggestions,
    String? Function(String?)? validator,
    bool required = false,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Text field
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            onTap: onTap,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: AppColors.primary, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: prefixIcon != null ? 0 : 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        // Quick suggestions
        if (suggestions != null && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          buildQuickFillChips(
            context: context,
            options: suggestions,
            controller: controller,
          ),
        ],
      ],
    );
  }

  // ============= VITALS DASHBOARD =============
  
  /// Modern vitals dashboard with visual indicators
  static Widget buildVitalsDashboard({
    required BuildContext context,
    required Map<String, TextEditingController> vitals,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final vitalConfigs = [
      {'key': 'bp', 'label': 'Blood Pressure', 'icon': Icons.favorite_rounded, 'unit': 'mmHg', 'color': AppColors.error},
      {'key': 'pulse', 'label': 'Pulse', 'icon': Icons.timeline_rounded, 'unit': 'bpm', 'color': AppColors.primary},
      {'key': 'temp', 'label': 'Temperature', 'icon': Icons.thermostat_rounded, 'unit': '°F', 'color': AppColors.warning},
      {'key': 'spo2', 'label': 'SpO2', 'icon': Icons.air_rounded, 'unit': '%', 'color': AppColors.info},
      {'key': 'rr', 'label': 'Resp Rate', 'icon': Icons.waves_rounded, 'unit': '/min', 'color': AppColors.accent},
      {'key': 'weight', 'label': 'Weight', 'icon': Icons.monitor_weight_rounded, 'unit': 'kg', 'color': const Color(0xFF8B5CF6)},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [AppColors.darkSurface, AppColors.darkBackground]
              : [Colors.white, AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Clear all vitals
                  for (final controller in vitals.values) {
                    controller.clear();
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vitals grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: vitalConfigs.map((config) {
              final controller = vitals[config['key'] as String];
              if (controller == null) return const SizedBox();
              
              return _buildVitalCard(
                context: context,
                controller: controller,
                label: config['label'] as String,
                icon: config['icon'] as IconData,
                unit: config['unit'] as String,
                color: config['color'] as Color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _buildVitalCard({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          AppInput.text(
            controller: controller,
            hint: '---',
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============= MODERN HEADER =============
  
  /// Modern gradient header with patient info
  static Widget buildModernHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? subtitle,
    Patient? patient,
    List<Color>? gradientColors,
    List<Widget>? actions,
  }) {
    final colors = gradientColors ?? [AppColors.primary, const Color(0xFF8B5CF6)];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // App bar row
              Row(
                children: [
                  _buildGlassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (actions != null) ...actions,
                ],
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
              // Patient info card
              if (patient != null) ...[
                const SizedBox(height: 20),
                _buildPatientInfoCard(context, patient),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  static Widget _buildPatientInfoCard(BuildContext context, Patient patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${patient.firstName[0]}${patient.lastName[0]}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient.firstName} ${patient.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (patient.dateOfBirth != null) ...[
                      Icon(
                        Icons.cake_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTime.now().year - patient.dateOfBirth!.year} yrs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.badge_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${patient.id}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============= FLOATING ACTION TOOLBAR =============
  
  /// Floating action toolbar with multiple actions
  static Widget buildFloatingToolbar({
    required BuildContext context,
    required List<FloatingToolbarAction> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSurface.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: action.isPrimary
                ? _buildPrimaryActionButton(context, action)
                : _buildSecondaryActionButton(context, action, isDark),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildPrimaryActionButton(
    BuildContext context,
    FloatingToolbarAction action,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [action.color ?? AppColors.primary, (action.color ?? AppColors.primary).withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (action.color ?? AppColors.primary).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(action.icon, color: Colors.white, size: 22),
                if (action.label != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    action.label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSecondaryActionButton(
    BuildContext context,
    FloatingToolbarAction action,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            action.icon,
            color: action.color ?? (isDark ? Colors.white70 : AppColors.textSecondary),
            size: 22,
          ),
        ),
      ),
    );
  }

  // ============= STATUS SELECTOR =============
  
  /// Modern status selector with icons
  static Widget buildStatusSelector({
    required BuildContext context,
    required String label,
    required List<StatusOption> options,
    required String selectedValue,
    required void Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((option) {
            final isSelected = selectedValue == option.value;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(option.value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: option == options.last ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? option.color.withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected 
                          ? option.color 
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        option.icon,
                        color: isSelected 
                            ? option.color 
                            : (isDark ? Colors.white54 : AppColors.textSecondary),
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? option.color 
                              : (isDark ? Colors.white70 : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============= DATE TIME PICKER =============
  
  /// Modern date/time picker
  static Widget buildDateTimePicker({
    required BuildContext context,
    required DateTime selectedDate,
    required void Function(DateTime) onDateChanged,
    bool showTime = false,
    String? label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              if (showTime) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );
                if (time != null) {
                  onDateChanged(DateTime(
                    date.year, date.month, date.day, time.hour, time.minute,
                  ));
                }
              } else {
                onDateChanged(date);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (showTime) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('h:mm a').format(selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============= PATIENT SELECTOR =============
  
  /// Modern patient selector with search
  static Widget buildPatientSelector({
    required BuildContext context,
    required List<Patient> patients,
    required int? selectedPatientId,
    required void Function(Patient?) onChanged,
    Patient? preselectedPatient,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPatient = preselectedPatient ?? 
        (selectedPatientId != null 
            ? patients.cast<Patient?>().firstWhere((p) => p?.id == selectedPatientId, orElse: () => null)
            : null);
    
    return GestureDetector(
      onTap: preselectedPatient != null 
          ? null 
          : () => _showPatientPicker(context, patients, onChanged),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selectedPatient != null 
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: selectedPatient == null 
              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05))
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedPatient != null 
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selectedPatient != null 
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: selectedPatient != null 
                  ? Center(
                      child: Text(
                        '${selectedPatient.firstName[0]}${selectedPatient.lastName[0]}'.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person_add_rounded,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPatient != null 
                        ? '${selectedPatient.firstName} ${selectedPatient.lastName}'
                        : 'Select Patient',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedPatient != null 
                          ? (isDark ? Colors.white : AppColors.textPrimary)
                          : (isDark ? Colors.white54 : AppColors.textSecondary),
                    ),
                  ),
                  if (selectedPatient != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${selectedPatient.id} • ${selectedPatient.phone}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (preselectedPatient == null)
              Icon(
                Icons.arrow_drop_down_rounded,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  static void _showPatientPicker(
    BuildContext context,
    List<Patient> patients,
    void Function(Patient?) onChanged,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatientPickerSheet(
        patients: patients,
        onSelected: (patient) {
          onChanged(patient);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ============= HELPER CLASSES =============

class FloatingToolbarAction {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? color;
  final bool isPrimary;

  const FloatingToolbarAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
    this.isPrimary = false,
  });
}

class StatusOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatusOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ============= PATIENT PICKER SHEET =============

class PatientPickerSheet extends StatefulWidget {
  final List<Patient> patients;
  final void Function(Patient) onSelected;

  const PatientPickerSheet({
    super.key,
    required this.patients,
    required this.onSelected,
  });

  @override
  State<PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<PatientPickerSheet> {
  late List<Patient> _filteredPatients;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPatients = widget.patients;
    _searchController.addListener(_filterPatients);
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = widget.patients.where((p) {
        final name = '${p.firstName} ${p.lastName}'.toLowerCase();
        return name.contains(query) || p.phone.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return ListTile(
                  onTap: () => widget.onSelected(patient),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${patient.firstName[0]}${patient.lastName[0]}'.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('${patient.firstName} ${patient.lastName}'),
                  subtitle: Text(patient.phone),
                  trailing: const Icon(Icons.chevron_right_rounded),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
