import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/video.dart';
import 'package:popmatch/models/streaming_platform.dart';
import 'package:popmatch/widgets/movie_card.dart';
import 'package:popmatch/widgets/search_bar_widget.dart';
import 'package:popmatch/widgets/search_results_widget.dart';
import 'package:popmatch/widgets/search_suggestions_widget.dart';
import 'package:popmatch/widgets/cast_crew_widget.dart';
import 'package:popmatch/widgets/recommendations_widget.dart';
import 'package:popmatch/widgets/streaming_platform_widget.dart';
import 'package:popmatch/widgets/video_player_widget.dart';

void main() {
  group('Enhanced PopMatch Widget Tests', () {
    // Enhanced test data with proper constraints
    late Movie testMovie;
    late Video testVideo;
    late StreamingPlatform testPlatform;

    setUp(() {
      testMovie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'A test movie for testing purposes',
        posterPath: '/test-poster.jpg',
        backdropPath: '/test-backdrop.jpg',
        voteAverage: 8.5,
        voteCount: 1000,
        popularity: 85.5,
        releaseDate: '2023-01-01',
        isAdult: false,
        video: false,
        originalLanguage: 'en',
        originalTitle: 'Test Movie',
        genres: ['Action', 'Adventure'],
      );

      testVideo = Video(
        id: 'test-video-1',
        name: 'Official Trailer',
        key: 'test-key',
        site: 'YouTube',
        size: 1080,
        type: 'Trailer',
        official: 'true',
        publishedAt: '2023-01-01',
      );

      testPlatform = StreamingPlatform(
        id: 'netflix',
        name: 'Netflix',
        logoPath: '/netflix-logo.png',
      );
    });

    group('MovieCard Widget', () {
      testWidgets('should display movie information correctly with proper constraints', (WidgetTester tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400, // Increased width to prevent overflow
                height: 600, // Increased height
                child: MovieCard(
                  movie: testMovie,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);
        expect(find.text('8.5'), findsOneWidget);
        expect(find.text('2023'), findsOneWidget);
        expect(tapped, isFalse);

        // Test tap functionality
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        expect(tapped, isTrue);
      });

      testWidgets('should handle movie with no rating', (WidgetTester tester) async {
        final movieWithoutRating = testMovie.copyWith(voteAverage: null);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: MovieCard(
                  movie: movieWithoutRating,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);
        expect(find.text('8.5'), findsNothing); // Should not find rating
        expect(find.text('2023'), findsOneWidget);
      });

      testWidgets('should handle movie with long title', (WidgetTester tester) async {
        final movieWithLongTitle = testMovie.copyWith(
          title: 'This is a very long movie title that should be truncated properly in the UI',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: MovieCard(
                  movie: movieWithLongTitle,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('This is a very long movie title that should be truncated properly in the UI'), findsOneWidget);
      });
    });

    group('SearchBarWidget', () {
      testWidgets('should display search bar correctly', (WidgetTester tester) async {
        String? searchQuery;
        bool cleared = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) => searchQuery = query,
                  onClear: () => cleared = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search movies, actors, or genres...'), findsOneWidget);
      });

      testWidgets('should call onSearch when text is submitted', (WidgetTester tester) async {
        String? searchQuery;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) => searchQuery = query,
                  onClear: () {},
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'action movies');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(searchQuery, equals('action movies'));
      });

      testWidgets('should call onClear when clear button is tapped', (WidgetTester tester) async {
        bool cleared = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) {},
                  onClear: () => cleared = true,
                ),
              ),
            ),
          ),
        );

        // Enter text to show clear button
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump();
        
        // Find and tap clear button
        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);
        
        await tester.tap(clearButton);
        await tester.pump();
        
        expect(cleared, isTrue);
      });
    });

    group('SearchResultsWidget', () {
      testWidgets('should display search results correctly', (WidgetTester tester) async {
        Movie? tappedMovie;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: SearchResultsWidget(
                  movies: [testMovie],
                  onMovieTap: (movie) => tappedMovie = movie,
                  isLoading: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);
        expect(find.text('8.5'), findsOneWidget);
      });

      testWidgets('should show loading state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: SearchResultsWidget(
                  movies: [],
                  onMovieTap: (movie) {},
                  isLoading: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show empty state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: SearchResultsWidget(
                  movies: [],
                  onMovieTap: (movie) {},
                  isLoading: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No movies found'), findsOneWidget);
      });
    });

    group('SearchSuggestionsWidget', () {
      testWidgets('should display suggestions correctly', (WidgetTester tester) async {
        String? selectedSuggestion;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: SearchSuggestionsWidget(
                  suggestions: ['action', 'adventure', 'comedy'],
                  onSuggestionTap: (suggestion) => selectedSuggestion = suggestion,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('action'), findsOneWidget);
        expect(find.text('adventure'), findsOneWidget);
        expect(find.text('comedy'), findsOneWidget);
      });

      testWidgets('should call onSuggestionTap when suggestion is tapped', (WidgetTester tester) async {
        String? selectedSuggestion;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: SearchSuggestionsWidget(
                  suggestions: ['action'],
                  onSuggestionTap: (suggestion) => selectedSuggestion = suggestion,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('action'));
        await tester.pump();

        expect(selectedSuggestion, equals('action'));
      });
    });

    group('CastCrewWidget', () {
      testWidgets('should display cast members correctly', (WidgetTester tester) async {
        final castMember = CastMember(
          id: 1,
          name: 'John Doe',
          character: 'Hero',
          profilePath: '/profile.jpg',
          order: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: CastMemberCard(
                  castMember: castMember,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Hero'), findsOneWidget);
      });

      testWidgets('should display crew members correctly', (WidgetTester tester) async {
        final crewMember = CrewMember(
          id: 1,
          name: 'Jane Smith',
          job: 'Director',
          department: 'Directing',
          profilePath: '/profile.jpg',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: CrewMemberCard(
                  crewMember: crewMember,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Director'), findsOneWidget);
      });
    });

    group('RecommendationsWidget', () {
      testWidgets('should display recommendations title', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300, // Increased height to prevent overflow
                child: RecommendationsWidget(
                  title: 'Recommendations',
                  movies: [testMovie],
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsOneWidget);
      });

      testWidgets('should display movie in recommendations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: RecommendationsWidget(
                  title: 'Recommendations',
                  movies: [testMovie],
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);
      });

      testWidgets('should call onMovieTap when movie is tapped', (WidgetTester tester) async {
        Movie? tappedMovie;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: RecommendationsWidget(
                  title: 'Recommendations',
                  movies: [testMovie],
                  onMovieTap: (movie) => tappedMovie = movie,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the movie card
        final movieCard = find.byType(GestureDetector).first;
        await tester.tap(movieCard);
        await tester.pump();

        expect(tappedMovie, equals(testMovie));
      });
    });

    group('StreamingPlatformLogo', () {
      testWidgets('should display platform logo with name', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 100,
                child: StreamingPlatformLogo(
                  platform: testPlatform,
                  showName: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Netflix'), findsOneWidget);
      });

      testWidgets('should display platform logo without name', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 100,
                child: StreamingPlatformLogo(
                  platform: testPlatform,
                  showName: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Netflix'), findsNothing);
      });
    });

    group('VideoPlayerWidget', () {
      testWidgets('should display video player for YouTube video', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300, // Increased height to prevent overflow
                child: VideoPlayerWidget(
                  video: testVideo,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2)); // Wait for initialization

        expect(find.text('Official Trailer'), findsOneWidget);
      });

      testWidgets('should handle non-YouTube videos', (WidgetTester tester) async {
        final nonYouTubeVideo = Video(
          id: 'test-video-2',
          name: 'Vimeo Trailer',
          key: 'test-key-2',
          site: 'Vimeo',
          size: 1080,
          type: 'Trailer',
          official: 'true',
          publishedAt: '2023-01-01',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: VideoPlayerWidget(
                  video: nonYouTubeVideo,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Vimeo Trailer'), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should handle movie card with basic features', (WidgetTester tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: MovieCard(
                  movie: testMovie,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Movie'), findsOneWidget);
        expect(tapped, isFalse);

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        expect(tapped, isTrue);
      });

      testWidgets('should handle search bar with basic features', (WidgetTester tester) async {
        String? searchQuery;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) => searchQuery = query,
                  onClear: () {},
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'test search');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(searchQuery, equals('test search'));
      });
    });
  });
} 