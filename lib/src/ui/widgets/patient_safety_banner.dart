import 'package:flutter/material.dart';
import '../../models/patient.dart';

class PatientSafetyBanner extends StatelessWidget {
  const PatientSafetyBanner({
    required this.patient,
    this.compact = false,
    super.key,
  });

  final PatientModel patient;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final warnings = _buildWarnings();
    
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      margin: EdgeInsets.all(compact ? 4 : 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border.all(color: _getBorerColor(), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Safety Alerts',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ...warnings.map((warning) => Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warning['icon'] as IconData,
                  size: compact ? 16 : 20,
                  color: warning['color'] as Color,
                ),
                SizedBox(width: compact ? 6 : 12),
                Expanded(
                  child: Text(
                    warning['text'] as String,
                    style: TextStyle(
                      color: warning['color'] as Color,
                      fontWeight: FontWeight.w500,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildWarnings() {
    final warnings = <Map<String, dynamic>>[];

    // Check for allergies
    if (patient.hasAllergies) {
      warnings.add({
        'icon': Icons.warning_amber,
        'color': Colors.red,
        'text': '⚠️ Allergies: ${patient.allergies}',
      });
    }

    // Check for high-risk patient
    if (patient.riskLevel == 2) {
      warnings.add({
        'icon': Icons.priority_high,
        'color': Colors.red,
        'text': '🔴 HIGH RISK PATIENT - Exercise caution with treatment decisions',
      });
    } else if (patient.riskLevel == 1) {
      warnings.add({
        'icon': Icons.info,
        'color': Colors.orange,
        'text': '⚠️ Medium risk patient - Monitor closely',
      });
    }

    // Check for missing critical information
    if (patient.emergencyContactPhone.isEmpty) {
      warnings.add({
        'icon': Icons.contact_phone,
        'color': Colors.orange,
        'text': '📞 Emergency contact missing',
      });
    }

    // Check for chronic conditions
    if (patient.chronicConditions.isNotEmpty && patient.chronicConditions.length <= 3) {
      warnings.add({
        'icon': Icons.medical_information,
        'color': Colors.blue,
        'text': '📋 Chronic: ${patient.chronicConditions.join(", ")}',
      });
    }

    return warnings;
  }

  Color _getBackgroundColor() {
    if (patient.hasAllergies || patient.riskLevel == 2) {
      return Colors.red.shade50;
    } else if (patient.riskLevel == 1) {
      return Colors.orange.shade50;
    }
    return Colors.blue.shade50;
  }

  Color _getBorerColor() {
    if (patient.hasAllergies || patient.riskLevel == 2) {
      return Colors.red.shade300;
    } else if (patient.riskLevel == 1) {
      return Colors.orange.shade300;
    }
    return Colors.blue.shade300;
  }
}
