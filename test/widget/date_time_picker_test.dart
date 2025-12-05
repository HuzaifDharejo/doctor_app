import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/date_time_picker.dart';

void main() {
  group('DatePreset', () {
    test('today returns current date', () {
      final date = DatePreset.today.toDate();
      final now = DateTime.now();
      
      expect(date, isNotNull);
      expect(date!.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
    });

    test('tomorrow returns next day', () {
      final date = DatePreset.tomorrow.toDate();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      expect(date, isNotNull);
      expect(date!.year, tomorrow.year);
      expect(date.month, tomorrow.month);
      expect(date.day, tomorrow.day);
    });

    test('nextWeek returns date 7 days from now', () {
      final date = DatePreset.nextWeek.toDate();
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      
      expect(date, isNotNull);
      expect(date!.year, nextWeek.year);
      expect(date.month, nextWeek.month);
      expect(date.day, nextWeek.day);
    });

    test('custom returns null', () {
      expect(DatePreset.custom.toDate(), isNull);
    });

    test('labels are correct', () {
      expect(DatePreset.today.label, 'Today');
      expect(DatePreset.tomorrow.label, 'Tomorrow');
      expect(DatePreset.nextWeek.label, 'Next Week');
      expect(DatePreset.nextMonth.label, 'Next Month');
      expect(DatePreset.custom.label, 'Custom');
    });
  });

  group('TimePreset', () {
    test('morning returns 9:00 AM', () {
      final time = TimePreset.morning.toTime();
      
      expect(time, isNotNull);
      expect(time!.hour, 9);
      expect(time.minute, 0);
    });

    test('noon returns 12:00 PM', () {
      final time = TimePreset.noon.toTime();
      
      expect(time, isNotNull);
      expect(time!.hour, 12);
      expect(time.minute, 0);
    });

    test('afternoon returns 2:00 PM', () {
      final time = TimePreset.afternoon.toTime();
      
      expect(time, isNotNull);
      expect(time!.hour, 14);
      expect(time.minute, 0);
    });

    test('evening returns 5:00 PM', () {
      final time = TimePreset.evening.toTime();
      
      expect(time, isNotNull);
      expect(time!.hour, 17);
      expect(time.minute, 0);
    });

    test('custom returns null', () {
      expect(TimePreset.custom.toTime(), isNull);
    });
  });

  group('AppDateTimePicker', () {
    Widget buildTestWidget({
      String? label,
      DateTime? initialDate,
      TimeOfDay? initialTime,
      bool showDatePresets = true,
      bool showTimePresets = true,
      bool showTime = true,
      ValueChanged<DateTime>? onDateSelected,
      ValueChanged<TimeOfDay>? onTimeSelected,
      String? errorText,
      String? helperText,
      bool isRequired = false,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppDateTimePicker(
                label: label,
                initialDate: initialDate,
                initialTime: initialTime,
                showDatePresets: showDatePresets,
                showTimePresets: showTimePresets,
                showTime: showTime,
                onDateSelected: onDateSelected,
                onTimeSelected: onTimeSelected,
                errorText: errorText,
                helperText: helperText,
                isRequired: isRequired,
                enabled: enabled,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: 'Select Date & Time',
      ));

      expect(find.text('Select Date & Time'), findsOneWidget);
    });

    testWidgets('shows required indicator when isRequired is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: 'Required Date',
        isRequired: true,
      ));

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('shows date section title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('shows time section when showTime is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showTime: true,
      ));

      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('hides time section when showTime is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showTime: false,
      ));

      expect(find.text('Time'), findsNothing);
    });

    testWidgets('shows date presets when showDatePresets is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showDatePresets: true,
      ));

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Next Week'), findsOneWidget);
    });

    testWidgets('hides date presets when showDatePresets is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showDatePresets: false,
      ));

      expect(find.text('Today'), findsNothing);
      expect(find.text('Tomorrow'), findsNothing);
    });

    testWidgets('shows time presets when showTimePresets is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showTimePresets: true,
        showTime: true,
      ));

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Noon'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
    });

    testWidgets('shows placeholder text when no date selected', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Select date...'), findsOneWidget);
    });

    testWidgets('shows placeholder text when no time selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showTime: true,
      ));

      expect(find.text('Select time...'), findsOneWidget);
    });

    testWidgets('displays initial date', (tester) async {
      final date = DateTime(2025, 12, 25);
      
      await tester.pumpWidget(buildTestWidget(
        initialDate: date,
      ));

      expect(find.text('Dec 25, 2025'), findsOneWidget);
    });

    testWidgets('displays initial time', (tester) async {
      const time = TimeOfDay(hour: 14, minute: 30);
      
      await tester.pumpWidget(buildTestWidget(
        initialTime: time,
        showTime: true,
      ));

      expect(find.text('2:30 PM'), findsOneWidget);
    });

    testWidgets('tapping Today preset selects today', (tester) async {
      DateTime? selectedDate;
      
      await tester.pumpWidget(buildTestWidget(
        onDateSelected: (date) => selectedDate = date,
      ));

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      
      final now = DateTime.now();
      expect(selectedDate, isNotNull);
      expect(selectedDate!.year, now.year);
      expect(selectedDate!.month, now.month);
      expect(selectedDate!.day, now.day);
    });

    testWidgets('tapping Tomorrow preset selects tomorrow', (tester) async {
      DateTime? selectedDate;
      
      await tester.pumpWidget(buildTestWidget(
        onDateSelected: (date) => selectedDate = date,
      ));

      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(selectedDate, isNotNull);
      expect(selectedDate!.year, tomorrow.year);
      expect(selectedDate!.month, tomorrow.month);
      expect(selectedDate!.day, tomorrow.day);
    });

    testWidgets('tapping Morning preset selects 9 AM', (tester) async {
      TimeOfDay? selectedTime;
      
      await tester.pumpWidget(buildTestWidget(
        showTime: true,
        onTimeSelected: (time) => selectedTime = time,
      ));

      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      
      expect(selectedTime, isNotNull);
      expect(selectedTime!.hour, 9);
      expect(selectedTime!.minute, 0);
    });

    testWidgets('shows error text when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        errorText: 'Please select a date',
      ));

      expect(find.text('Please select a date'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows helper text when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helperText: 'Choose your preferred date',
      ));

      expect(find.text('Choose your preferred date'), findsOneWidget);
    });

    testWidgets('error text takes precedence over helper text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        errorText: 'Error message',
        helperText: 'Helper message',
      ));

      expect(find.text('Error message'), findsOneWidget);
      expect(find.text('Helper message'), findsNothing);
    });

    testWidgets('date button shows calendar icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });

    testWidgets('time button shows clock icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        showTime: true,
      ));

      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('disabled picker does not respond to taps', (tester) async {
      DateTime? selectedDate;
      
      await tester.pumpWidget(buildTestWidget(
        enabled: false,
        onDateSelected: (date) => selectedDate = date,
      ));

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      
      expect(selectedDate, isNull);
    });
  });

  group('CompactDatePicker', () {
    testWidgets('renders without time section', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactDatePicker(
            selectedDate: DateTime(2025, 1, 15),
            onDateSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsNothing);
    });

    testWidgets('shows date presets by default', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactDatePicker(
            onDateSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('hides presets when showPresets is false', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactDatePicker(
            showPresets: false,
            onDateSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('Today'), findsNothing);
    });
  });

  group('CompactTimePicker', () {
    testWidgets('renders time section only', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactTimePicker(
            selectedTime: const TimeOfDay(hour: 10, minute: 30),
            onTimeSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('Time'), findsOneWidget);
      // Date section title should not appear (no label set)
    });

    testWidgets('shows time presets by default', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactTimePicker(
            onTimeSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Noon'), findsOneWidget);
    });
  });

  group('AppDateTimePicker dark mode', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AppDateTimePicker(
            label: 'Dark Mode Picker',
            initialDate: DateTime(2025, 6, 15),
            initialTime: const TimeOfDay(hour: 14, minute: 0),
          ),
        ),
      ));

      expect(find.text('Dark Mode Picker'), findsOneWidget);
      expect(find.text('Jun 15, 2025'), findsOneWidget);
      expect(find.text('2:00 PM'), findsOneWidget);
    });
  });

  group('AppDateTimePicker accessibility', () {
    testWidgets('wraps content in Semantics widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppDateTimePicker(
            label: 'Appointment Time',
          ),
        ),
      ));

      // Check that the main Semantics widget is present
      expect(find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label != null,
      ), findsWidgets);
    });

    testWidgets('preset chips are marked as buttons in semantics', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppDateTimePicker(
            showDatePresets: true,
          ),
        ),
      ));

      // Check that preset chips exist and are wrapped in Semantics
      expect(find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.button == true &&
                    widget.properties.label?.contains('preset') == true,
      ), findsWidgets);
    });
  });
}
