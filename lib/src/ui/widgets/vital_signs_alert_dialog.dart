import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/vital_thresholds_service.dart';

class VitalSignsAlertDialog extends StatelessWidget {
  final List<VitalSign> abnormalVitals;
  final List<VitalSign> criticalVitals;
  final VoidCallback onAcknowledge;
  final String? patientName;
  final String? patientPhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const VitalSignsAlertDialog({
    Key? key,
    required this.abnormalVitals,
    required this.criticalVitals,
    required this.onAcknowledge,
    this.patientName,
    this.patientPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
  }) : super(key: key);

  bool get _isEmergency => criticalVitals.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        _isEmergency ? Icons.emergency : Icons.warning_rounded,
        size: 56,
        color: _isEmergency ? Colors.red[700] : Colors.orange[700],
      ),
      title: Text(
        _isEmergency ? 'CRITICAL VITALS ⚠️' : 'ABNORMAL VITALS',
        style: TextStyle(
          color: _isEmergency ? Colors.red[700] : Colors.orange[700],
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEmergency) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emergency, color: Colors.red[700], size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'EMERGENCY - Immediate Action Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...criticalVitals.map((vital) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildVitalAlert(vital, Colors.red),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (abnormalVitals.isNotEmpty &&
                abnormalVitals.where((v) => !v.isCritical).isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Abnormal Vitals - Requires Attention',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...abnormalVitals
                        .where((v) => !v.isCritical)
                        .map((vital) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildVitalAlert(vital, Colors.orange),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Clinical Recommendations:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...abnormalVitals.map((vital) {
              if (vital.recommendation.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vital.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vital.recommendation,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        if (_isEmergency)
          AppButton.danger(
            label: 'Emergency',
            icon: Icons.local_hospital,
            onPressed: () {
              Navigator.pop(context);
              _showEmergencyProtocol(context);
            },
          ),
        AppButton.primary(
          label: 'Acknowledged',
          onPressed: onAcknowledge,
        ),
      ],
    );
  }

  Widget _buildVitalAlert(VitalSign vital, Color color) {
    final colorValue = color == Colors.red ? Colors.red[700]! : Colors.orange[700]!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            vital.isCritical ? Icons.error : Icons.warning,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vital.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorValue,
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${vital.value}${vital.unit}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: color,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Normal: ${vital.minNormal}-${vital.maxNormal}${vital.unit}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEmergencyProtocol(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.emergency,
          size: 64,
          color: Colors.red,
        ),
        title: const Text(
          'EMERGENCY PROTOCOL',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient info if available
              if (patientName != null && patientName!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(patientName!, style: const TextStyle(fontSize: 16)),
                      if (patientPhone != null && patientPhone!.isNotEmpty)
                        Text('📞 $patientPhone'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Critical vitals summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ CRITICAL VALUES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...criticalVitals.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${v.name}: ${v.value}${v.unit} (Normal: ${v.minNormal}-${v.maxNormal})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Emergency actions
              const Text(
                'Emergency Actions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildEmergencyAction(
                context,
                icon: Icons.phone_in_talk,
                color: Colors.green,
                label: 'Call Emergency Services',
                sublabel: '911 / Local Emergency',
                onTap: () => _callEmergency(context, '911'),
              ),
              
              if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty)
                _buildEmergencyAction(
                  context,
                  icon: Icons.contact_phone,
                  color: Colors.orange,
                  label: 'Call Emergency Contact',
                  sublabel: emergencyContactName ?? emergencyContactPhone!,
                  onTap: () => _callEmergency(context, emergencyContactPhone!),
                ),
              
              _buildEmergencyAction(
                context,
                icon: Icons.content_copy,
                color: Colors.blue,
                label: 'Copy Vital Signs',
                sublabel: 'Copy to clipboard for reporting',
                onTap: () => _copyVitalsToClipboard(context),
              ),
              
              const SizedBox(height: 16),
              
              // Emergency checklist
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Emergency Checklist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Stay calm and assess the situation'),
                    Text('2. Ensure patient safety'),
                    Text('3. Call emergency services if needed'),
                    Text('4. Administer first aid if trained'),
                    Text('5. Notify emergency contacts'),
                    Text('6. Document all observations'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close Protocol',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.danger(
            label: 'Call 911',
            icon: Icons.phone,
            onPressed: () => _callEmergency(context, '911'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sublabel),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  Future<void> _callEmergency(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not initiate call to $number. Please dial manually.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Copy',
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: number));
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _copyVitalsToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('CRITICAL VITAL SIGNS REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    if (patientName != null) {
      buffer.writeln('Patient: $patientName');
    }
    buffer.writeln('');
    buffer.writeln('CRITICAL VALUES:');
    for (final vital in criticalVitals) {
      buffer.writeln('• ${vital.name}: ${vital.value}${vital.unit} (Normal: ${vital.minNormal}-${vital.maxNormal}${vital.unit})');
    }
    if (abnormalVitals.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('ABNORMAL VALUES:');
      for (final vital in abnormalVitals) {
        buffer.writeln('• ${vital.name}: ${vital.value}${vital.unit} (Normal: ${vital.minNormal}-${vital.maxNormal}${vital.unit})');
      }
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Vital signs copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
