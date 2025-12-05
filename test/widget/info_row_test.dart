import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/info_row.dart';

void main() {
  group('InfoRow', () {
    testWidgets('displays label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Email',
              value: 'test@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Email',
              value: 'test@example.com',
              icon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('shows copy button when copyable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Email',
              value: 'test@example.com',
              copyable: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('copies value when copy button tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Email',
              value: 'test@example.com',
              copyable: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      // Check snackbar appears
      expect(find.text('Email copied'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Phone',
              value: '123-456-7890',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('123-456-7890'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays action icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Phone',
              value: '123-456-7890',
              actionIcon: Icons.call,
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.call), findsOneWidget);
    });

    testWidgets('calls onAction when action button tapped', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Phone',
              value: '123-456-7890',
              actionIcon: Icons.call,
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.call));
      await tester.pump();

      expect(actionCalled, isTrue);
    });
  });

  group('InfoRowCompact', () {
    testWidgets('displays label and value inline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowCompact(
              label: 'Status',
              value: 'Active',
            ),
          ),
        ),
      );

      // RichText contains both label and value
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('uses custom separator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowCompact(
              label: 'Age',
              value: '25',
              separator: ' -',
            ),
          ),
        ),
      );

      // The widget renders with RichText
      expect(find.byType(RichText), findsOneWidget);
    });
  });

  group('InfoColumn', () {
    testWidgets('displays value prominently above label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoColumn(
              label: 'Total',
              value: '\$1,234',
            ),
          ),
        ),
      );

      expect(find.text('\$1,234'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoColumn(
              label: 'Revenue',
              value: '\$5,000',
              icon: Icons.attach_money,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoColumn(
              label: 'Count',
              value: '42',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('42'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('InfoList', () {
    testWidgets('displays all info rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoList(
              items: [
                InfoRow(label: 'Name', value: 'John'),
                InfoRow(label: 'Age', value: '30'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('shows dividers by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoList(
              items: [
                InfoRow(label: 'A', value: '1'),
                InfoRow(label: 'B', value: '2'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('hides dividers when showDividers is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoList(
              showDividers: false,
              items: [
                InfoRow(label: 'A', value: '1'),
                InfoRow(label: 'B', value: '2'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNothing);
    });
  });

  group('InfoGrid', () {
    testWidgets('displays all items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoGrid(
              items: {
                'Name': 'John Doe',
                'Age': '30',
                'City': 'New York',
              },
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
    });
  });

  group('InfoBadge', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBadge(label: 'Active'),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBadge(
              label: 'Verified',
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('uses custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBadge(
              label: 'Error',
              color: Colors.red,
            ),
          ),
        ),
      );

      // Badge renders with color
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoBadge(
              label: 'Tap Me',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
