---
description: Testing conventions for PopMatch — always apply when writing or modifying tests
---

- Unit and widget tests live in `test/`; integration tests live in `integration_test/` and require a real device/simulator. `flutter test` cannot mix both in one invocation — run them separately or use `scripts/ci_test.sh`.
- Always call `TMDBService.setTestMode(true)` in `setUpAll` (and `setTestMode(false)` in `tearDownAll`) to prevent real TMDB network calls and use sample data instead.
- Always call `FirebaseConfig.setTestMode(true)` in `setUpAll` (and `setTestMode(false)` in `tearDownAll`) when tests touch `AuthService` or `AuthProvider`. This disables Firebase so auth runs in development/SharedPreferences mode without requiring `Firebase.initializeApp()`.
- Always call `SharedPreferences.setMockInitialValues({})` in `setUpAll` to isolate local storage. Required for any code using `CollaborativeFilteringService`, `AdaptiveWeightingService`, or `AuthProvider`.
- Use `MovieProvider.setTestGenres()` when a test needs a preloaded provider without real API calls.
- Reuse helpers from `test/test_utilities.dart` (mock setup, test user creation).
- Integration tests for the swipe deck seed data directly — do not rely on the network.
- Test coverage map is in `test/README_TESTS.md`.

## Standard widget test boilerplate

```dart
void main() {
  late AuthProvider authProvider;
  late MovieProvider movieProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
    FirebaseConfig.setTestMode(false);
  });

  setUp(() {
    authProvider = AuthProvider();
    movieProvider = MovieProvider();
    movieProvider.setTestGenres(const {28: 'Action', 12: 'Adventure', 35: 'Comedy'});
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
        ChangeNotifierProvider(create: (_) => ShowProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider(create: (_) => StreamingProvider()),
      ],
      child: MaterialApp(theme: ThemeData.dark(), home: child),
    );
  }

  group('Feature', () {
    testWidgets('description', (tester) async {
      await tester.pumpWidget(wrap(const MyScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Expected'), findsOneWidget);
    });
  });
}
```

## Standard service/unit test boilerplate

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServiceName Tests', () {
    final service = SomeService();

    test('description', () async {
      final result = await service.someMethod();
      expect(result, expectedValue);
    });
  });
}
```
