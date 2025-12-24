import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Emergency info quick access floating button
class EmergencyInfoButton extends StatefulWidget {
  const EmergencyInfoButton({
    super.key,
    required this.patientName,
    this.bloodType,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalAlerts,
  });

  final String patientName;
  final String? bloodType;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String>? medicalAlerts;

  @override
  State<EmergencyInfoButton> createState() => _EmergencyInfoButtonState();
}

class _EmergencyInfoButtonState extends State<EmergencyInfoButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _callEmergencyContact() async {
    if (widget.emergencyContactPhone != null && widget.emergencyContactPhone!.isNotEmpty) {
      final uri = Uri.parse('tel:${widget.emergencyContactPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        // Expanded panel
        if (_isExpanded)
          Positioned(
            bottom: 60,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.bottomRight,
                child: _buildExpandedPanel(context),
              ),
            ),
          ),
        // FAB button
        _buildFabButton(),
      ],
    );
  }

  Widget _buildFabButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isExpanded
                  ? [const Color(0xFF6B7280), const Color(0xFF4B5563)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isExpanded 
                    ? const Color(0xFF6B7280) 
                    : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isExpanded ? Icons.close_rounded : Icons.emergency_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 280,
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      widget.patientName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Blood Type
          if (widget.bloodType != null && widget.bloodType!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.bloodtype_rounded,
              label: 'Blood Type',
              value: widget.bloodType!,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              isHighlighted: true,
            ),
          
          // Allergies
          if (widget.allergies != null && widget.allergies!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.warning_amber_rounded,
              label: 'Allergies',
              value: widget.allergies!,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          
          // Medical Alerts
          if (widget.medicalAlerts != null && widget.medicalAlerts!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.medicalAlerts!.map((alert) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    alert,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Emergency Contact
          if (widget.emergencyContactName != null && widget.emergencyContactName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.contact_emergency_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.emergencyContactName!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  if (widget.emergencyContactPhone != null && widget.emergencyContactPhone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _callEmergencyContact,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              widget.emergencyContactPhone!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 18 : 12,
                    fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact emergency alert chip
class EmergencyAlertChip extends StatelessWidget {
  const EmergencyAlertChip({
    super.key,
    required this.hasAllergies,
    this.bloodType,
    this.onTap,
  });

  final bool hasAllergies;
  final String? bloodType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emergency_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            if (bloodType != null && bloodType!.isNotEmpty) ...[
              Text(
                bloodType!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (hasAllergies) ...[
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
            if (hasAllergies)
              const Icon(Icons.warning_rounded, size: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
