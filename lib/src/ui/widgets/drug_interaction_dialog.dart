import 'package:flutter/material.dart';
import '../../services/drug_interaction_service.dart';

class DrugInteractionDialog extends StatefulWidget {
  final String newMedication;
  final List<String> currentMedications;
  final List<DrugInteraction> interactions;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DrugInteractionDialog({
    Key? key,
    required this.newMedication,
    required this.currentMedications,
    required this.interactions,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<DrugInteractionDialog> createState() => _DrugInteractionDialogState();
}

class _DrugInteractionDialogState extends State<DrugInteractionDialog> {
  final _reasonController = TextEditingController();
  bool _acknowledgeRisk = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _criticalCount =>
      widget.interactions.where((i) => i.severity == InteractionSeverity.severe).length;
  int get _majorCount =>
      widget.interactions.where((i) => i.severity == InteractionSeverity.moderate).length;
  int get _minorCount =>
      widget.interactions.where((i) => i.severity == InteractionSeverity.mild).length;

  bool get _hasCritical => _criticalCount > 0;
  bool get _hasMajor => _majorCount > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        size: 56,
        color: _hasCritical ? Colors.red[700] : Colors.orange[700],
      ),
      title: Text(
        'DRUG INTERACTION CHECK',
        style: TextStyle(
          color: _hasCritical ? Colors.red[700] : Colors.orange[700],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Medication: ${widget.newMedication}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Checking against ${widget.currentMedications.length} current medication(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interaction Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasCritical)
                    _buildSeverityRow(
                      '🔴 CRITICAL',
                      _criticalCount,
                      Colors.red,
                    )
                  else
                    const SizedBox.shrink(),
                  if (_hasMajor)
                    Padding(
                      padding: EdgeInsets.only(top: _hasCritical ? 8 : 0),
                      child: _buildSeverityRow(
                        '🟡 MAJOR',
                        _majorCount,
                        Colors.orange,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_minorCount > 0)
                    Padding(
                      padding: EdgeInsets.only(
                          top: (_hasCritical || _hasMajor) ? 8 : 0),
                      child: _buildSeverityRow(
                        '🟢 MINOR',
                        _minorCount,
                        Colors.green,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interactions List
            Text(
              'Interactions Details:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...widget.interactions.map((interaction) {
              final isCritical = interaction.severity == InteractionSeverity.severe;
              final isMajor = interaction.severity == InteractionSeverity.moderate;
              final color = isCritical
                  ? Colors.red
                  : isMajor
                      ? Colors.orange
                      : Colors.green;
              final colorValue = isCritical ? Colors.red[700]! : isMajor ? Colors.orange[700]! : Colors.green[700]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    border: Border.all(color: color, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${interaction.drug1} + ${interaction.drug2}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: colorValue,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              interaction.severity.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: color,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        interaction.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (interaction.recommendation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  interaction.recommendation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),

            // Override Section (only for non-critical)
            if (!_hasCritical) ...[
              const SizedBox(height: 16),
              Text(
                'Override Prescription',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              AppInput.multiline(
                controller: _reasonController,
                hint: 'Enter reason for override...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _acknowledgeRisk,
                onChanged: (value) {
                  setState(() {
                    _acknowledgeRisk = value ?? false;
                  });
                },
                title: const Text(
                  'I acknowledge the interaction risk',
                  style: TextStyle(fontSize: 12),
                ),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton.tertiary(
          label: 'Cancel',
          onPressed: widget.onCancel,
        ),
        if (_hasCritical)
          FilledButton.tonalIcon(
            onPressed: null,
            icon: const Icon(Icons.block),
            label: const Text('Cannot Prescribe'),
          )
        else
          FilledButton(
            onPressed: _acknowledgeRisk ? widget.onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Prescribe Anyway'),
          ),
      ],
    );
  }

  Widget _buildSeverityRow(String label, int count, Color color) {
    final colorValue = color == Colors.red ? Colors.red[700]! : color == Colors.orange ? Colors.orange[700]! : Colors.green[700]!;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorValue,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Chip(
          label: Text(
            '$count interaction(s)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide(color: color),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
