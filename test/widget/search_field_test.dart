import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/widgets/search_field.dart';

void main() {
  group('SearchField', () {
    testWidgets('displays with default search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              hintText: 'Find patients',
            ),
          ),
        ),
      );

      expect(find.text('Find patients'), findsOneWidget);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button is pressed', (tester) async {
      String? lastQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (query) => lastQuery = query,
              debounceMs: 0, // Disable debounce for testing
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text field should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(lastQuery, '');
    });

    testWidgets('calls onSearch after debounce', (tester) async {
      String? lastQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (query) => lastQuery = query,
              debounceMs: 100,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Should not have called onSearch yet
      expect(lastQuery, isNull);

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 150));

      // Now should have called onSearch
      expect(lastQuery, 'test');
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses custom prefix icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              prefixIcon: const Icon(Icons.person_search),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_search), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('uses external controller', (tester) async {
      final controller = TextEditingController(text: 'initial');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              controller: controller,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'initial');

      controller.dispose();
    });

    testWidgets('uses initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              initialValue: 'preset',
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'preset');
    });

    testWidgets('respects enabled property', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('calls onClear when clearing', (tester) async {
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              onSearch: (_) {},
              onClear: () => clearCalled = true,
              debounceMs: 0,
            ),
          ),
        ),
      );

      // Enter text and clear
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(clearCalled, isTrue);
    });
  });

  group('AppBarSearchField', () {
    testWidgets('displays back button when onBack is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (_) {},
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('hides back button when onBack is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('calls onBack when back button is pressed', (tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (_) {},
              onBack: () => backPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backPressed, isTrue);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (_) {},
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onSearch after debounce', (tester) async {
      String? lastQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBarSearchField(
              onSearch: (query) => lastQuery = query,
              debounceMs: 100,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'patient');
      await tester.pump(const Duration(milliseconds: 150));

      expect(lastQuery, 'patient');
    });
  });

  group('SearchFilterChips', () {
    testWidgets('displays all filter options plus All chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChips<String>(
              filters: const ['Active', 'Inactive', 'Pending'],
              selected: null,
              onSelected: (_) {},
              labelBuilder: (f) => f,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('All chip is selected when selected is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChips<String>(
              filters: const ['Active', 'Inactive'],
              selected: null,
              onSelected: (_) {},
              labelBuilder: (f) => f,
            ),
          ),
        ),
      );

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All'),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('filter chip is selected when matching selected value',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChips<String>(
              filters: const ['Active', 'Inactive'],
              selected: 'Active',
              onSelected: (_) {},
              labelBuilder: (f) => f,
            ),
          ),
        ),
      );

      final activeChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Active'),
      );
      expect(activeChip.selected, isTrue);

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All'),
      );
      expect(allChip.selected, isFalse);
    });

    testWidgets('calls onSelected with null when All is tapped',
        (tester) async {
      String? selectedValue = 'Active';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChips<String>(
              filters: const ['Active', 'Inactive'],
              selected: selectedValue,
              onSelected: (v) => selectedValue = v,
              labelBuilder: (f) => f,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pump();

      expect(selectedValue, isNull);
    });

    testWidgets('calls onSelected with value when filter is tapped',
        (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChips<String>(
              filters: const ['Active', 'Inactive'],
              selected: selectedValue,
              onSelected: (v) => selectedValue = v,
              labelBuilder: (f) => f,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Active'));
      await tester.pump();

      expect(selectedValue, 'Active');
    });
  });

  group('SearchResultsContainer', () {
    testWidgets('shows loading widget when isLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: true,
              hasResults: false,
              isLoading: true,
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Results'), findsNothing);
    });

    testWidgets('shows custom loading widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: true,
              hasResults: false,
              isLoading: true,
              loadingWidget: Text('Loading...'),
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows empty query state when no query', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: false,
              hasResults: false,
              isLoading: false,
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Enter a search term'), findsOneWidget);
    });

    testWidgets('shows custom empty query widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: false,
              hasResults: false,
              isLoading: false,
              emptyQueryWidget: Text('Start searching'),
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.text('Start searching'), findsOneWidget);
    });

    testWidgets('shows no results state when query but no results',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: true,
              hasResults: false,
              isLoading: false,
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('shows custom no results widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: true,
              hasResults: false,
              isLoading: false,
              noResultsWidget: Text('Nothing here'),
              child: Text('Results'),
            ),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows child when has query and results', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsContainer(
              hasQuery: true,
              hasResults: true,
              isLoading: false,
              child: Text('Results here'),
            ),
          ),
        ),
      );

      expect(find.text('Results here'), findsOneWidget);
    });
  });
}
