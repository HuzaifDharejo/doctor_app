/// Widget tests for Dashboard components
/// 
/// Tests the dashboard's StatCard, summary cards, and quick actions
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/stat_card.dart';

void main() {
  group('Dashboard StatCard Tests', () {
    testWidgets('renders with title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Appointments',
              value: '12',
            ),
          ),
        ),
      );

      expect(find.text('Appointments'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Patients',
              value: '50',
              icon: Icons.people,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: '\$1,500',
              subtitle: 'Today',
            ),
          ),
        ),
      );

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('\$1,500'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Appointments',
              value: '5',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders with trend indicator (up)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Patients',
              value: '100',
              trend: StatTrend.up,
              trendValue: '+15%',
            ),
          ),
        ),
      );

      expect(find.text('+15%'), findsOneWidget);
    });

    testWidgets('renders with trend indicator (down)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Pending',
              value: '5',
              trend: StatTrend.down,
              trendValue: '-10%',
            ),
          ),
        ),
      );

      expect(find.text('-10%'), findsOneWidget);
    });

    testWidgets('renders with custom icon color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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

      final statCard = find.byType(StatCard);
      expect(statCard, findsOneWidget);
    });

    testWidgets('renders StatCardCompact', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'Compact',
              value: '10',
            ),
          ),
        ),
      );

      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders StatCardCompact with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardCompact(
              title: 'With Icon',
              value: '25',
              icon: Icons.person,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('With Icon'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders StatCardHero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCardHero(
              title: 'Hero Card',
              value: '100',
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.purpleAccent],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hero Card'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });
  });

  group('Dashboard Quick Actions', () {
    testWidgets('quick action button renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestQuickActionButton(
              icon: Icons.add,
              label: 'New Patient',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Patient'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('quick action button handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestQuickActionButton(
              icon: Icons.calendar_today,
              label: 'Schedule',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(_TestQuickActionButton));
      expect(tapped, isTrue);
    });

    testWidgets('multiple quick actions in row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TestQuickActionButton(
                  icon: Icons.person_add,
                  label: 'Patient',
                  onTap: () {},
                ),
                _TestQuickActionButton(
                  icon: Icons.calendar_month,
                  label: 'Appointment',
                  onTap: () {},
                ),
                _TestQuickActionButton(
                  icon: Icons.medication,
                  label: 'Prescription',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Appointment'), findsOneWidget);
      expect(find.text('Prescription'), findsOneWidget);
    });
  });

  group('Dashboard Summary Row', () {
    testWidgets('renders multiple stat cards in row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                Expanded(child: StatCard(title: 'Total', value: '100')),
                SizedBox(width: 8),
                Expanded(child: StatCard(title: 'Completed', value: '80')),
                SizedBox(width: 8),
                Expanded(child: StatCard(title: 'Pending', value: '20')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatCard), findsNWidgets(3));
      expect(find.text('100'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('stat cards wrap in grid on small screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.all(16),
              children: const [
                StatCard(title: 'A', value: '1'),
                StatCard(title: 'B', value: '2'),
                StatCard(title: 'C', value: '3'),
                StatCard(title: 'D', value: '4'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatCard), findsNWidgets(4));
    });
  });

  group('Dashboard Alert Banner', () {
    testWidgets('renders alert banner with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestAlertBanner(
              message: '3 overdue follow-ups',
              icon: Icons.warning,
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('3 overdue follow-ups'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('alert banner can be dismissed', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestAlertBanner(
              message: 'Alert',
              icon: Icons.info,
              color: Colors.blue,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('alert banner has action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestAlertBanner(
              message: 'New updates available',
              icon: Icons.update,
              color: Colors.green,
              actionLabel: 'View',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('View'));
      expect(actionTapped, isTrue);
    });
  });

  group('Dashboard Revenue Card', () {
    testWidgets('displays today revenue', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: "Today's Revenue",
              value: '\$2,500',
              icon: Icons.attach_money,
            ),
          ),
        ),
      );

      expect(find.text("Today's Revenue"), findsOneWidget);
      expect(find.text('\$2,500'), findsOneWidget);
    });

    testWidgets('displays pending payments', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Pending Payments',
              value: '\$1,200',
              icon: Icons.pending_actions,
            ),
          ),
        ),
      );

      expect(find.text('Pending Payments'), findsOneWidget);
      expect(find.text('\$1,200'), findsOneWidget);
    });
  });

  group('Dashboard Follow-up Section', () {
    testWidgets('displays follow-up count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Follow-ups Due',
              value: '5',
              icon: Icons.event_repeat,
            ),
          ),
        ),
      );

      expect(find.text('Follow-ups Due'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays overdue follow-ups with subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Overdue',
              value: '3',
              icon: Icons.warning_amber,
              subtitle: 'Needs attention',
            ),
          ),
        ),
      );

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
    });
  });
}

/// Test helper widget for quick action buttons
class _TestQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TestQuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Test helper widget for alert banners
class _TestAlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TestAlertBanner({
    required this.message,
    required this.icon,
    required this.color,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
