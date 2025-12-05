import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/form_field_wrapper.dart';

void main() {
  group('FormFieldWrapper', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          child: TextField(),
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays label when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          label: 'Test Label',
          child: TextField(),
        ),
      ));

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('shows required indicator when isRequired is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          label: 'Required Field',
          isRequired: true,
          child: TextField(),
        ),
      ));

      expect(find.text('Required Field'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('shows helper text when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          helperText: 'This is helper text',
          child: TextField(),
        ),
      ));

      expect(find.text('This is helper text'), findsOneWidget);
    });

    testWidgets('shows error text with error icon when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          errorText: 'This field has an error',
          child: TextField(),
        ),
      ));

      expect(find.text('This field has an error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error text takes precedence over helper text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          helperText: 'Helper text',
          errorText: 'Error text',
          child: TextField(),
        ),
      ));

      expect(find.text('Error text'), findsOneWidget);
      expect(find.text('Helper text'), findsNothing);
    });

    testWidgets('shows info tooltip when showInfoTooltip is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          label: 'Field with Info',
          showInfoTooltip: true,
          infoTooltipMessage: 'This is tooltip message',
          child: TextField(),
        ),
      ));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not show required indicator when isRequired is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          label: 'Optional Field',
          isRequired: false,
          child: TextField(),
        ),
      ));

      expect(find.text('Optional Field'), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper(
          padding: const EdgeInsets.all(24),
          child: Container(key: const Key('child')),
        ),
      ));

      final padding = tester.widget<Padding>(find.ancestor(
        of: find.byKey(const Key('child')),
        matching: find.byType(Padding),
      ).first);
      expect(padding.padding, const EdgeInsets.all(24));
    });

    testWidgets('applies semantic label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const FormFieldWrapper(
          semanticLabel: 'Email input field',
          child: TextField(),
        ),
      ));

      expect(
        find.bySemanticsLabel('Email input field'),
        findsOneWidget,
      );
    });
  });

  group('FormFieldWrapper.textField', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('creates text field with controller', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.textField(
          controller: controller,
          label: 'Name',
          hint: 'Enter name',
        ),
      ));

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('text field calls onChanged', (tester) async {
      final controller = TextEditingController();
      String? changedValue;
      
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.textField(
          controller: controller,
          onChanged: (value) => changedValue = value,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(changedValue, 'test input');
    });

    testWidgets('text field shows hint text', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.textField(
          controller: controller,
          hint: 'Enter your email',
        ),
      ));

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('disabled text field is not editable', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.textField(
          controller: controller,
          enabled: false,
        ),
      ));

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, false);
    });
  });

  group('FormFieldWrapper.dropdown', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('creates dropdown with items', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.dropdown<String>(
          value: 'option1',
          items: const [
            DropdownMenuItem(value: 'option1', child: Text('Option 1')),
            DropdownMenuItem(value: 'option2', child: Text('Option 2')),
          ],
          onChanged: (_) {},
          label: 'Select Option',
        ),
      ));

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Select Option'), findsOneWidget);
    });

    testWidgets('dropdown calls onChanged when selection changes', (tester) async {
      String? selectedValue = 'option1';
      
      await tester.pumpWidget(buildTestWidget(
        StatefulBuilder(
          builder: (context, setState) => FormFieldWrapper.dropdown<String>(
            value: selectedValue,
            items: const [
              DropdownMenuItem(value: 'option1', child: Text('Option 1')),
              DropdownMenuItem(value: 'option2', child: Text('Option 2')),
            ],
            onChanged: (value) {
              setState(() => selectedValue = value);
            },
          ),
        ),
      ));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Option 2').last);
      await tester.pumpAndSettle();
      
      expect(selectedValue, 'option2');
    });
  });

  group('FormFieldWrapper.checkbox', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('creates checkbox with title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.checkbox(
          value: false,
          onChanged: (_) {},
          title: 'Accept Terms',
        ),
      ));

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Accept Terms'), findsOneWidget);
    });

    testWidgets('checkbox calls onChanged when tapped', (tester) async {
      bool value = false;
      
      await tester.pumpWidget(buildTestWidget(
        StatefulBuilder(
          builder: (context, setState) => FormFieldWrapper.checkbox(
            value: value,
            onChanged: (newValue) {
              setState(() => value = newValue!);
            },
            title: 'Accept',
          ),
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      
      expect(value, true);
    });

    testWidgets('checkbox shows subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.checkbox(
          value: false,
          onChanged: (_) {},
          title: 'Enable Notifications',
          subtitle: 'Receive updates via email',
        ),
      ));

      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Receive updates via email'), findsOneWidget);
    });
  });

  group('FormFieldWrapper.switchField', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('creates switch with title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.switchField(
          value: false,
          onChanged: (_) {},
          title: 'Dark Mode',
        ),
      ));

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('switch calls onChanged when toggled', (tester) async {
      bool value = false;
      
      await tester.pumpWidget(buildTestWidget(
        StatefulBuilder(
          builder: (context, setState) => FormFieldWrapper.switchField(
            value: value,
            onChanged: (newValue) {
              setState(() => value = newValue);
            },
            title: 'Toggle',
          ),
        ),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      
      expect(value, true);
    });

    testWidgets('switch shows subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        FormFieldWrapper.switchField(
          value: true,
          onChanged: (_) {},
          title: 'Auto Sync',
          subtitle: 'Sync data automatically',
        ),
      ));

      expect(find.text('Auto Sync'), findsOneWidget);
      expect(find.text('Sync data automatically'), findsOneWidget);
    });
  });

  group('FormFieldWrapper dark mode', () {
    Widget buildDarkTestWidget(Widget child) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(buildDarkTestWidget(
        const FormFieldWrapper(
          label: 'Dark Mode Field',
          helperText: 'Helper in dark mode',
          child: TextField(),
        ),
      ));

      expect(find.text('Dark Mode Field'), findsOneWidget);
      expect(find.text('Helper in dark mode'), findsOneWidget);
    });

    testWidgets('error text renders in dark mode', (tester) async {
      await tester.pumpWidget(buildDarkTestWidget(
        const FormFieldWrapper(
          label: 'Error Field',
          errorText: 'This is an error',
          child: TextField(),
        ),
      ));

      expect(find.text('This is an error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
