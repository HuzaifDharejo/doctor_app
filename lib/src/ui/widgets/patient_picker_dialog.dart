import 'package:flutter/material.dart';

import '../../db/doctor_db.dart';
import '../../services/encounter_service.dart';
import '../../theme/app_theme.dart';
import '../screens/encounter_screen.dart';

/// Shared patient picker dialog used across the app
/// 
/// Usage:
/// ```dart
/// final patient = await showDialog<Patient>(
///   context: context,
///   builder: (context) => PatientPickerDialog(patients: patients),
/// );
/// ```
class PatientPickerDialog extends StatefulWidget {
  const PatientPickerDialog({
    super.key,
    required this.patients,
    this.title = 'Select Patient',
    this.subtitle = 'Choose a patient to continue',
    this.icon = Icons.person_search_rounded,
    this.iconColor = AppColors.quickActionPink,
  });

  final List<Patient> patients;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  State<PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<PatientPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _filteredPatients = widget.patients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = widget.patients;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredPatients = widget.patients.where((p) {
          final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
          return fullName.contains(lowerQuery) ||
              p.phone.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchField(isDark),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredPatients.isEmpty
                  ? _buildEmptyState()
                  : _buildPatientList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: _filterPatients,
      decoration: InputDecoration(
        hintText: 'Search patients...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No patients found',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(bool isDark) {
    return ListView.builder(
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: PatientColors.getColor(index),
            child: Text(
              patient.firstName.isNotEmpty
                  ? patient.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            '${patient.firstName} ${patient.lastName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(patient.phone),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, patient),
        );
      },
    );
  }
}

/// Centralized patient color palette
/// Used for consistent patient avatar colors across the app
class PatientColors {
  static const List<Color> _colors = [
    AppColors.primary,       // Indigo
    AppColors.purple,        // Purple
    AppColors.quickActionPink, // Pink
    AppColors.accent,        // Teal
    AppColors.warning,       // Amber
    AppColors.quickActionGreen, // Emerald
    AppColors.blue,          // Blue
    AppColors.error,         // Red
  ];

  /// Get a consistent color for a patient based on index
  static Color getColor(int index) {
    return _colors[index % _colors.length];
  }

  /// Get a color based on patient ID for consistency
  static Color getColorForPatient(int patientId) {
    return _colors[patientId % _colors.length];
  }

  /// Get all available colors
  static List<Color> get all => _colors;
}

/// Shared function to start a new encounter with patient picker
/// 
/// Use this from any screen that needs to start an encounter:
/// ```dart
/// await startNewEncounterWithPicker(context, db);
/// ```
Future<void> startNewEncounterWithPicker(
  BuildContext context,
  DoctorDatabase db,
) async {
  // Get all patients
  final patients = await db.getAllPatients();
  
  if (!context.mounted) return;
  
  if (patients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No patients found. Please add a patient first.')),
    );
    return;
  }

  // Show patient picker dialog
  final selectedPatient = await showDialog<Patient>(
    context: context,
    builder: (context) => PatientPickerDialog(
      patients: patients,
      title: 'New Visit',
      subtitle: 'Choose a patient to start a clinical visit',
      icon: Icons.medical_services_rounded,
    ),
  );

  if (selectedPatient == null || !context.mounted) return;

  // Create visit (encounter behind the scenes)
  final encounterService = EncounterService(db: db);
  try {
    final encounterId = await encounterService.startEncounter(
      patientId: selectedPatient.id,
      chiefComplaint: '',
      encounterType: 'outpatient',
    );

    if (!context.mounted) return;
    
    // Navigate to visit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EncounterScreen(
          encounterId: encounterId,
          patient: selectedPatient,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to create visit: $e')),
    );
  }
}
