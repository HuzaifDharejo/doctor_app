/// Pagination utilities for handling large lists efficiently.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Represents a single page of items.
@immutable
class Page<T> {
  const Page({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalItems,
  });

  /// The items in this page.
  final List<T> items;
  
  /// The current page index (0-based).
  final int pageIndex;
  
  /// The maximum number of items per page.
  final int pageSize;
  
  /// The total number of items across all pages.
  final int totalItems;
  
  /// Total number of pages.
  int get totalPages => (totalItems / pageSize).ceil();
  
  /// Whether there are more pages after this one.
  bool get hasNextPage => pageIndex < totalPages - 1;
  
  /// Whether there are pages before this one.
  bool get hasPreviousPage => pageIndex > 0;
  
  /// Whether this is the first page.
  bool get isFirstPage => pageIndex == 0;
  
  /// Whether this is the last page.
  bool get isLastPage => pageIndex >= totalPages - 1;
  
  /// The starting index of items in this page (1-based for display).
  int get startIndex => pageIndex * pageSize + 1;
  
  /// The ending index of items in this page (1-based for display).
  int get endIndex => (startIndex - 1 + items.length).clamp(1, totalItems);
}

/// A paginated data controller that manages loading pages of data.
class PaginationController<T> extends ChangeNotifier {
  PaginationController({
    required this.fetchPage,
    this.pageSize = 20,
  });

  /// Function to fetch a page of items.
  /// Returns (items, totalCount).
  final Future<(List<T>, int)> Function(int pageIndex, int pageSize) fetchPage;
  
  /// Number of items per page.
  final int pageSize;

  /// All loaded items across all pages.
  final List<T> _items = [];
  List<T> get items => List.unmodifiable(_items);
  
  /// Current loading state.
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  /// Error message if loading failed.
  String? _error;
  String? get error => _error;
  
  /// Whether initial load has been done.
  bool _hasInitialized = false;
  bool get hasInitialized => _hasInitialized;
  
  /// Total number of items (from server).
  int _totalItems = 0;
  int get totalItems => _totalItems;
  
  /// Current page index.
  int _currentPage = 0;
  int get currentPage => _currentPage;
  
  /// Total number of pages.
  int get totalPages => (_totalItems / pageSize).ceil();
  
  /// Whether there are more items to load.
  bool get hasMore => _items.length < _totalItems;
  
  /// Whether loading has started at least once.
  bool get isEmpty => _hasInitialized && _items.isEmpty && !_isLoading;
  
  /// Track disposal state to prevent notifyListeners after disposal
  bool _isDisposed = false;
  
  /// Safely notify listeners only if not disposed
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  /// Load the initial page.
  Future<void> loadInitial() async {
    if (_isLoading || _isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _items.clear();
    _currentPage = 0;
    _safeNotifyListeners();
    
    try {
      final (items, total) = await fetchPage(0, pageSize);
      if (_isDisposed) return;
      _items.addAll(items);
      _totalItems = total;
      _hasInitialized = true;
    } catch (e) {
      if (_isDisposed) return;
      _error = e.toString();
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
  
  /// Load the next page if available.
  Future<void> loadNextPage() async {
    if (_isLoading || !hasMore || _isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();
    
    try {
      final nextPage = _currentPage + 1;
      final (items, total) = await fetchPage(nextPage, pageSize);
      if (_isDisposed) return;
      _items.addAll(items);
      _totalItems = total;
      _currentPage = nextPage;
    } catch (e) {
      if (_isDisposed) return;
      _error = e.toString();
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
  
  /// Refresh and reload from the beginning.
  Future<void> refresh() async {
    _items.clear();
    _error = null;
    _hasInitialized = false;
    _currentPage = 0;
    _totalItems = 0;
    await loadInitial();
  }
  
  /// Check if we should load more based on scroll position.
  /// Call this when the user scrolls near the bottom.
  void onScroll({
    required double scrollPosition,
    required double maxScrollExtent,
    double threshold = 200,
  }) {
    if (scrollPosition >= maxScrollExtent - threshold) {
      loadNextPage();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _items.clear();
    super.dispose();
  }
}

/// A paginated list result for database queries.
@immutable
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  /// The items in this result.
  final List<T> items;
  
  /// Total count of all matching items.
  final int totalCount;
  
  /// The offset used for this query.
  final int offset;
  
  /// The limit used for this query.
  final int limit;
  
  /// Whether there are more items after this result.
  bool get hasMore => offset + items.length < totalCount;
  
  /// Current page number (1-based).
  int get currentPage => (offset / limit).floor() + 1;
  
  /// Total pages.
  int get totalPages => (totalCount / limit).ceil();
}

/// Extension to add pagination support to lists.
extension PaginationExtension<T> on List<T> {
  /// Get a paginated subset of this list.
  PaginatedResult<T> paginate({
    required int page,
    int pageSize = 20,
  }) {
    final offset = (page - 1) * pageSize;
    final end = (offset + pageSize).clamp(0, length);
    final items = offset < length ? sublist(offset, end) : <T>[];
    
    return PaginatedResult(
      items: items,
      totalCount: length,
      offset: offset,
      limit: pageSize,
    );
  }
}
