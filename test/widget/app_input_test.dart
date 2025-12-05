import 'package:doctor_app/src/core/components/app_input.dart';
import 'package:doctor_app/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppInput', () {
    Widget buildTestWidget({
      required Widget child,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Test Label',
          controller: TextEditingController(),
        ),
      ));

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Test',
          hint: 'Enter something',
          controller: TextEditingController(),
        ),
      ));

      expect(find.text('Enter something'), findsOneWidget);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Test',
          prefixIcon: Icons.person,
          controller: TextEditingController(),
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with suffix icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Test',
          suffixIcon: Icons.visibility,
          controller: TextEditingController(),
        ),
      ));

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Test',
          controller: controller,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(controller.text, 'Hello World');
    });

    testWidgets('shows validation error', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: Form(
          autovalidateMode: AutovalidateMode.always,
          child: AppInput(
            label: 'Required Field',
            controller: TextEditingController(),
            validator: (value) => value?.isEmpty == true ? 'This field is required' : null,
          ),
        ),
      ));

      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Password',
          controller: TextEditingController(text: 'secret'),
          obscureText: true,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('renders multiline when maxLines > 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Description',
          controller: TextEditingController(),
          maxLines: 5,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 5);
    });

    testWidgets('disabled state prevents input', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(buildTestWidget(
        child: AppInput(
          label: 'Disabled',
          controller: controller,
          enabled: false,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    group('AppInput.email', () {
      testWidgets('renders with email keyboard type', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.email(
            controller: TextEditingController(),
          ),
        ));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.emailAddress);
      });

      testWidgets('has email icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.email(
            controller: TextEditingController(),
          ),
        ));

        expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      });
    });

    group('AppInput.phone', () {
      testWidgets('renders with phone keyboard type', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.phone(
            controller: TextEditingController(),
          ),
        ));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.phone);
      });

      testWidgets('has phone icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.phone(
            controller: TextEditingController(),
          ),
        ));

        expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      });
    });

    group('AppInput.name', () {
      testWidgets('renders with name keyboard type', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.name(
            controller: TextEditingController(),
          ),
        ));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.name);
      });

      testWidgets('has person icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: AppInput.name(
            controller: TextEditingController(),
          ),
        ));

        expect(find.byIcon(Icons.person_outlined), findsOneWidget);
      });
    });
  });
}
