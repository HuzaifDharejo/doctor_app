import 'package:flutter/material.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../core/theme/design_tokens.dart';
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
    final isSevere = widget.allergyResult.severity == AllergySeverity.severe;
    final isModerate = widget.allergyResult.severity == AllergySeverity.moderate;

    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        size: 56,
        color: isSevere ? Colors.red[700] : Colors.orange[700],
      ),
      title: Text(
        'ALLERGY ALERT',
        style: TextStyle(
          color: isSevere ? Colors.red[700] : Colors.orange[700],
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
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSevere
                    ? Colors.red[50]
                    : isModerate
                        ? Colors.orange[50]
                        : Colors.yellow[50],
                border: Border.all(
                  color: isSevere
                      ? Colors.red
                      : isModerate
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
                    'Severity: ${widget.allergyResult.severity.label}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSevere
                          ? Colors.red[700]
                          : isModerate
                              ? Colors.orange[700]
                              : Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allergy Type: ${widget.allergyResult.allergyType}',
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
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  const SizedBox(height: 8),
                  Text(
                    widget.allergyResult.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.allergyResult.recommendation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 ${widget.allergyResult.recommendation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Override Section (only for non-critical)
            if (!isSevere) ...[
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
        AppButton.tertiary(
          label: 'Cancel',
          onPressed: widget.onCancel,
        ),
        if (isSevere)
          AppButton.secondary(
            label: 'Cannot Prescribe',
            icon: Icons.block,
            isDisabled: true,
            onPressed: widget.onCancel, // Close dialog since cannot prescribe
          )
        else
          AppButton.primary(
            label: 'Prescribe Anyway',
            isDisabled: !_acknowledgeRisk,
            onPressed: _acknowledgeRisk ? widget.onConfirm : widget.onCancel,
          ),
      ],
    );
  }
}


