import 'dart:async';

import 'package:flutter/material.dart';

/// A search text field with debouncing and clear button.
///
/// This widget provides a consistent search experience with:
/// - Debounced search to avoid excessive API calls
/// - Clear button when text is present
/// - Loading indicator during search
/// - Customizable hint and styling
///
/// Example:
/// ```dart
/// SearchField(
///   onSearch: (query) => searchPatients(query),
///   hintText: 'Search patients...',
///   debounceMs: 300,
/// )
/// ```
class SearchField extends StatefulWidget {
  /// Creates a search field.
  const SearchField({
    super.key,
    required this.onSearch,
    this.hintText = 'Search...',
    this.debounceMs = 300,
    this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.onClear,
    this.isLoading = false,
    this.textInputAction = TextInputAction.search,
    this.focusNode,
    this.initialValue,
  });

  /// Callback when search query changes (after debounce).
  final ValueChanged<String> onSearch;

  /// Hint text shown when field is empty.
  final String hintText;

  /// Debounce delay in milliseconds.
  final int debounceMs;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to autofocus the field.
  final bool autofocus;

  /// Custom prefix icon (defaults to search icon).
  final Widget? prefixIcon;

  /// Callback when clear button is pressed.
  final VoidCallback? onClear;

  /// Whether search is in progress.
  final bool isLoading;

  /// Text input action.
  final TextInputAction textInputAction;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Initial value for the field.
  final String? initialValue;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  bool _ownsController = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to show/hide clear button

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceMs),
      () {
        widget.onSearch(_controller.text);
      },
    );
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon ?? const Icon(Icons.search),
        suffixIcon: widget.isLoading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : hasText
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _onClear,
                    tooltip: 'Clear search',
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onSubmitted: (_) => widget.onSearch(_controller.text),
    );
  }
}

/// A compact search field designed for app bars.
///
/// This widget is styled for use in app bars with a more compact design.
class AppBarSearchField extends StatefulWidget {
  /// Creates an app bar search field.
  const AppBarSearchField({
    super.key,
    required this.onSearch,
    this.hintText = 'Search...',
    this.debounceMs = 300,
    this.onBack,
    this.autofocus = true,
    this.isLoading = false,
  });

  /// Callback when search query changes (after debounce).
  final ValueChanged<String> onSearch;

  /// Hint text shown when field is empty.
  final String hintText;

  /// Debounce delay in milliseconds.
  final int debounceMs;

  /// Callback when back button is pressed.
  final VoidCallback? onBack;

  /// Whether to autofocus the field.
  final bool autofocus;

  /// Whether search is in progress.
  final bool isLoading;

  @override
  State<AppBarSearchField> createState() => _AppBarSearchFieldState();
}

class _AppBarSearchFieldState extends State<AppBarSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceMs),
      () {
        widget.onSearch(value);
      },
    );
  }

  void _onClear() {
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
            tooltip: 'Back',
          ),
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
            ),
            onChanged: _onTextChanged,
            onSubmitted: widget.onSearch,
          ),
        ),
        if (widget.isLoading)
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onSurface,
            ),
          )
        else if (_hasText)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _onClear,
            tooltip: 'Clear',
          ),
      ],
    );
  }
}

/// A filter chip group for search filters.
///
/// This widget displays a row of filter chips that can be used
/// alongside a search field to refine results.
class SearchFilterChips<T> extends StatelessWidget {
  /// Creates a filter chip group.
  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  /// Available filter options.
  final List<T> filters;

  /// Currently selected filter.
  final T? selected;

  /// Callback when a filter is selected.
  final ValueChanged<T?> onSelected;

  /// Builder for filter labels.
  final String Function(T filter) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          // Filter chips
          ...filters.map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labelBuilder(filter)),
                selected: selected == filter,
                onSelected: (isSelected) {
                  onSelected(isSelected ? filter : null);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search result container with empty state handling.
///
/// This widget displays search results or an appropriate empty state
/// based on the search state.
class SearchResultsContainer extends StatelessWidget {
  /// Creates a search results container.
  const SearchResultsContainer({
    super.key,
    required this.hasQuery,
    required this.hasResults,
    required this.isLoading,
    required this.child,
    this.emptyQueryWidget,
    this.noResultsWidget,
    this.loadingWidget,
  });

  /// Whether there is a search query.
  final bool hasQuery;

  /// Whether there are search results.
  final bool hasResults;

  /// Whether search is in progress.
  final bool isLoading;

  /// The results widget to display.
  final Widget child;

  /// Widget to show when there's no query.
  final Widget? emptyQueryWidget;

  /// Widget to show when there are no results.
  final Widget? noResultsWidget;

  /// Widget to show during loading.
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (!hasQuery) {
      return emptyQueryWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Enter a search term',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }

    if (!hasResults) {
      return noResultsWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No results found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
    }

    return child;
  }
}
