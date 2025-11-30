import 'package:flutter/material.dart';
import 'allergy_checking_service.dart';
import 'drug_interaction_service.dart';

class PrescriptionSafetyService {
  final AllergyCheckingService _allergyService;
  final DrugInteractionService _interactionService;

  PrescriptionSafetyService({
    AllergyCheckingService? allergyService,
    DrugInteractionService? interactionService,
  })  : _allergyService = allergyService ?? AllergyCheckingService(),
        _interactionService = interactionService ?? DrugInteractionService();

  /// Check medication against patient allergies
  /// Returns null if no allergies, AllergyCheckResult if allergic
  AllergyCheckResult? checkMedicationAllergy({
    required String medicationName,
    required String patientAllergies,
  }) {
    if (patientAllergies.isEmpty) return null;

    final result = _allergyService.checkDrugAllergy(
      drugName: medicationName,
      patientAllergies: patientAllergies,
    );

    if (result.isAllergic) {
      return result;
    }
    return null;
  }

  /// Check new medication against all current medications
  /// Returns list of interactions found
  List<DrugInteraction> checkDrugInteractions({
    required String newMedication,
    required List<String> currentMedications,
  }) {
    if (currentMedications.isEmpty) return [];

    final interactions = <DrugInteraction>[];

    for (final currentMed in currentMedications) {
      final interaction =
          _interactionService.checkInteraction(currentMed, newMedication);
      if (interaction != null) {
        interactions.add(interaction);
      }
    }

    // Sort by severity (Critical > Major > Minor)
    interactions.sort((a, b) {
      final severityOrder = {'Critical': 0, 'Major': 1, 'Minor': 2};
      return (severityOrder[a.severity] ?? 3)
          .compareTo(severityOrder[b.severity] ?? 3);
    });

    return interactions;
  }

  /// Check if medication can be safely prescribed
  /// Returns: (canPrescribe, allergyResult, interactions)
  ({
    bool canPrescribe,
    AllergyCheckResult? allergyResult,
    List<DrugInteraction> interactions,
  }) performSafetyCheck({
    required String medicationName,
    required String patientAllergies,
    required List<String> currentMedications,
  }) {
    // Check allergies first
    final allergyResult = checkMedicationAllergy(
      medicationName: medicationName,
      patientAllergies: patientAllergies,
    );

    // Critical allergies cannot be overridden
    if (allergyResult != null && allergyResult.severity == 'Critical') {
      return (
        canPrescribe: false,
        allergyResult: allergyResult,
        interactions: [],
      );
    }

    // Check interactions
    final interactions = checkDrugInteractions(
      newMedication: medicationName,
      currentMedications: currentMedications,
    );

    // Critical interactions cannot be overridden
    final hasCriticalInteraction = interactions
        .any((i) => i.severity == 'Critical');

    if (hasCriticalInteraction) {
      return (
        canPrescribe: false,
        allergyResult: allergyResult,
        interactions: interactions,
      );
    }

    // If we reach here, can prescribe (may need acknowledgment)
    return (
      canPrescribe: true,
      allergyResult: allergyResult,
      interactions: interactions,
    );
  }

  /// Get list of safe alternative medications
  List<String> getSafeAlternatives({
    required String medication,
    required String allergen,
  }) {
    return _allergyService.getSafeAlternatives(
      medication: medication,
      allergen: allergen,
    );
  }

  /// Get monitoring requirements for drug interaction
  String getMonitoringRequirements({
    required String drug1,
    required String drug2,
  }) {
    final interaction = _interactionService.checkInteraction(drug1, drug2);
    if (interaction != null) {
      return 'Monitor for: ${interaction.description}';
    }
    return '';
  }
}

/// Result from prescription safety check
class PrescriptionSafetyResult {
  final bool canPrescribe;
  final AllergyCheckResult? allergyAlert;
  final List<DrugInteraction> interactions;
  final bool requiresAcknowledgment;

  PrescriptionSafetyResult({
    required this.canPrescribe,
    this.allergyAlert,
    required this.interactions,
  }) : requiresAcknowledgment =
            allergyAlert != null || interactions.isNotEmpty;

  /// Get user-friendly safety message
  String getSafetyMessage() {
    final messages = <String>[];

    if (allergyAlert != null) {
      messages.add('⚠️ ALLERGY: ${allergyAlert!.allergen} (${allergyAlert!.severity})');
    }

    if (interactions.isNotEmpty) {
      final critical = interactions.where((i) => i.severity == 'Critical').length;
      final major = interactions.where((i) => i.severity == 'Major').length;
      
      if (critical > 0) {
        messages.add('🔴 $critical CRITICAL interaction(s)');
      }
      if (major > 0) {
        messages.add('🟡 $major MAJOR interaction(s)');
      }
    }

    return messages.join(' | ');
  }
}
