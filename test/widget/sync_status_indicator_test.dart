import 'package:doctor_app/src/core/utils/connectivity.dart';
import 'package:doctor_app/src/core/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatusIndicator', () {
    testWidgets('shows connected status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(status: ConnectivityStatus.connected),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows offline status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(status: ConnectivityStatus.offline),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('shows unknown status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(status: ConnectivityStatus.unknown),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.text('Checking...'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              status: ConnectivityStatus.connected,
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.text('Synced'), findsNothing);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              status: ConnectivityStatus.connected,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SyncStatusIndicator));
      expect(tapped, isTrue);
    });
  });

  group('SyncProgressIndicator', () {
    testWidgets('shows message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncProgressIndicator(message: 'Syncing data...'),
          ),
        ),
      );

      expect(find.text('Syncing data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows indeterminate progress by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncProgressIndicator(message: 'Loading'),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, isNull); // Indeterminate has null value
    });

    testWidgets('shows determinate progress when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncProgressIndicator(
              message: 'Uploading',
              progress: 0.5,
              isIndeterminate: false,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.5);
    });
  });

  group('OfflineBanner', () {
    testWidgets('shows default message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      expect(find.text('You are currently offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('shows custom message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(message: 'No internet connection'),
          ),
        ),
      );

      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              actionLabel: 'Retry',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(actionCalled, isTrue);
    });

    testWidgets('hides action button when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('ConnectivityAwareScaffold', () {
    testWidgets('shows offline banner when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectivityAwareScaffold(
            status: ConnectivityStatus.offline,
            body: Text('Content'),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('hides offline banner when connected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectivityAwareScaffold(
            status: ConnectivityStatus.connected,
            body: Text('Content'),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('respects showOfflineBanner flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectivityAwareScaffold(
            status: ConnectivityStatus.offline,
            showOfflineBanner: false,
            body: Text('Content'),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsNothing);
    });

    testWidgets('shows custom offline message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectivityAwareScaffold(
            status: ConnectivityStatus.offline,
            offlineMessage: 'Custom offline message',
            body: Text('Content'),
          ),
        ),
      );

      expect(find.text('Custom offline message'), findsOneWidget);
    });
  });

  group('PendingSyncBadge', () {
    testWidgets('shows count when greater than 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(count: 5),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('hides when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(count: 0),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows 99+ for counts over 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(count: 150),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('wraps child widget correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(
              count: 3,
              child: Icon(Icons.sync),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows only child when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(
              count: 0,
              child: Icon(Icons.sync),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });
}
