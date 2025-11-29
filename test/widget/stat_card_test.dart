import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('displays title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total Patients',
              value: '1,234',
            ),
          ),
        ),
      );

      expect(find.text('Total Patients'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Patients',
              value: '100',
              icon: Icons.people,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: '\$50,000',
              subtitle: 'This month',
            ),
          ),
        ),
      );

      expect(find.text('This month'), findsOneWidget);
    });

    testWidgets('displays trend indicator when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Growth',
              value: '25%',
              trend: StatTrend.up,
              trendValue: '+5%',
            ),
          ),
        ),
      );

      expect(find.text('+5%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays down trend correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Cancellations',
              value: '5',
              trend: StatTrend.down,
              trendValue: '-2',
            ),
          ),
        ),
      );

      expect(find.text('-2'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('displays neutral trend correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Status',
              value: 'Stable',
              trend: StatTrend.neutral,
              trendValue: '0%',
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Patients',
              value: '100',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses custom icon color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Urgent',
              value: '3',
              icon: Icons.warning,
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(icon.color, Colors.red);
    });
  });

  group('StatCardCompact', () {
    testWidgets('displays title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Today',
              value: '12',
            ),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Appointments',
              value: '8',
              icon: Icons.calendar_today,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows chevron when tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Details',
              value: 'View',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides chevron when not tappable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Info',
              value: '100',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Tap me',
              value: '!',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCardCompact));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('StatCardHero', () {
    testWidgets('displays title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Monthly Revenue',
              value: '\$125,000',
            ),
          ),
        ),
      );

      expect(find.text('Monthly Revenue'), findsOneWidget);
      expect(find.text('\$125,000'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Revenue',
              value: '\$100K',
              icon: Icons.attach_money,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('displays description when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Performance',
              value: '95%',
              description: 'Above target by 10%',
            ),
          ),
        ),
      );

      expect(find.text('Above target by 10%'), findsOneWidget);
    });

    testWidgets('displays trend indicator when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Growth',
              value: '150%',
              trend: StatTrend.up,
              trendValue: '+25%',
            ),
          ),
        ),
      );

      expect(find.text('+25%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Tap me',
              value: 'Hero',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCardHero));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses custom gradient when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Custom',
              value: 'Gradient',
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
              ),
            ),
          ),
        ),
      );

      // Just verify it builds without error
      expect(find.byType(StatCardHero), findsOneWidget);
    });
  });

  group('StatCardRow', () {
    testWidgets('displays multiple cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardRow(
              children: [
                StatCardCompact(title: 'A', value: '1'),
                StatCardCompact(title: 'B', value: '2'),
                StatCardCompact(title: 'C', value: '3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('spaces cards with custom spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardRow(
              spacing: 16,
              children: [
                StatCardCompact(title: 'X', value: '1'),
                StatCardCompact(title: 'Y', value: '2'),
              ],
            ),
          ),
        ),
      );

      // Verify both cards are rendered
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
    });
  });

  group('StatTrend', () {
    test('has all expected values', () {
      expect(StatTrend.values, contains(StatTrend.up));
      expect(StatTrend.values, contains(StatTrend.down));
      expect(StatTrend.values, contains(StatTrend.neutral));
      expect(StatTrend.values.length, 3);
    });
  });
}
