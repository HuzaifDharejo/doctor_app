import 'package:doctor_app/src/core/components/app_button.dart';
import 'package:doctor_app/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton', () {
    Widget buildTestWidget({required Widget child}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('primary button displays label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Primary Button',
          onPressed: () {},
        ),
      ));

      expect(find.text('Primary Button'), findsOneWidget);
    });

    testWidgets('primary button triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Click Me',
          onPressed: () => pressed = true,
        ),
      ));

      await tester.tap(find.text('Click Me'));
      expect(pressed, true);
    });

    testWidgets('secondary button displays label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.secondary(
          label: 'Secondary Button',
          onPressed: () {},
        ),
      ));

      expect(find.text('Secondary Button'), findsOneWidget);
    });

    testWidgets('tertiary button displays label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.tertiary(
          label: 'Tertiary Button',
          onPressed: () {},
        ),
      ));

      expect(find.text('Tertiary Button'), findsOneWidget);
    });

    testWidgets('danger button displays label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.danger(
          label: 'Danger Button',
          onPressed: () {},
        ),
      ));

      expect(find.text('Danger Button'), findsOneWidget);
    });

    testWidgets('button displays icon when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'With Icon',
          icon: Icons.add,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('disabled button does not trigger onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Disabled',
          onPressed: null,
        ),
      ));

      await tester.tap(find.text('Disabled'));
      expect(pressed, false);
    });

    testWidgets('loading state shows loading indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Loading',
          isLoading: true,
          onPressed: () {},
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loading button does not trigger onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Loading',
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      ));

      await tester.tap(find.byType(AppButton));
      expect(pressed, false);
    });

    testWidgets('fullWidth button expands to container width', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: SizedBox(
          width: 300,
          child: AppButton.primary(
            label: 'Full Width',
            fullWidth: true,
            onPressed: () {},
          ),
        ),
      ));

      final buttonFinder = find.byType(ElevatedButton);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.width, 300);
    });

    testWidgets('small button has smaller height', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Small',
          size: AppButtonSize.small,
          onPressed: () {},
        ),
      ));

      final buttonFinder = find.byType(ElevatedButton);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, lessThan(50));
    });

    testWidgets('large button has larger height', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: AppButton.primary(
          label: 'Large',
          size: AppButtonSize.large,
          onPressed: () {},
        ),
      ));

      final buttonFinder = find.byType(ElevatedButton);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(48));
    });
  });
}
