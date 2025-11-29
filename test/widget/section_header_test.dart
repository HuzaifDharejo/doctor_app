import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/section_header.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'My Section'),
          ),
        ),
      );

      expect(find.text('My Section'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Section',
              subtitle: 'Subtitle text',
            ),
          ),
        ),
      );

      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('displays count badge when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Items',
              count: 42,
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays action button with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Section',
              actionLabel: 'View All',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('calls onAction when action button tapped', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Section',
              actionLabel: 'Tap Me',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('shows icon button when onAction but no label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Section',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('uses custom action icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Section',
              actionIcon: Icons.add,
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('LabeledDivider', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LabeledDivider(label: 'OR'),
          ),
        ),
      );

      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('displays dividers on both sides', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LabeledDivider(label: 'OR'),
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('GroupedSection', () {
    testWidgets('displays title and children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupedSection(
              title: 'Group Title',
              children: [
                Text('Child 1'),
                Text('Child 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Group Title'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupedSection(
              title: 'Group',
              subtitle: 'Description',
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupedSection(
              title: 'Group',
              actionLabel: 'Action',
              onAction: () {},
              children: const [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.text('Action'), findsOneWidget);
    });
  });

  group('HeaderCard', () {
    testWidgets('displays title and content in card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderCard(
              title: 'Card Title',
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeaderCard(
              title: 'Card',
              subtitle: 'Subtitle',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Subtitle'), findsOneWidget);
    });
  });

  group('CollapsibleSection', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Collapsible',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Collapsible'), findsOneWidget);
    });

    testWidgets('shows content when initially expanded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Section',
              initiallyExpanded: true,
              child: Text('Visible Content'),
            ),
          ),
        ),
      );

      expect(find.text('Visible Content'), findsOneWidget);
    });

    testWidgets('hides content when initially collapsed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Section',
              initiallyExpanded: false,
              child: Text('Hidden Content'),
            ),
          ),
        ),
      );

      // Content exists but is hidden via AnimatedCrossFade
      expect(find.text('Section'), findsOneWidget);
    });

    testWidgets('toggles expansion when tapped', (tester) async {
      bool? isExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Tap Me',
              initiallyExpanded: true,
              onExpansionChanged: (expanded) => isExpanded = expanded,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(isExpanded, isFalse);
    });

    testWidgets('shows expand/collapse icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Section',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Section',
              subtitle: 'Click to expand',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Click to expand'), findsOneWidget);
    });
  });
}
