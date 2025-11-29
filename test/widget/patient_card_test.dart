import 'package:doctor_app/src/db/doctor_db.dart';
import 'package:doctor_app/src/theme/app_theme.dart';
import 'package:doctor_app/src/ui/widgets/patient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientCard', () {
    late Patient testPatient;

    setUp(() {
      testPatient = Patient(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: DateTime(1990, 5, 15),
        phone: '1234567890',
        email: 'john.doe@example.com',
        address: '123 Main St',
        medicalHistory: 'Diabetes,Hypertension',
        tags: 'regular,vip',
        riskLevel: 2,
        createdAt: DateTime.now(),
      );
    });

    Widget buildTestWidget({
      required Patient patient,
      DateTime? lastVisit,
      DateTime? nextAppointment,
      int index = 0,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PatientCard(
              patient: patient,
              lastVisit: lastVisit,
              nextAppointment: nextAppointment,
              index: index,
            ),
          ),
        ),
      );
    }

    // Helper to pump widget with animation
    Future<void> pumpPatientCard(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(widget);
      // Pump enough for the staggered animation to complete
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('displays patient name correctly', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays phone number when lastVisit and nextAppointment are null', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('displays medical history tags', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      // Medical history is 'Diabetes,Hypertension' - should show as chips
      expect(find.text('Diabetes'), findsOneWidget);
      expect(find.text('Hypertension'), findsOneWidget);
    });

    testWidgets('shows low risk indicator for low risk patients', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      // Risk level 2 is Low - should show check icon and 'Low' text
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('shows medium risk indicator for medium risk patients', (tester) async {
      final mediumRiskPatient = Patient(
        id: 2,
        firstName: 'Jane',
        lastName: 'Smith',
        dateOfBirth: DateTime(1985, 3, 20),
        phone: '9876543210',
        email: '',
        address: '',
        medicalHistory: '',
        tags: '',
        riskLevel: 3, // Medium risk
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: mediumRiskPatient));

      // Risk level 3 is Medium - should show warning icon and 'Medium' text
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('shows high risk indicator for high risk patients', (tester) async {
      final highRiskPatient = Patient(
        id: 2,
        firstName: 'Jane',
        lastName: 'Smith',
        dateOfBirth: DateTime(1985, 3, 20),
        phone: '9876543210',
        email: '',
        address: '',
        medicalHistory: '',
        tags: '',
        riskLevel: 5, // High risk
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: highRiskPatient));

      // Risk level 5 is High - should show error icon and 'High' text
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('displays last visit date when provided', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      await pumpPatientCard(tester, buildTestWidget(
        patient: testPatient,
        lastVisit: yesterday,
      ),);

      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('displays next appointment when provided', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      await pumpPatientCard(tester, buildTestWidget(
        patient: testPatient,
        nextAppointment: tomorrow,
      ),);

      expect(find.byIcon(Icons.event_rounded), findsOneWidget);
    });

    testWidgets('shows call button for patient with phone', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    });

    testWidgets('shows message button for patient with phone', (tester) async {
      await pumpPatientCard(tester, buildTestWidget(patient: testPatient));

      expect(find.byIcon(Icons.message_rounded), findsOneWidget);
    });

    testWidgets('hides quick action buttons for patient without phone', (tester) async {
      final patientNoPhone = Patient(
        id: 3,
        firstName: 'Bob',
        lastName: 'Wilson',
        dateOfBirth: DateTime(1995, 8, 10),
        phone: '',
        email: '',
        address: '',
        medicalHistory: '',
        tags: '',
        riskLevel: 0,
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: patientNoPhone));

      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsNothing);
      expect(find.byIcon(Icons.message_rounded), findsNothing);
      // Should show arrow instead
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('handles patient with empty medical history', (tester) async {
      final patientNoHistory = Patient(
        id: 4,
        firstName: 'Alice',
        lastName: 'Brown',
        dateOfBirth: DateTime(1995, 8, 10),
        phone: '1112223333',
        email: '',
        address: '',
        medicalHistory: '',
        tags: '',
        riskLevel: 1,
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: patientNoHistory));

      expect(find.text('Alice Brown'), findsOneWidget);
      // Should not crash with empty medical history
    });

    testWidgets('truncates long medical history tags', (tester) async {
      final patientLongHistory = Patient(
        id: 5,
        firstName: 'Charlie',
        lastName: 'Davis',
        dateOfBirth: DateTime(1988, 12),
        phone: '5555555555',
        email: '',
        address: '',
        medicalHistory: 'VeryLongMedicalConditionName,AnotherLongCondition',
        tags: '',
        riskLevel: 0,
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: patientLongHistory));

      expect(find.text('Charlie Davis'), findsOneWidget);
      // Long tags should be truncated with ellipsis
      expect(find.textContaining('...'), findsWidgets);
    });

    testWidgets('shows No phone text when phone is empty and no lastVisit/nextAppointment', (tester) async {
      final patientNoPhone = Patient(
        id: 6,
        firstName: 'Eve',
        lastName: 'Taylor',
        dateOfBirth: DateTime(1992, 6, 20),
        phone: '',
        email: '',
        address: '',
        medicalHistory: '',
        tags: '',
        riskLevel: 1,
        createdAt: DateTime.now(),
      );

      await pumpPatientCard(tester, buildTestWidget(patient: patientNoPhone));

      expect(find.text('No phone'), findsOneWidget);
    });
  });
}
