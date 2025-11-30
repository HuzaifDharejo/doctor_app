# 🔧 QUICK INTEGRATION GUIDE
## How to Add Safety Checks to Existing Screens

**Last Updated**: November 30, 2024

This guide provides copy-paste code snippets to integrate the new safety checking services into your existing UI screens.

---

## 1️⃣ ALLERGY CHECKING IN PRESCRIPTION SCREEN

### Location
`lib/src/ui/screens/add_prescription_screen.dart`

### Code to Add (in _addMedication() or before save)

```dart
// Check for allergy contraindications
Future<void> _checkAllergiesForMedication(String medicationName) async {
  if (_selectedPatient == null) return;
  
  final allergyCheck = AllergyCheckingService.checkDrugSafety(
    allergyHistory: _selectedPatient!.allergies,
    proposedDrug: medicationName,
  );
  
  if (allergyCheck.hasConcern) {
    // Show warning dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ ALLERGY ALERT'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient allergic to: ${allergyCheck.allergyType}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSeverityBadge(allergyCheck.severity),
              const SizedBox(height: 12),
              Text(allergyCheck.message),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendation:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(allergyCheck.recommendation),
                    const SizedBox(height: 12),
                    Text(
                      'Education:',
                      style: Theme.of(ctx).textTheme.labelSmall,
                    ),
                    Text(
                      AllergyCheckingService.getAllergyEducation(allergyCheck.allergyType),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Use Alternative'),
          ),
          if (allergyCheck.severity == AllergySeverity.mild ||
              allergyCheck.severity == AllergySeverity.moderate)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Mark as confirmed and continue
                _medications.last.allergy Acknowledged = true;
                setState(() {});
              },
              child: const Text('Acknowledge & Continue'),
            ),
        ],
      ),
    );
  }
}

Widget _buildSeverityBadge(AllergySeverity severity) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Color(severity.colorValue),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      severity.label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
```

### Call this before saving medication
```dart
// In your save button handler
for (final med in _medications) {
  if (med.name.isNotEmpty) {
    await _checkAllergiesForMedication(med.name);
  }
}
```

---

## 2️⃣ DRUG INTERACTION CHECKING IN PRESCRIPTION SCREEN

### Location
Same file: `lib/src/ui/screens/add_prescription_screen.dart`

### Code to Add

```dart
// Check for drug interactions with existing prescriptions
Future<void> _checkDrugInteractions() async {
  if (_selectedPatientId == null || _medications.isEmpty) return;
  
  try {
    final db = await ref.read(doctorDbProvider.future);
    
    // Get current active medications
    final currentPrescriptions = 
        await db.getActivePrescriptionsForPatient(_selectedPatientId!);
    
    // Extract medication names from new prescriptions
    final newMedications = _medications
        .where((m) => m.name.isNotEmpty)
        .map((m) => m.name)
        .toList();
    
    // Extract medication names from current prescriptions
    final currentMedNames = <String>[];
    for (final rx in currentPrescriptions) {
      try {
        final items = jsonDecode(rx.itemsJson) as List<dynamic>;
        for (final item in items) {
          if (item is Map && item['name'] != null) {
            currentMedNames.add(item['name'].toString());
          }
        }
      } catch (_) {}
    }
    
    // Check for interactions
    final interactions = DrugInteractionService.checkMultipleInteractions(
      currentMedications: currentMedNames,
      newMedications: newMedications,
    );
    
    if (interactions.isNotEmpty) {
      _showInteractionWarning(interactions);
    }
  } catch (e) {
    // Log error but don't block prescription
    debugPrint('Error checking interactions: $e');
  }
}

void _showInteractionWarning(List<DrugInteraction> interactions) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ DRUG INTERACTION ALERT'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final interaction in interactions) ...[
              if (interactions.indexOf(interaction) > 0)
                const Divider(height: 16),
              _buildInteractionCard(interaction),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Review Medications'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            // Mark as reviewed and continue
            setState(() => _interactionsAcknowledged = true);
          },
          child: const Text('Acknowledge'),
        ),
      ],
    ),
  );
}

Widget _buildInteractionCard(DrugInteraction interaction) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(
        color: Color(interaction.severity.colorValue),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(8),
      color: Color(interaction.severity.colorValue).withOpacity(0.1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(interaction.severity.colorValue),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                interaction.severity.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${interaction.drug1} + ${interaction.drug2}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(interaction.description),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommendation:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.recommendation,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### Call this before save
```dart
// In your save button handler, after checking allergies
await _checkDrugInteractions();
```

---

## 3️⃣ RISK SUMMARY IN PATIENT VIEW SCREEN

### Location
`lib/src/ui/screens/patient_view_screen.dart` or `patient_view_screen_modern.dart`

### Code to Add (in the build method)

```dart
// Add this import at the top
import '../../services/comprehensive_risk_assessment_service.dart';
import '../widgets/risk_assessment_widgets.dart';

