import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/components/app_button.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../theme/app_theme.dart';
import '../edit_prescription_screen.dart';
import 'patient_view_widgets.dart';

/// Tab showing all prescriptions for a patient
class PatientPrescriptionsTab extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientPrescriptionsTab({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<PatientPrescriptionsTab> createState() =>
      _PatientPrescriptionsTabState();
}

class _PatientPrescriptionsTabState
    extends ConsumerState<PatientPrescriptionsTab> {
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final db = await ref.read(doctorDbProvider.future);
      final prescriptions =
          await db.getPrescriptionsForPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _prescriptions = prescriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No prescriptions yet',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          return _buildPrescriptionCard(context, prescription, isDark);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(
      BuildContext context, Prescription prescription, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final theme = Theme.of(context);

    // Parse medications from JSON
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (_) {}

    final itemCount = medications.length;
    // ignore: deprecated_member_use
    final diagnosis = prescription.diagnosis;

    return PatientItemCard(
      title: 'Prescription #${prescription.id}',
      subtitle:
          '$itemCount medication${itemCount != 1 ? 's' : ''}${diagnosis.isNotEmpty ? ' • $diagnosis' : ''}\n${dateFormat.format(prescription.createdAt)}',
      icon: Icons.medication,
      iconColor: theme.colorScheme.primary,
      onTap: () => _showPrescriptionDetails(prescription, medications, isDark),
    );
  }

  void _showPrescriptionDetails(
      Prescription prescription, List<dynamic> medications, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrescriptionDetailSheet(
        prescription: prescription,
        medications: medications,
        patient: widget.patient,
        isDark: isDark,
        onPrescriptionUpdated: _loadPrescriptions,
      ),
    );
  }
}

/// Bottom sheet showing prescription details with full actions
class _PrescriptionDetailSheet extends ConsumerStatefulWidget {
  final Prescription prescription;
  final List<dynamic> medications;
  final Patient patient;
  final bool isDark;
  final VoidCallback onPrescriptionUpdated;

  const _PrescriptionDetailSheet({
    required this.prescription,
    required this.medications,
    required this.patient,
    required this.isDark,
    required this.onPrescriptionUpdated,
  });

  @override
  ConsumerState<_PrescriptionDetailSheet> createState() =>
      _PrescriptionDetailSheetState();
}

class _PrescriptionDetailSheetState
    extends ConsumerState<_PrescriptionDetailSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final prescription = widget.prescription;
    final medications = widget.medications;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription #${prescription.id}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(prescription.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              widget.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: widget.isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Quick Actions Row
          _buildQuickActions(theme),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Diagnosis
                  // ignore: deprecated_member_use
                  if (prescription.diagnosis.isNotEmpty) ...[
                    _buildDetailSection(
                      'Diagnosis',
                      // ignore: deprecated_member_use
                      prescription.diagnosis,
                      Icons.medical_information_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Medications
                  if (medications.isNotEmpty) ...[
                    Text(
                      'Medications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...medications.map((item) =>
                        _buildMedicationItem(item as Map<String, dynamic>, theme)),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  if (prescription.instructions.isNotEmpty) ...[
                    _buildDetailSection(
                      'Instructions',
                      prescription.instructions,
                      Icons.notes_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Refillable badge
                  if (prescription.isRefillable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              size: 16, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Refillable Prescription',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Main Action Buttons
                  const SizedBox(height: 8),
                  _buildMainActions(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: Icons.phone_outlined,
            label: 'Call',
            onTap: _callPatient,
          ),
          _buildQuickActionButton(
            icon: Icons.message_outlined,
            label: 'SMS',
            onTap: _messagePatient,
          ),
          _buildQuickActionButton(
            icon: Icons.share_outlined,
            label: 'WhatsApp',
            onTap: _shareViaWhatsApp,
          ),
          _buildQuickActionButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            onTap: _generatePdf,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: widget.isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: widget.isDark ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> item, ThemeData theme) {
    final name = (item['name'] ?? item['medicationName'] ?? 'Unknown') as String;
    final dosage = (item['dosage'] ?? '') as String;
    final frequency = (item['frequency'] ?? '') as String;
    final duration = (item['duration'] ?? '') as String;
    final instructions =
        (item['instructions'] ?? item['notes'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medication_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (dosage.isNotEmpty || frequency.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [dosage, frequency].where((s) => s.isNotEmpty).join(' • '),
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
          if (duration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Duration: $duration',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              instructions,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: widget.isDark ? Colors.white54 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainActions(ThemeData theme) {
    return Column(
      children: [
        // Edit and Refill buttons
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: _isLoading ? null : _editPrescription,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                label: 'Refill',
                icon: Icons.refresh,
                onPressed: _isLoading ? null : _refillPrescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Delete button
        AppButton.danger(
          label: 'Delete Prescription',
          icon: Icons.delete_outline,
          fullWidth: true,
          onPressed: _isLoading ? null : _deletePrescription,
        ),
      ],
    );
  }

  // Action Methods

  Future<void> _callPatient() async {
    final phone = widget.patient.phone;
    if (phone.isEmpty) {
      _showSnackBar('No phone number available');
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not launch phone app');
    }
  }

  Future<void> _messagePatient() async {
    final phone = widget.patient.phone;
    if (phone.isEmpty) {
      _showSnackBar('No phone number available');
      return;
    }

    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not launch messaging app');
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final phone = widget.patient.phone;
    if (phone.isEmpty) {
      _showSnackBar('No phone number available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await WhatsAppService.sharePrescription(
        patient: widget.patient,
        prescription: widget.prescription,
        doctorName: profile.displayName,
        clinicName:
            profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
        clinicPhone: profile.clinicPhone,
      );
    } catch (e) {
      _showSnackBar('Error sharing: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);

    try {
      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await PdfService.sharePrescriptionPdf(
        patient: widget.patient,
        prescription: widget.prescription,
        doctorName: profile.displayName,
        clinicName:
            profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
        clinicPhone: profile.clinicPhone,
        clinicAddress: profile.clinicAddress,
        signatureData: (profile.signatureData?.isNotEmpty ?? false)
            ? profile.signatureData
            : null,
      );
      _showSnackBar('PDF generated successfully');
    } catch (e) {
      _showSnackBar('Error generating PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editPrescription() async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EditPrescriptionScreen(
          prescription: widget.prescription,
          patient: widget.patient,
        ),
      ),
    );
    widget.onPrescriptionUpdated();
  }

  Future<void> _refillPrescription() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Refill Prescription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Create a new prescription with the same medications for ${widget.patient.firstName} ${widget.patient.lastName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "A new prescription will be created with today's date.",
                      style: TextStyle(fontSize: 13, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.primary(
            label: 'Create Refill',
            icon: Icons.add,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final db = await ref.read(doctorDbProvider.future);

      // Create new prescription with same items
      final newPrescription = PrescriptionsCompanion.insert(
        patientId: widget.prescription.patientId,
        itemsJson: widget.prescription.itemsJson,
        instructions: Value(widget.prescription.instructions),
        isRefillable: Value(widget.prescription.isRefillable),
      );

      await db.insertPrescription(newPrescription);

      if (mounted) {
        Navigator.pop(context);
        widget.onPrescriptionUpdated();
        _showSnackBar('Prescription refilled successfully');
      }
    } catch (e) {
      _showSnackBar('Error creating refill: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePrescription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text(
          'Are you sure you want to delete this prescription? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      await db.deletePrescription(widget.prescription.id);

      if (mounted) {
        Navigator.pop(context);
        widget.onPrescriptionUpdated();
        _showSnackBar('Prescription deleted');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting prescription: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
