import 'package:doctor_app/src/core/widgets/loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              isLoading: true,
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              isLoading: true,
              loadingChild: const Text('Loading...'),
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('disables button when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              isLoading: true,
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('disables button when disabled flag is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              disabled: true,
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('automatically manages loading state during async operation', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                completed = true;
              },
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(LoadingButton));
      await tester.pump();

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for operation to complete
      await tester.pump(const Duration(milliseconds: 150));

      // Should show child again
      expect(find.text('Submit'), findsOneWidget);
      expect(completed, isTrue);
    });
  });

  group('LoadingTextButton', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingTextButton(
              onPressed: () async {},
              child: const Text('Cancel'),
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingTextButton(
              onPressed: () async {},
              isLoading: true,
              child: const Text('Cancel'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingOutlinedButton', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingOutlinedButton(
              onPressed: () async {},
              child: const Text('Reset'),
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingOutlinedButton(
              onPressed: () async {},
              isLoading: true,
              child: const Text('Reset'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingIconButton', () {
    testWidgets('shows icon when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIconButton(
              onPressed: () async {},
              icon: const Icon(Icons.save),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIconButton(
              onPressed: () async {},
              isLoading: true,
              icon: const Icon(Icons.save),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.save), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIconButton(
              onPressed: () async {},
              icon: const Icon(Icons.save),
              tooltip: 'Save',
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Save');
    });

    testWidgets('disables button when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIconButton(
              onPressed: () async {},
              disabled: true,
              icon: const Icon(Icons.save),
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });
  });
}