// Then in your tab bar or main content
FutureBuilder<ComprehensiveRiskAssessment>(
  future: _loadRiskAssessment(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasData && snapshot.data != null) {
      final assessment = snapshot.data!;
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk Summary Card at the top
              RiskSummaryCard(
                assessment: assessment,
                onTap: () => _showDetailedRiskAssessment(assessment),
              ),
              const SizedBox(height: 16),
              
              // Critical Alerts
              if (assessment.riskFactors
                  .any((f) => f.riskLevel == RiskLevel.critical))
                CriticalAlertsWidget(
                  riskFactors: assessment.riskFactors,
                  onDismiss: () => setState(() {}),
                  onTap: (factor) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(factor.description),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (factor.recommendations.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recommendations:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...factor.recommendations.map(
                                    (rec) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(rec)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              
              // Rest of patient info...
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  },
)

// Helper method to load risk assessment
Future<ComprehensiveRiskAssessment> _loadRiskAssessment() async {
  final db = await ref.read(doctorDbProvider.future);
  
  final vitals = await db.getVitalSignsForPatient(widget.patient.id);
  final prescriptions = 
      await db.getActivePrescriptionsForPatient(widget.patient.id);
  final appointments = await db.getAppointmentsForPatient(widget.patient.id);
  final records = await db.getMedicalRecordsForPatient(widget.patient.id);
  
  return ComprehensiveRiskAssessmentService.assessPatient(
    patient: widget.patient,
    recentVitals: vitals.take(10).toList(),
    activePrescriptions: prescriptions,
    recentAppointments: appointments.take(20).toList(),
    recentAssessments: records.take(10).toList(),
  );
}

void _showDetailedRiskAssessment(ComprehensiveRiskAssessment assessment) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RiskAssessmentDetail(assessment: assessment),
      ),
    ),
  );
}
```

---

## 4️⃣ DASHBOARD CRITICAL ALERTS

### Location
`lib/src/ui/screens/clinical_dashboard.dart`

### Code to Add (in build method)

```dart
// In your dashboard content, add at the top
if (alertRisks.isNotEmpty)
  Padding(
    padding: const EdgeInsets.all(12.0),
    child: CriticalAlertsWidget(
      riskFactors: alertRisks,
      onDismiss: () {
        // Refresh dashboard
        _refreshKey.currentState?.show();
      },
      onTap: (factor) {
        // Navigate to patient or show details
        _showAlertDetails(factor);
      },
    ),
  ),

// Where alertRisks is calculated
List<RiskFactor> get alertRisks {
  final allRisks = <RiskFactor>[];
  
  for (final patient in _dashboardData?.patients ?? []) {
    final vitals = _dashboardData?.recentVitalsByPatient[patient.id] ?? [];
    final prescriptions = _dashboardData?.prescriptionsByPatient[patient.id] ?? [];
    final appointments = _dashboardData?.appointmentsByPatient[patient.id] ?? [];
    final records = _dashboardData?.recordsByPatient[patient.id] ?? [];
    
    final assessment = ComprehensiveRiskAssessmentService.assessPatient(
      patient: patient,
      recentVitals: vitals,
      activePrescriptions: prescriptions,
      recentAppointments: appointments,
      recentAssessments: records,
    );
    
    allRisks.addAll(
      assessment.riskFactors.where((f) => 
        f.riskLevel == RiskLevel.critical || 
        f.riskLevel == RiskLevel.high
      ),
    );
  }
  
  return allRisks.take(5).toList(); // Top 5 alerts
}
```

---

## 5️⃣ VITAL SIGNS ALERT INTEGRATION

### Location
`lib/src/ui/screens/vital_signs_screen.dart`

### Code to Add

```dart
// In the vital signs list item building
Widget _buildVitalSignItem(VitalSign vital) {
  final risks = _assessVitalSignsRisks(vital);
  
  return Card(
    color: risks.isNotEmpty
        ? Color(risks.first.riskLevel.colorValue).withOpacity(0.1)
        : null,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy HH:mm').format(vital.recordedAt),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (risks.isNotEmpty)
                Icon(
                  Icons.warning,
                  color: Color(risks.first.riskLevel.colorValue),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Vital values grid
          _buildVitalsGrid(vital),
          
          // Alerts if any
          if (risks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...risks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(risk.riskLevel.colorValue).withOpacity(0.1),
                    border: Border.all(
                      color: Color(risk.riskLevel.colorValue),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        risk.description,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (risk.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...risk.recommendations.take(1).map(
                              (rec) => Text(rec, style: const TextStyle(fontSize: 12)),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

List<RiskFactor> _assessVitalSignsRisks(VitalSign vital) {
  final risks = <RiskFactor>[];
  
  // Blood pressure check
  if (vital.systolicBp != null && vital.diastolicBp != null) {
    if (vital.systolicBp! >= 180 || vital.diastolicBp! >= 120) {
      risks.add(RiskFactor(
        category: 'vital_sign',
        riskLevel: RiskLevel.critical,
        description: 
          'Hypertensive Crisis: ${vital.systolicBp}/${vital.diastolicBp} mmHg',
        recommendations: ['Contact patient immediately'],
      ));
    }
  }
  
  // Add more vital sign checks as needed...
  
  return risks;
}
```

---

## 📋 CHECKLIST FOR INTEGRATION

- [ ] Add allergy checking to prescription screen
- [ ] Add drug interaction checking to prescription screen
- [ ] Add risk summary to patient view screen
- [ ] Add critical alerts to dashboard
- [ ] Add vital signs alerts to vital signs screen
- [ ] Test with sample data
- [ ] Deploy to production

---

## 🧪 TESTING THESE FEATURES

### Test Data Setup
1. Create patient with allergies: "Penicillin, Aspirin"
2. Create active prescriptions: "Lithium, Thiazide diuretic"
3. Add vital signs: BP 180/120, O2 88%
4. View patient and check for alerts

### Expected Results
- ✅ Allergy alert when trying to prescribe Amoxicillin
- ✅ Drug interaction alert for Lithium + Thiazide
- ✅ Risk summary showing CRITICAL alerts
- ✅ Dashboard showing patient in critical alerts section
- ✅ Vital signs showing red alert indicators

---

**Questions?** Refer to the service files for more details on available methods.
