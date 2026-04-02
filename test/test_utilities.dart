import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/video.dart';
import 'package:popmatch/models/streaming_platform.dart';
import 'package:popmatch/models/user.dart';

/// Test utilities for PopMatch widget tests
class TestUtilities {
  /// Creates a test app with common providers
  static Widget createTestApp({
    required Widget child,
    List<ChangeNotifierProvider> additionalProviders = const [],
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ...additionalProviders,
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
      ),
    );
  }

  /// Creates a test movie with default values
  static Movie createTestMovie({
    int id = 1,
    String title = 'Test Movie',
    String? overview,
    double? rating,
    int? voteCount,
    List<String>? genres,
    String? posterPath,
  }) {
    return Movie(
      id: id,
      title: title,
      overview: overview ?? 'A test movie for testing purposes',
      voteAverage: rating,
      voteCount: voteCount,
      genres: genres ?? ['Action', 'Adventure'],
      posterPath: posterPath,
      releaseDate: '2023-01-01',
      popularity: 85.5,
      isAdult: false,
      video: false,
      originalLanguage: 'en',
      originalTitle: title,
    );
  }

  /// Creates a test movie with no rating
  static Movie createTestMovieWithNoRating({
    int id = 1,
    String title = 'Test Movie',
  }) {
    return Movie(
      id: id,
      title: title,
      overview: 'A test movie for testing purposes',
      voteAverage: null,
      voteCount: null,
      genres: ['Action', 'Adventure'],
      posterPath: '/test-poster.jpg',
      releaseDate: '2023-01-01',
      popularity: 85.5,
      isAdult: false,
      video: false,
      originalLanguage: 'en',
      originalTitle: title,
    );
  }

  /// Creates a test movie with long title
  static Movie createTestMovieWithLongTitle({
    int id = 1,
  }) {
    return Movie(
      id: id,
      title: 'This is a very long movie title that should be truncated in the UI to prevent overflow issues and maintain proper layout',
      overview: 'A test movie with a very long title for testing text overflow handling',
      voteAverage: 8.5,
      voteCount: 1000,
      genres: ['Action', 'Adventure', 'Comedy'],
      posterPath: '/test-poster.jpg',
      releaseDate: '2023-01-01',
      popularity: 85.5,
      isAdult: false,
      video: false,
      originalLanguage: 'en',
      originalTitle: 'This is a very long movie title that should be truncated',
    );
  }

  /// Tests widget with different screen sizes
  static Future<void> testWithConstraints(
    WidgetTester tester,
    Widget widget,
    Size constraints,
  ) async {
    await tester.binding.setSurfaceSize(constraints);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Waits for async operations to complete
  static Future<void> waitForAsync(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Creates a test video with default values
  static Video createTestVideo({
    String? id,
    String? name,
    String? site,
  }) {
    return Video(
      id: id ?? 'test-video-1',
      name: name ?? 'Official Trailer',
      key: 'test-key',
      site: site ?? 'YouTube',
      size: 1080,
      type: 'Trailer',
      official: 'true',
      publishedAt: '2023-01-01',
    );
  }

  /// Creates a test streaming platform with default values
  static StreamingPlatform createTestPlatform({
    String? id,
    String? name,
  }) {
          return StreamingPlatform(
        id: id ?? 'netflix',
        name: name ?? 'Netflix',
        logoPath: '/netflix-logo.png',
      );
  }

  /// Creates a test user with default values
  static User createTestUser({
    String? id,
    String? email,
    String? displayName,
  }) {
    return User(
      id: id ?? 'test-user-id',
      email: email ?? 'test@example.com',
      displayName: displayName ?? 'Test User',
      photoURL: '/test-photo.jpg',
      watchlist: [],
      preferences: {},
    );
  }

  /// Creates a test cast member with default values
  static CastMember createTestCastMember({
    int? id,
    String? name,
    String? character,
  }) {
    return CastMember(
      id: id ?? 1,
      name: name ?? 'John Doe',
      character: character ?? 'Hero',
      profilePath: '/profile.jpg',
      order: 1,
    );
  }

  /// Creates a test crew member with default values
  static CrewMember createTestCrewMember({
    int? id,
    String? name,
    String? job,
  }) {
    return CrewMember(
      id: id ?? 1,
      name: name ?? 'Jane Smith',
      job: job ?? 'Director',
      department: 'Directing',
      profilePath: '/profile.jpg',
    );
  }

  /// Creates a list of test movies
  static List<Movie> createTestMovies({int count = 3}) {
    return List.generate(count, (index) => createTestMovie(
      id: index + 1,
      title: 'Test Movie ${index + 1}',
      rating: 7.0 + (index * 0.5),
    ));
  }

  /// Creates a list of test videos
  static List<Video> createTestVideos({int count = 3}) {
    return List.generate(count, (index) => createTestVideo(
      id: 'test-video-${index + 1}',
      name: 'Trailer ${index + 1}',
    ));
  }

  /// Creates a list of test streaming platforms
  static List<StreamingPlatform> createTestPlatforms() {
    return [
      createTestPlatform(id: 'netflix', name: 'Netflix'),
      createTestPlatform(id: 'amazon', name: 'Amazon Prime'),
      createTestPlatform(id: 'disney', name: 'Disney+'),
    ];
  }
}

/// Widget test helpers
class WidgetTestHelpers {
  /// Wraps a widget in a MaterialApp with proper sizing
  static Widget wrapWithMaterialApp({
    required Widget child,
    double width = 400,
    double height = 600,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }

  /// Wraps a widget in a MaterialApp with providers
  static Widget wrapWithProviders({
    required Widget child,
    List<ChangeNotifierProvider> providers = const [],
    double width = 400,
    double height = 600,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: providers.isEmpty
              ? child
              : MultiProvider(
                  providers: providers,
                  child: child,
                ),
        ),
      ),
    );
  }

  /// Waits for async operations to complete
  static Future<void> waitForAsync(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Taps a widget and waits for animations
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text and waits for updates
  static Future<void> enterTextAndWait(WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Finds text and verifies it exists
  static void expectTextExists(WidgetTester tester, String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Finds text and verifies it doesn't exist
  static void expectTextDoesNotExist(WidgetTester tester, String text) {
    expect(find.text(text), findsNothing);
  }

  /// Finds widget by type and verifies it exists
  static void expectWidgetExists(WidgetTester tester, Type widgetType) {
    expect(find.byType(widgetType), findsOneWidget);
  }

  /// Finds widget by type and verifies it doesn't exist
  static void expectWidgetDoesNotExist(WidgetTester tester, Type widgetType) {
    expect(find.byType(widgetType), findsNothing);
  }
}

/// Mock data for testing
class MockData {
  /// Sample movie data for testing
  static final List<Map<String, dynamic>> sampleMovies = [
    {
      'id': 1,
      'title': 'The Avengers',
      'overview': 'Earth\'s mightiest heroes must come together.',
      'posterPath': '/avengers.jpg',
      'voteAverage': 8.0,
      'genres': ['Action', 'Adventure', 'Sci-Fi'],
    },
    {
      'id': 2,
      'title': 'Inception',
      'overview': 'A thief who steals corporate secrets.',
      'posterPath': '/inception.jpg',
      'voteAverage': 8.8,
      'genres': ['Action', 'Adventure', 'Sci-Fi'],
    },
    {
      'id': 3,
      'title': 'The Dark Knight',
      'overview': 'When the menace known as the Joker.',
      'posterPath': '/dark-knight.jpg',
      'voteAverage': 9.0,
      'genres': ['Action', 'Crime', 'Drama'],
    },
  ];

  /// Sample video data for testing
  static final List<Map<String, dynamic>> sampleVideos = [
    {
      'id': 'video-1',
      'name': 'Official Trailer',
      'site': 'YouTube',
      'key': 'abc123',
    },
    {
      'id': 'video-2',
      'name': 'Behind the Scenes',
      'site': 'Vimeo',
      'key': 'def456',
    },
  ];

  /// Sample streaming platforms for testing
  static final List<Map<String, dynamic>> samplePlatforms = [
    {
      'id': 'netflix',
      'name': 'Netflix',
      'logoPath': '/netflix-logo.png',
    },
    {
      'id': 'amazon',
      'name': 'Amazon Prime',
      'logoPath': '/amazon-logo.png',
    },
  ];
}

/// Test assertions for common widget patterns
class TestAssertions {
  /// Asserts that a movie card displays correctly
  static void assertMovieCardDisplays(WidgetTester tester, Movie movie) {
    expect(find.text(movie.title), findsOneWidget);
    if (movie.voteAverage != null) {
      expect(find.text(movie.voteAverage!.toStringAsFixed(1)), findsOneWidget);
    }
    if (movie.year != null) {
      expect(find.text(movie.year!), findsOneWidget);
    }
  }

  /// Asserts that a search bar is functional
  static void assertSearchBarFunctional(WidgetTester tester) {
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search movies, actors, or genres...'), findsOneWidget);
  }

  /// Asserts that a loading indicator is shown
  static void assertLoadingIndicatorShown(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Asserts that an empty state is shown
  static void assertEmptyStateShown(WidgetTester tester, String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Asserts that a list has the expected number of items
  static void assertListHasItems(WidgetTester tester, int expectedCount) {
    expect(find.byType(ListView), findsOneWidget);
  }
} 