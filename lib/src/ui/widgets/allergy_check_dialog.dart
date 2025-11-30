import 'package:flutter/material.dart';
import '../../services/allergy_checking_service.dart';

class AllergyCheckDialog extends StatefulWidget {
  final String medicationName;
  final String patientAllergies;
  final AllergyCheckResult allergyResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AllergyCheckDialog({
    Key? key,
    required this.medicationName,
    required this.patientAllergies,
    required this.allergyResult,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AllergyCheckDialog> createState() => _AllergyCheckDialogState();
}

class _AllergyCheckDialogState extends State<AllergyCheckDialog> {
  final _reasonController = TextEditingController();
  bool _acknowledgeRisk = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.allergyResult.severity == 'Critical';
    final isSerious = widget.allergyResult.severity == 'Serious';

    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        size: 56,
        color: isCritical ? Colors.red[700] : Colors.orange[700],
      ),
      title: Text(
        'ALLERGY ALERT',
        style: TextStyle(
          color: isCritical ? Colors.red[700] : Colors.orange[700],
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCritical
                    ? Colors.red[50]
                    : isSerious
                        ? Colors.orange[50]
                        : Colors.yellow[50],
                border: Border.all(
                  color: isCritical
                      ? Colors.red
                      : isSerious
                          ? Colors.orange
                          : Colors.amber,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Severity: ${widget.allergyResult.severity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCritical
                          ? Colors.red[700]
                          : isSerious
                              ? Colors.orange[700]
                              : Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reaction Type: ${widget.allergyResult.reactionType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Allergy Details
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
                    'Medication: ${widget.medicationName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Known Allergy: ${widget.allergyResult.allergen}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reaction: ${widget.allergyResult.reaction}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safe Alternatives (if available)
            if (widget.allergyResult.safeAlternatives.isNotEmpty) ...[
              Text(
                'Safe Alternatives:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
              ),
              const SizedBox(height: 8),
              ...widget.allergyResult.safeAlternatives.map((alt) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Override Section (only for non-critical)
            if (!isCritical) ...[
              Text(
                'Override Prescription',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter reason for override...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
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
                  'I acknowledge the allergic reaction risk',
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
        OutlinedButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        if (isCritical)
          FilledButton.tonalIcon(
            onPressed: null, // Disabled for critical
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
}
