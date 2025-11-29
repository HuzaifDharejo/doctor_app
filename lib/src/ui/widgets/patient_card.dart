import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';
import '../screens/patient_view_screen.dart';
import 'patient_avatar.dart';

class PatientCard extends StatefulWidget {
  
  const PatientCard({
    required this.patient, super.key,
    this.lastVisit,
    this.nextAppointment,
    this.index = 0,
    this.heroTagPrefix,
  });
  final Patient patient;
  final DateTime? lastVisit;
  final DateTime? nextAppointment;
  final int index;
  final String? heroTagPrefix;

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    // Stagger animation based on index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRiskColor(int riskLevel) {
    if (riskLevel <= 2) return AppColors.riskLow;
    if (riskLevel <= 4) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  String _getRiskLabel(int riskLevel) {
    if (riskLevel <= 2) return 'Low';
    if (riskLevel <= 4) return 'Medium';
    return 'High';
  }

  IconData _getRiskIcon(int riskLevel) {
    if (riskLevel <= 2) return Icons.check_circle_rounded;
    if (riskLevel <= 4) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
    return DateFormat('MMM d, y').format(date);
  }

  String _formatUpcomingDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) return 'Today ${DateFormat('h:mm a').format(date)}';
    if (difference.inDays == 1) return 'Tomorrow ${DateFormat('h:mm a').format(date)}';
    if (difference.inDays < 7) return DateFormat('EEE h:mm a').format(date);
    return DateFormat('MMM d').format(date);
  }

  Future<void> _makePhoneCall() async {
    if (widget.patient.phone.isEmpty) return;
    unawaited(HapticFeedback.lightImpact());
    final uri = Uri(scheme: 'tel', path: widget.patient.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendMessage() async {
    if (widget.patient.phone.isEmpty) return;
    unawaited(HapticFeedback.lightImpact());
    final uri = Uri(scheme: 'sms', path: widget.patient.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PatientViewScreen(patient: widget.patient),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final riskLevel = patient.riskLevel;
    final riskColor = _getRiskColor(riskLevel);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar with gradient border - Hero animation
                        Hero(
                          tag: '${widget.heroTagPrefix ?? "card"}-patient-avatar-${patient.id}',
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.8),
                                  AppColors.primaryLight.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: PatientAvatar(
                                patientId: patient.id,
                                firstName: patient.firstName,
                                lastName: patient.lastName,
                                size: isCompact ? 44 : 50,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isCompact ? 12 : 16),
                        
                        // Patient Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: '${widget.heroTagPrefix ?? "card"}-patient-name-${patient.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          '${patient.firstName} ${patient.lastName}',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Risk Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          riskColor.withValues(alpha: 0.2),
                                          riskColor.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getRiskIcon(riskLevel),
                                          size: 12,
                                          color: riskColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getRiskLabel(riskLevel),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: riskColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isCompact ? 4 : 6),
                              
                              // Last visit / Next appointment info
                              if (widget.lastVisit != null || widget.nextAppointment != null)
                                Row(
                                  children: [
                                    if (widget.lastVisit != null) ...[
                                      Icon(
                                        Icons.history_rounded,
                                        size: 12,
                                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatRelativeDate(widget.lastVisit!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (widget.lastVisit != null && widget.nextAppointment != null)
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        width: 1,
                                        height: 12,
                                        color: isDark ? AppColors.darkDivider : AppColors.divider,
                                      ),
                                    if (widget.nextAppointment != null) ...[
                                      const Icon(
                                        Icons.event_rounded,
                                        size: 12,
                                        color: AppColors.appointments,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatUpcomingDate(widget.nextAppointment!),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.appointments,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.phone_rounded,
                                        size: 12,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        patient.phone.isNotEmpty ? patient.phone : 'No phone',
                                        style: TextStyle(
                                          fontSize: isCompact ? 11 : 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              
                              if (patient.medicalHistory.isNotEmpty) ...[
                                SizedBox(height: isCompact ? 8 : 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: patient.medicalHistory
                                      .split(',')
                                      .take(2)
                                      .map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.primary.withValues(alpha: 0.12),
                                                  AppColors.primaryLight.withValues(alpha: 0.08),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tag.trim().length > 15 ? '${tag.trim().substring(0, 12)}...' : tag.trim(),
                                              style: TextStyle(
                                                fontSize: isCompact ? 9 : 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),)
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Quick Actions
                        if (patient.phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              _QuickActionButton(
                                icon: Icons.call_rounded,
                                color: AppColors.success,
                                onTap: _makePhoneCall,
                                size: isCompact ? 32 : 36,
                              ),
                              const SizedBox(height: 6),
                              _QuickActionButton(
                                icon: Icons.message_rounded,
                                color: AppColors.info,
                                onTap: _sendMessage,
                                size: isCompact ? 32 : 36,
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick action button with ripple effect
class _QuickActionButton extends StatelessWidget {

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 36,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
