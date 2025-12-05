import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// Data class to hold vital signs values
class VitalsData {
  final String? bpSystolic;
  final String? bpDiastolic;
  final String? heartRate;
  final String? temperature;
  final String? weight;
  final String? height;
  final String? spO2;
  final String? respiratoryRate;

  VitalsData({
    this.bpSystolic,
    this.bpDiastolic,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    this.spO2,
    this.respiratoryRate,
  });

  /// Get formatted BP string (e.g., "120/80")
  String? get formattedBP {
    if (bpSystolic == null && bpDiastolic == null) return null;
    return '${bpSystolic ?? ""}/${bpDiastolic ?? ""}';
  }

  /// Check if any vital sign is set
  bool get hasData {
    return bpSystolic != null || bpDiastolic != null || heartRate != null ||
           temperature != null || weight != null || height != null ||
           spO2 != null || respiratoryRate != null;
  }
}

/// Reusable vital signs input section with state management
/// Used across all medical record screens that need vitals entry
class VitalsInputSection extends StatefulWidget {
  const VitalsInputSection({
    super.key,
    this.showAllFields = true,
    this.compactMode = false,
    this.compact = false,  // Alias for compactMode
    this.accentColor,
    this.initialData,
  });

  final bool showAllFields;
  final bool compactMode;
  final bool compact;  // Alias for compactMode
  final Color? accentColor;
  final VitalsData? initialData;

  @override
  VitalsInputSectionState createState() => VitalsInputSectionState();
}

class VitalsInputSectionState extends State<VitalsInputSection> {
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _rrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      setData(widget.initialData!);
    }
  }

  @override
  void dispose() {
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _spo2Controller.dispose();
    _rrController.dispose();
    super.dispose();
  }

  /// Set vitals data from external source
  void setData(VitalsData data) {
    if (data.bpSystolic != null) _bpSystolicController.text = data.bpSystolic!;
    if (data.bpDiastolic != null) _bpDiastolicController.text = data.bpDiastolic!;
    if (data.heartRate != null) _pulseController.text = data.heartRate!;
    if (data.temperature != null) _tempController.text = data.temperature!;
    if (data.weight != null) _weightController.text = data.weight!;
    if (data.height != null) _heightController.text = data.height!;
    if (data.spO2 != null) _spo2Controller.text = data.spO2!;
    if (data.respiratoryRate != null) _rrController.text = data.respiratoryRate!;
  }

  /// Get current vitals data
  VitalsData getData() {
    return VitalsData(
      bpSystolic: _bpSystolicController.text.isNotEmpty ? _bpSystolicController.text : null,
      bpDiastolic: _bpDiastolicController.text.isNotEmpty ? _bpDiastolicController.text : null,
      heartRate: _pulseController.text.isNotEmpty ? _pulseController.text : null,
      temperature: _tempController.text.isNotEmpty ? _tempController.text : null,
      weight: _weightController.text.isNotEmpty ? _weightController.text : null,
      height: _heightController.text.isNotEmpty ? _heightController.text : null,
      spO2: _spo2Controller.text.isNotEmpty ? _spo2Controller.text : null,
      respiratoryRate: _rrController.text.isNotEmpty ? _rrController.text : null,
    );
  }

  /// Clear all vitals
  void clear() {
    _bpSystolicController.clear();
    _bpDiastolicController.clear();
    _pulseController.clear();
    _tempController.clear();
    _weightController.clear();
    _heightController.clear();
    _spo2Controller.clear();
    _rrController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = widget.compact || widget.compactMode;
    
    // Primary vitals (always shown)
    final primaryVitals = <Widget>[
      _VitalInputField(
        controller: _bpSystolicController,
        controller2: _bpDiastolicController,
        label: 'BP',
        hint: '120',
        hint2: '80',
        unit: 'mmHg',
        icon: Icons.favorite_rounded,
        iconColor: Colors.red,
        isDark: isDark,
        compact: isCompact,
        isBP: true,
      ),
      _VitalInputField(
        controller: _pulseController,
        label: 'Pulse',
        hint: '72',
        unit: 'bpm',
        icon: Icons.monitor_heart_rounded,
        iconColor: Colors.pink,
        isDark: isDark,
        compact: isCompact,
      ),
      _VitalInputField(
        controller: _tempController,
        label: 'Temp',
        hint: '98.6',
        unit: '°F',
        icon: Icons.thermostat_rounded,
        iconColor: Colors.orange,
        isDark: isDark,
        compact: isCompact,
      ),
      _VitalInputField(
        controller: _spo2Controller,
        label: 'SpO₂',
        hint: '98',
        unit: '%',
        icon: Icons.air_rounded,
        iconColor: Colors.blue,
        isDark: isDark,
        compact: isCompact,
      ),
    ];

    // Secondary vitals (shown when showAllFields is true)
    final secondaryVitals = <Widget>[
      if (widget.showAllFields)
        _VitalInputField(
          controller: _weightController,
          label: 'Weight',
          hint: '70',
          unit: 'kg',
          icon: Icons.monitor_weight_rounded,
          iconColor: Colors.purple,
          isDark: isDark,
          compact: isCompact,
        ),
      if (widget.showAllFields)
        _VitalInputField(
          controller: _heightController,
          label: 'Height',
          hint: '170',
          unit: 'cm',
          icon: Icons.height_rounded,
          iconColor: Colors.teal,
          isDark: isDark,
          compact: isCompact,
        ),
      if (widget.showAllFields)
        _VitalInputField(
          controller: _rrController,
          label: 'RR',
          hint: '16',
          unit: '/min',
          icon: Icons.air_outlined,
          iconColor: Colors.cyan,
          isDark: isDark,
          compact: isCompact,
        ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [...primaryVitals, ...secondaryVitals],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary vitals row
        Row(
          children: primaryVitals
              .map((w) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              )))
              .toList(),
        ),
        if (secondaryVitals.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Secondary vitals row
          Row(
            children: secondaryVitals
                .map((w) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: w,
                )))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Individual vital sign input field
class _VitalInputField extends StatelessWidget {
  const _VitalInputField({
    required this.controller,
    this.controller2,
    required this.label,
    required this.hint,
    this.hint2,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    this.compact = false,
    this.isBP = false,
  });

  final TextEditingController controller;
  final TextEditingController? controller2;
  final String label;
  final String hint;
  final String? hint2;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final bool compact;
  final bool isBP;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: isBP ? 120 : 100,
        child: _buildContent(context),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : iconColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 14 : 16, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Input field(s)
          if (isBP && controller2 != null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  '/',
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller2,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint2,
                      hintStyle: TextStyle(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
