import 'package:doctor_app/src/core/widgets/error_display.dart';
import 'package:doctor_app/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorDisplay', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('displays message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ErrorDisplay(message: 'Something went wrong'),
      ),);

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ErrorDisplay(
          title: 'Error Title',
          message: 'Error message',
        ),
      ),);

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ErrorDisplay(
          message: 'Custom icon error',
          icon: Icons.cloud_off,
        ),
      ),);

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        ErrorDisplay(
          message: 'Retryable error',
          onRetry: () {},
        ),
      ),);

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ErrorDisplay(message: 'No retry error'),
      ),);

      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('triggers onRetry callback when retry button tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(buildTestWidget(
        ErrorDisplay(
          message: 'Retryable error',
          onRetry: () => retried = true,
        ),
      ),);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('uses custom retry label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        ErrorDisplay(
          message: 'Custom label error',
          onRetry: () {},
          retryLabel: 'Reload',
        ),
      ),);

      expect(find.text('Reload'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });

    group('factory constructors', () {
      testWidgets('network() shows connection error', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.network(),
        ),);

        expect(find.text('Connection Error'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      });

      testWidgets('loadFailed() shows load error', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.loadFailed(),
        ),);

        expect(find.text('Failed to Load'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('loadFailed() accepts custom message', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.loadFailed(message: 'Custom load error'),
        ),);

        expect(find.text('Custom load error'), findsOneWidget);
      });

      testWidgets('empty() shows empty state', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.empty(message: 'No items found'),
        ),);

        expect(find.text('Nothing Here'), findsOneWidget);
        expect(find.text('No items found'), findsOneWidget);
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      });

      testWidgets('empty() accepts custom title and icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.empty(
            title: 'No Patients',
            message: 'Add your first patient',
            icon: Icons.person_add_outlined,
          ),
        ),);

        expect(find.text('No Patients'), findsOneWidget);
        expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
      });
    });

    group('compact mode', () {
      testWidgets('inline() renders compact version', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.inline(message: 'Inline error'),
        ),);

        expect(find.text('Inline error'), findsOneWidget);
        // Should have error icon
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('compact shows retry button when provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ErrorDisplay.inline(
            message: 'Inline retry error',
            onRetry: () {},
          ),
        ),);

        expect(find.text('Try Again'), findsOneWidget);
      });
    });
  });

  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: Text('Child Widget'),
          ),
        ),
      );

      expect(find.text('Child Widget'), findsOneWidget);
    });

    testWidgets('uses custom fallback when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            fallback: (error, reset) => Text('Custom fallback: $error'),
            child: const Text('Normal child'),
          ),
        ),
      );

      // Initially shows child
      expect(find.text('Normal child'), findsOneWidget);
    });
  });

  group('Snackbar Extensions', () {
    testWidgets('showErrorSnackBar displays error snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.showErrorSnackBar('Error message'),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showSuccessSnackBar displays success snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.showSuccessSnackBar('Success message'),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showInfoSnackBar displays info snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.showInfoSnackBar('Info message'),
                child: const Text('Show Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
