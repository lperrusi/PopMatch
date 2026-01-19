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
  group('PopMatch Widget Tests', () {
    // Mock data for testing
    final testMovie = Movie(
      id: 1,
      title: 'Complete Movie',
      overview: 'A complete movie for testing',
      posterPath: '/test-poster.jpg',
      backdropPath: '/test-backdrop.jpg',
      releaseDate: '2023-01-01',
      voteAverage: 8.5,
      voteCount: 1000,
      popularity: 100.0,
      genreIds: [28, 12],
      isAdult: false,
      video: false,
      originalLanguage: 'en',
      originalTitle: 'Complete Movie',
      genres: ['Action', 'Adventure'],
    );

    final testVideo = Video(
      id: 'test-video-1',
      name: 'Official Trailer',
      key: 'test-key',
      site: 'YouTube',
      size: 1080,
      type: 'Trailer',
      official: 'true',
      publishedAt: '2023-01-01',
    );

    final testPlatform = StreamingPlatform(
      id: 'netflix',
      name: 'Netflix',
      logoPath: '/netflix-logo.png',
    );

    group('MovieCard Widget', () {
      testWidgets('should display movie information correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: MovieCard(
                  movie: testMovie,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Complete Movie'), findsOneWidget);
        expect(find.text('8.5'), findsOneWidget);
      });

      testWidgets('should call onTap when tapped', (WidgetTester tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: MovieCard(
                  movie: testMovie,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MovieCard));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('should display movie with no rating', (WidgetTester tester) async {
        final movieWithoutRating = testMovie.copyWith(voteAverage: null);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: MovieCard(
                  movie: movieWithoutRating,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Complete Movie'), findsOneWidget);
        expect(find.text('8.5'), findsNothing);
      });

      testWidgets('should handle movie with long title', (WidgetTester tester) async {
        final movieWithLongTitle = testMovie.copyWith(
          title: 'This is a very long movie title that should be truncated in the UI',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: MovieCard(
                  movie: movieWithLongTitle,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('This is a very long movie title that should be truncated in the UI'), findsOneWidget);
      });
    });

    group('SearchBarWidget', () {
      testWidgets('should display search bar with hint text', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Search...'), findsOneWidget);
      });

      testWidgets('should call onSearch when submitted', (WidgetTester tester) async {
        String? searchQuery;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) => searchQuery = query,
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'action movie');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(searchQuery, equals('action movie'));
      });

      testWidgets('should call onClear when clear button is tapped', (WidgetTester tester) async {
        bool clearCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) {},
                  onClear: () => clearCalled = true,
                ),
              ),
            ),
          ),
        );

        // Enter text first to show clear button
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(clearCalled, isTrue);
      });
    });

    group('SearchResultsWidget', () {
      testWidgets('should display search results', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: SearchResultsWidget(
                  movies: [testMovie],
                  isLoading: false,
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Complete Movie'), findsOneWidget);
      });

      testWidgets('should show loading state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: SearchResultsWidget(
                  movies: [],
                  isLoading: true,
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show empty state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: SearchResultsWidget(
                  movies: [],
                  isLoading: false,
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('No movies found'), findsOneWidget);
      });
    });

    group('SearchSuggestionsWidget', () {
      testWidgets('should display search suggestions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: SearchSuggestionsWidget(
                  suggestions: ['Action', 'Adventure', 'Comedy'],
                  onSuggestionTap: (suggestion) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Action'), findsOneWidget);
        expect(find.text('Adventure'), findsOneWidget);
        expect(find.text('Comedy'), findsOneWidget);
      });

      testWidgets('should call onSuggestionTap when suggestion is tapped', (WidgetTester tester) async {
        String? tappedSuggestion;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: SearchSuggestionsWidget(
                  suggestions: ['Action', 'Adventure'],
                  onSuggestionTap: (suggestion) => tappedSuggestion = suggestion,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Action'));
        await tester.pump();

        expect(tappedSuggestion, equals('Action'));
      });
    });

    group('CastMemberCard', () {
      testWidgets('should display cast member information', (WidgetTester tester) async {
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
                width: 150,
                height: 200,
                child: CastMemberCard(
                  castMember: castMember,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Hero'), findsOneWidget);
      });

      testWidgets('should call onTap when tapped', (WidgetTester tester) async {
        final castMember = CastMember(
          id: 1,
          name: 'John Doe',
          character: 'Hero',
          profilePath: '/profile.jpg',
          order: 1,
        );

        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 150,
                height: 200,
                child: CastMemberCard(
                  castMember: castMember,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(CastMemberCard));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });

    group('CrewMemberCard', () {
      testWidgets('should display crew member information', (WidgetTester tester) async {
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
                width: 150,
                height: 200,
                child: CrewMemberCard(
                  crewMember: crewMember,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

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
                width: 300,
                height: 200,
                child: RecommendationsWidget(
                  title: 'Recommended Movies',
                  movies: [testMovie],
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Recommended Movies'), findsOneWidget);
      });

      testWidgets('should display movie in recommendations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: RecommendationsWidget(
                  title: 'Recommended Movies',
                  movies: [testMovie],
                  onMovieTap: (movie) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Complete Movie'), findsOneWidget);
      });

      testWidgets('should call onMovieTap when movie is tapped', (WidgetTester tester) async {
        Movie? tappedMovie;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: RecommendationsWidget(
                  title: 'Recommended Movies',
                  movies: [testMovie],
                  onMovieTap: (movie) => tappedMovie = movie,
                ),
              ),
            ),
          ),
        );

        // Find and tap the movie card within the recommendations
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        expect(tappedMovie, equals(testMovie));
      });
    });

    group('StreamingPlatformLogo Widget', () {
      testWidgets('should display streaming platform logo', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                height: 100,
                child: StreamingPlatformLogo(
                  platform: testPlatform,
                  showName: true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Netflix'), findsOneWidget);
      });

      testWidgets('should display platform without name', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                height: 100,
                child: StreamingPlatformLogo(
                  platform: testPlatform,
                  showName: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Netflix'), findsNothing);
      });
    });

    group('VideoPlayerWidget', () {
      testWidgets('should display video player for YouTube video', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: VideoPlayerWidget(
                  video: testVideo,
                ),
              ),
            ),
          ),
        );

        // Wait for video to initialize
        await tester.pump(const Duration(seconds: 1));
        
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
                width: 300,
                height: 200,
                child: VideoPlayerWidget(
                  video: nonYouTubeVideo,
                ),
              ),
            ),
          ),
        );

        // Wait for video to initialize
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.text('Vimeo Trailer'), findsOneWidget);
      });
    });

    group('Basic Integration Tests', () {
      testWidgets('should handle movie card with basic features', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: MovieCard(
                  movie: testMovie,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Check that the movie title is displayed (there might be multiple instances)
        expect(find.text('Complete Movie'), findsWidgets);
      });

      testWidgets('should handle search bar functionality', (WidgetTester tester) async {
        String? searchQuery;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SearchBarWidget(
                  onSearch: (query) => searchQuery = query,
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