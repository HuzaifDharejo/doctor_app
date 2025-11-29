// Basic app smoke test for Doctor App
import 'package:doctor_app/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Doctor App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DoctorApp()));

    // Wait for any async operations
    await tester.pumpAndSettle();

    // Verify that the app starts without errors
    // The app should show some content
    expect(find.byType(DoctorApp), findsOneWidget);
  });
}
