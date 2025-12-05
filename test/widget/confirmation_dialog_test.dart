import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/confirmation_dialog.dart';

void main() {
  group('ConfirmationDialog', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Confirm Action',
              message: 'Are you sure?',
            ),
          ),
        ),
      );

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('displays default button text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Test',
              message: 'Test message',
            ),
          ),
        ),
      );

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('uses custom button text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Test',
              message: 'Test message',
              confirmText: 'Yes, do it',
              cancelText: 'No way',
            ),
          ),
        ),
      );

      expect(find.text('Yes, do it'), findsOneWidget);
      expect(find.text('No way'), findsOneWidget);
    });

    testWidgets('shows warning icon for destructive actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Delete',
              message: 'Delete item?',
              isDestructive: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows help icon for non-destructive actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Confirm',
              message: 'Confirm action?',
              isDestructive: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Custom',
              message: 'Custom message',
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('cancel button returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmationDialog(
                    title: 'Test',
                    message: 'Test',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirm button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmationDialog(
                    title: 'Test',
                    message: 'Test',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('static show method works', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmationDialog.show(
                  context: context,
                  title: 'Confirm',
                  message: 'Are you sure?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Title and button both say "Confirm" so check for both
      expect(find.text('Confirm'), findsNWidgets(2));
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('DeleteConfirmationDialog', () {
    testWidgets('displays item name and type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'John Doe',
              itemType: 'patient',
            ),
          ),
        ),
      );

      expect(find.text('Delete patient?'), findsOneWidget);
      expect(
          find.text('Are you sure you want to delete "John Doe"?'),
          findsOneWidget);
    });

    testWidgets('shows "This action cannot be undone" warning', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Test Item',
            ),
          ),
        ),
      );

      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('shows delete icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('shows additional message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(
              itemName: 'Patient',
              additionalMessage: 'All related records will be deleted.',
            ),
          ),
        ),
      );

      expect(
          find.text('All related records will be deleted.'), findsOneWidget);
    });

    testWidgets('static show method works', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await DeleteConfirmationDialog.show(
                  context: context,
                  itemName: 'Patient',
                  itemType: 'patient',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('LogoutConfirmationDialog', () {
    testWidgets('displays logout title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      // Title and button both say "Log Out"
      expect(find.text('Log Out'), findsNWidgets(2));
      expect(find.textContaining('log out'), findsWidgets);
    });

    testWidgets('shows logout icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('has correct button labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      expect(find.text('Log Out'), findsWidgets); // Title and button
      expect(find.text('Stay Signed In'), findsOneWidget);
    });

    testWidgets('static show method works', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await LogoutConfirmationDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stay Signed In'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('DiscardChangesDialog', () {
    testWidgets('displays discard title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscardChangesDialog(),
          ),
        ),
      );

      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(find.textContaining('unsaved changes'), findsOneWidget);
    });

    testWidgets('shows edit_off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscardChangesDialog(),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit_off), findsOneWidget);
    });

    testWidgets('has correct button labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscardChangesDialog(),
          ),
        ),
      );

      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('static show method works', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await DiscardChangesDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('SendConfirmationDialog', () {
    testWidgets('displays message type and recipient count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SendConfirmationDialog(
              recipientCount: 5,
              messageType: 'SMS',
            ),
          ),
        ),
      );

      expect(find.text('Send SMS?'), findsOneWidget);
      expect(find.textContaining('5 recipients'), findsOneWidget);
    });

    testWidgets('handles single recipient correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SendConfirmationDialog(
              recipientCount: 1,
              messageType: 'email',
            ),
          ),
        ),
      );

      expect(find.textContaining('1 recipient'), findsOneWidget);
    });

    testWidgets('shows send icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SendConfirmationDialog(
              recipientCount: 3,
              messageType: 'notification',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('static show method works', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await SendConfirmationDialog.show(
                  context: context,
                  recipientCount: 10,
                  messageType: 'reminder',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
