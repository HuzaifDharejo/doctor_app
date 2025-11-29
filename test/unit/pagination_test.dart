import 'package:doctor_app/src/core/utils/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Page', () {
    test('calculates totalPages correctly', () {
      const page = Page<int>(
        items: [1, 2, 3],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 25,
      );
      
      expect(page.totalPages, 3);
    });
    
    test('calculates totalPages for exact division', () {
      const page = Page<int>(
        items: [1, 2],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 20,
      );
      
      expect(page.totalPages, 2);
    });
    
    test('hasNextPage returns true when more pages exist', () {
      const page = Page<int>(
        items: [1, 2, 3],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 25,
      );
      
      expect(page.hasNextPage, isTrue);
    });
    
    test('hasNextPage returns false on last page', () {
      const page = Page<int>(
        items: [1, 2],
        pageIndex: 2,
        pageSize: 10,
        totalItems: 22,
      );
      
      expect(page.hasNextPage, isFalse);
    });
    
    test('hasPreviousPage returns false on first page', () {
      const page = Page<int>(
        items: [1],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 15,
      );
      
      expect(page.hasPreviousPage, isFalse);
    });
    
    test('hasPreviousPage returns true after first page', () {
      const page = Page<int>(
        items: [1],
        pageIndex: 1,
        pageSize: 10,
        totalItems: 15,
      );
      
      expect(page.hasPreviousPage, isTrue);
    });
    
    test('isFirstPage returns true for pageIndex 0', () {
      const page = Page<int>(
        items: [1],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 15,
      );
      
      expect(page.isFirstPage, isTrue);
      expect(page.isLastPage, isFalse);
    });
    
    test('isLastPage returns true for last page', () {
      const page = Page<int>(
        items: [1],
        pageIndex: 1,
        pageSize: 10,
        totalItems: 15,
      );
      
      expect(page.isFirstPage, isFalse);
      expect(page.isLastPage, isTrue);
    });
    
    test('startIndex and endIndex are correct for first page', () {
      const page = Page<int>(
        items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        pageIndex: 0,
        pageSize: 10,
        totalItems: 25,
      );
      
      expect(page.startIndex, 1);
      expect(page.endIndex, 10);
    });
    
    test('startIndex and endIndex are correct for second page', () {
      const page = Page<int>(
        items: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        pageIndex: 1,
        pageSize: 10,
        totalItems: 25,
      );
      
      expect(page.startIndex, 11);
      expect(page.endIndex, 20);
    });
    
    test('endIndex does not exceed totalItems', () {
      const page = Page<int>(
        items: [21, 22, 23, 24, 25],
        pageIndex: 2,
        pageSize: 10,
        totalItems: 25,
      );
      
      expect(page.startIndex, 21);
      expect(page.endIndex, 25);
    });
  });
  
  group('PaginationController', () {
    late PaginationController<int> controller;
    late List<int> allData;
    
    setUp(() {
      allData = List.generate(45, (i) => i + 1);
      controller = PaginationController<int>(
        fetchPage: (pageIndex, pageSize) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          final start = pageIndex * pageSize;
          final end = (start + pageSize).clamp(0, allData.length);
          return (allData.sublist(start, end), allData.length);
        },
      );
    });
    
    tearDown(() {
      controller.dispose();
    });
    
    test('initial state is empty and not loading', () {
      expect(controller.items, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.hasInitialized, isFalse);
      expect(controller.error, isNull);
    });
    
    test('loadInitial loads first page', () async {
      await controller.loadInitial();
      
      expect(controller.items.length, 20);
      expect(controller.hasInitialized, isTrue);
      expect(controller.totalItems, 45);
      expect(controller.hasMore, isTrue);
      expect(controller.currentPage, 0);
    });
    
    test('loadNextPage loads additional items', () async {
      await controller.loadInitial();
      await controller.loadNextPage();
      
      expect(controller.items.length, 40);
      expect(controller.currentPage, 1);
      expect(controller.hasMore, isTrue);
    });
    
    test('loadNextPage stops when no more items', () async {
      await controller.loadInitial();
      await controller.loadNextPage();
      await controller.loadNextPage();
      
      expect(controller.items.length, 45);
      expect(controller.hasMore, isFalse);
      
      // Loading more should do nothing
      await controller.loadNextPage();
      expect(controller.items.length, 45);
    });
    
    test('refresh clears and reloads', () async {
      await controller.loadInitial();
      await controller.loadNextPage();
      expect(controller.items.length, 40);
      
      await controller.refresh();
      expect(controller.items.length, 20);
      expect(controller.currentPage, 0);
    });
    
    test('isEmpty returns true when no items after initialization', () async {
      final emptyController = PaginationController<int>(
        fetchPage: (_, __) async => (<int>[], 0),
      );
      
      await emptyController.loadInitial();
      expect(emptyController.isEmpty, isTrue);
      
      emptyController.dispose();
    });
    
    test('handles fetch errors', () async {
      final errorController = PaginationController<int>(
        fetchPage: (_, __) async {
          throw Exception('Network error');
        },
      );
      
      await errorController.loadInitial();
      
      expect(errorController.error, contains('Network error'));
      expect(errorController.items, isEmpty);
      
      errorController.dispose();
    });
    
    test('notifies listeners on state changes', () async {
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);
      
      await controller.loadInitial();
      
      // At least 2 notifications: start loading + finish loading
      expect(notificationCount, greaterThanOrEqualTo(2));
    });
  });
  
  group('PaginatedResult', () {
    test('hasMore returns true when more items exist', () {
      const result = PaginatedResult<int>(
        items: [1, 2, 3, 4, 5],
        totalCount: 10,
        offset: 0,
        limit: 5,
      );
      
      expect(result.hasMore, isTrue);
    });
    
    test('hasMore returns false when all items loaded', () {
      const result = PaginatedResult<int>(
        items: [6, 7, 8, 9, 10],
        totalCount: 10,
        offset: 5,
        limit: 5,
      );
      
      expect(result.hasMore, isFalse);
    });
    
    test('currentPage is calculated correctly', () {
      const page1 = PaginatedResult<int>(
        items: [1, 2, 3],
        totalCount: 30,
        offset: 0,
        limit: 10,
      );
      expect(page1.currentPage, 1);
      
      const page2 = PaginatedResult<int>(
        items: [11, 12, 13],
        totalCount: 30,
        offset: 10,
        limit: 10,
      );
      expect(page2.currentPage, 2);
      
      const page3 = PaginatedResult<int>(
        items: [21, 22, 23],
        totalCount: 30,
        offset: 20,
        limit: 10,
      );
      expect(page3.currentPage, 3);
    });
    
    test('totalPages is calculated correctly', () {
      const result = PaginatedResult<int>(
        items: [1, 2, 3],
        totalCount: 25,
        offset: 0,
        limit: 10,
      );
      
      expect(result.totalPages, 3);
    });
  });
  
  group('PaginationExtension', () {
    late List<int> data;
    
    setUp(() {
      data = List.generate(25, (i) => i + 1);
    });
    
    test('paginate returns correct items for first page', () {
      final result = data.paginate(page: 1, pageSize: 10);
      
      expect(result.items, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      expect(result.totalCount, 25);
      expect(result.hasMore, isTrue);
    });
    
    test('paginate returns correct items for middle page', () {
      final result = data.paginate(page: 2, pageSize: 10);
      
      expect(result.items, [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      expect(result.hasMore, isTrue);
    });
    
    test('paginate returns correct items for last page', () {
      final result = data.paginate(page: 3, pageSize: 10);
      
      expect(result.items, [21, 22, 23, 24, 25]);
      expect(result.hasMore, isFalse);
    });
    
    test('paginate handles empty list', () {
      final emptyList = <int>[];
      final result = emptyList.paginate(page: 1, pageSize: 10);
      
      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
      expect(result.hasMore, isFalse);
    });
    
    test('paginate handles page beyond data', () {
      final result = data.paginate(page: 10, pageSize: 10);
      
      expect(result.items, isEmpty);
      expect(result.totalCount, 25);
    });
    
    test('paginate uses default pageSize of 20', () {
      final largeData = List.generate(50, (i) => i);
      final result = largeData.paginate(page: 1);
      
      expect(result.items.length, 20);
    });
  });
}
