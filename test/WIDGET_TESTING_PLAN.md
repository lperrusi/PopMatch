# Widget Testing Plan for PopMatch

## Current Test Status

### ✅ Passing Widget Tests (27 tests)
- Basic widget rendering tests
- Simple interaction tests
- Basic functionality tests

### ⚠️ Failing Widget Tests (19 tests)

## Critical Issues Identified

### 1. Layout Overflow Issues
**Affected Widgets:**
- MovieCard Widget (Row overflow by 90px)
- RecommendationsWidget (Column overflow by 84px)
- VideoPlayerWidget (Column overflow by 16px)

**Root Cause:** Widgets not properly handling constrained test environments

### 2. Icon Reference Issues
**Affected Widgets:**
- SearchBarWidget (clear button icon not found)
- VideoPlayerWidget (video type icons)

**Root Cause:** Using incorrect Material Icons or missing icon references

### 3. Provider Setup Issues
**Affected Widgets:**
- All widgets requiring provider context
- Widgets with async operations

**Root Cause:** Missing proper provider context in test environment

### 4. Test Environment Issues
**Issues:**
- Network timeout issues
- Missing mock data
- Async operation handling

## Widget Tests We Should Implement/Fix

### 1. MovieCard Widget Tests (Priority: HIGH)
**Current Issues:**
- Layout overflow in constrained environments
- Rating display logic issues
- Long title handling

**Tests to Implement:**
```dart
// Responsive layout tests
testWidgets('should handle different screen sizes', (WidgetTester tester) async {
  // Test with different constraints
});

// Rating display tests
testWidgets('should display rating correctly', (WidgetTester tester) async {
  // Test with null, zero, and valid ratings
});

// Long title handling
testWidgets('should truncate long titles', (WidgetTester tester) async {
  // Test with very long movie titles
});

// Streaming availability display
testWidgets('should show streaming platforms', (WidgetTester tester) async {
  // Test streaming platform icons
});
```

### 2. SearchBarWidget Tests (Priority: HIGH)
**Current Issues:**
- Clear button icon not found
- Placeholder text not displaying

**Tests to Implement:**
```dart
// Icon tests
testWidgets('should show clear button when text entered', (WidgetTester tester) async {
  // Test clear button visibility and functionality
});

// Placeholder text
testWidgets('should display placeholder text', (WidgetTester tester) async {
  // Test placeholder text display
});

// Search functionality
testWidgets('should call onSearch when text changes', (WidgetTester tester) async {
  // Test search callback
});
```

### 3. RecommendationsWidget Tests (Priority: MEDIUM)
**Current Issues:**
- Layout overflow
- Tap handling issues

**Tests to Implement:**
```dart
// Responsive layout
testWidgets('should fit in constrained space', (WidgetTester tester) async {
  // Test with different container sizes
});

// Movie tap handling
testWidgets('should handle movie taps correctly', (WidgetTester tester) async {
  // Test tap callbacks
});

// Loading states
testWidgets('should show loading state', (WidgetTester tester) async {
  // Test loading indicators
});
```

### 4. VideoPlayerWidget Tests (Priority: MEDIUM)
**Current Issues:**
- Non-YouTube video handling
- Layout overflow

**Tests to Implement:**
```dart
// Video type detection
testWidgets('should detect YouTube videos', (WidgetTester tester) async {
  // Test YouTube URL detection
});

testWidgets('should handle Vimeo videos', (WidgetTester tester) async {
  // Test Vimeo URL handling
});

// Error handling
testWidgets('should show error for invalid URLs', (WidgetTester tester) async {
  // Test error states
});
```

### 5. StreamingPlatformWidget Tests (Priority: LOW)
**Tests to Implement:**
```dart
// Platform display
testWidgets('should show available platforms', (WidgetTester tester) async {
  // Test platform icon display
});

// Platform tap handling
testWidgets('should handle platform taps', (WidgetTester tester) async {
  // Test platform selection
});
```

## Test Environment Improvements Needed

### 1. Provider Test Helpers
```dart
// Create reusable provider setup
Widget createTestApp({
  required Widget child,
  List<ChangeNotifierProvider> providers = const [],
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MovieProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ...providers,
    ],
    child: MaterialApp(home: child),
  );
}
```

### 2. Mock Data Utilities
```dart
// Create consistent test data
class TestData {
  static Movie createTestMovie({
    int id = 1,
    String title = 'Test Movie',
    double? rating,
  }) {
    return Movie(
      id: id,
      title: title,
      voteAverage: rating,
      // ... other properties
    );
  }
}
```

### 3. Layout Test Helpers
```dart
// Test with different screen sizes
Future<void> testWithConstraints(
  WidgetTester tester,
  Widget widget,
  Size constraints,
) async {
  await tester.binding.setSurfaceSize(constraints);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}
```

## Implementation Priority

### Phase 1: Critical Fixes (Week 1)
1. **Fix MovieCard layout overflow**
   - Add proper flex constraints
   - Handle long titles with ellipsis
   - Fix rating display logic

2. **Fix SearchBarWidget icons**
   - Update to correct Material Icons
   - Add proper clear button functionality

3. **Add provider test helpers**
   - Create reusable test setup
   - Fix provider context issues

### Phase 2: Enhanced Testing (Week 2)
1. **Improve RecommendationsWidget**
   - Fix layout overflow
   - Add proper tap handling
   - Test loading states

2. **Enhance VideoPlayerWidget**
   - Fix video type detection
   - Add error handling tests
   - Test different video platforms

### Phase 3: Comprehensive Coverage (Week 3)
1. **Add missing widget tests**
   - StreamingPlatformWidget
   - CastCrewWidget
   - SearchResultsWidget

2. **Add integration tests**
   - Widget interaction tests
   - Cross-widget communication
   - User flow tests

## Test Categories to Implement

### 1. Responsive Design Tests
- Test widgets at different screen sizes
- Test with different text lengths
- Test with different data amounts

### 2. Accessibility Tests
- Test semantic labels
- Test keyboard navigation
- Test screen reader compatibility

### 3. Error Handling Tests
- Test with invalid data
- Test network error states
- Test loading timeout scenarios

### 4. Performance Tests
- Test with large datasets
- Test scroll performance
- Test memory usage

### 5. User Interaction Tests
- Test tap gestures
- Test long press gestures
- Test drag and drop (if applicable)

## Success Metrics

### Quantitative
- **Test Coverage:** Aim for 90%+ widget test coverage
- **Pass Rate:** 95%+ test pass rate
- **Performance:** All tests complete within 30 seconds

### Qualitative
- **Reliability:** Tests are deterministic and don't flake
- **Maintainability:** Tests are easy to understand and modify
- **Completeness:** All user interactions are tested

## Next Steps

1. **Immediate:** Fix the critical layout overflow issues
2. **Short-term:** Implement proper provider test setup
3. **Medium-term:** Add comprehensive widget test coverage
4. **Long-term:** Implement performance and accessibility tests

This plan will ensure our widgets are robust, responsive, and thoroughly tested for all user scenarios. 