import 'package:flutter/material.dart';
import '../../services/vital_thresholds_service.dart';

class VitalSignsAlertDialog extends StatelessWidget {
  final List<VitalSign> abnormalVitals;
  final List<VitalSign> criticalVitals;
  final VoidCallback onAcknowledge;

  const VitalSignsAlertDialog({
    Key? key,
    required this.abnormalVitals,
    required this.criticalVitals,
    required this.onAcknowledge,
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
                padding: const EdgeInsets.all(12),
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
            if (abnormalVitals.isNotEmpty && abnormalVitals != criticalVitals) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
              'Recommendations:',
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
                  padding: const EdgeInsets.all(10),
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
                );
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        if (_isEmergency)
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              // Could trigger emergency protocol here
            },
            icon: const Icon(Icons.call_emergency),
            label: const Text('Call Emergency'),
          ),
        FilledButton(
          onPressed: onAcknowledge,
          child: const Text('Acknowledged'),
        ),
      ],
    );
  }

  Widget _buildVitalAlert(VitalSign vital, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
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
                        color: color[700],
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
}
