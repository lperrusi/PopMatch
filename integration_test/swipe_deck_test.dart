import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/tv_show.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/swipe_screen.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/retro_cinema_movie_card.dart';
import 'package:popmatch/widgets/retro_cinema_show_card.dart';

/// Exercises the Discover swipe deck with a seeded [MovieProvider] (no TMDB).
///
/// Run on host (fast):
///   flutter test integration_test/swipe_deck_test.dart
///
/// Run on a device/simulator:
///   flutter test integration_test/swipe_deck_test.dart -d <deviceId>
///
/// Related commands (repo root):
///   flutter test integration_test/swipe_like_integration_test.dart
///   flutter test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Swipe deck (integration)', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    setUp(() {
      TMDBService.setTestMode(true);
      RetroCinemaMovieCard.disableAsyncColorExtraction = true;
      SwipeScreen.debugDisableBufferMaintenance = true;
    });

    tearDown(() {
      RetroCinemaMovieCard.disableAsyncColorExtraction = false;
      SwipeScreen.debugDisableBufferMaintenance = false;
    });

    List<Movie> testDeck() {
      return <Movie>[
        Movie(
          id: 91001,
          title: 'Integration Deck A',
          overview: 'a',
          releaseDate: '2020-01-01',
          genreIds: const <int>[28],
        ),
        Movie(
          id: 91002,
          title: 'Integration Deck B',
          overview: 'b',
          releaseDate: '2020-01-02',
          genreIds: const <int>[28],
        ),
        Movie(
          id: 91003,
          title: 'Integration Deck C',
          overview: 'c',
          releaseDate: '2020-01-03',
          genreIds: const <int>[28],
        ),
      ];
    }

    Widget harness(MovieProvider movieProvider) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
          ChangeNotifierProvider<ShowProvider>(create: (_) => ShowProvider()),
          ChangeNotifierProvider<RecommendationsProvider>(
            create: (_) => RecommendationsProvider(),
          ),
          ChangeNotifierProvider<StreamingProvider>(
            create: (_) => StreamingProvider(),
          ),
          ChangeNotifierProvider<SocialProvider>(
            create: (_) => SocialProvider(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          home: const SwipeScreen(),
        ),
      );
    }

    testWidgets('removeMovie keeps front card aligned with keyed swiper',
        (WidgetTester tester) async {
      final movieProvider = MovieProvider()
        ..replaceSwipeDeckForTest(testDeck());

      await tester.pumpWidget(harness(movieProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Integration Deck A'), findsWidgets);

      movieProvider.removeMovie(91001, user: null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Integration Deck A'), findsNothing);
      expect(find.text('Integration Deck B'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('skip swipe shows next seeded title',
        (WidgetTester tester) async {
      final movieProvider = MovieProvider()
        ..replaceSwipeDeckForTest(testDeck());

      await tester.pumpWidget(harness(movieProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final Finder movieSwiper = find.byKey(const ValueKey<int>(91001));
      expect(movieSwiper, findsOneWidget);
      expect(find.byType(CardSwiper), findsOneWidget);

      await tester.drag(movieSwiper, const Offset(0, 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Integration Deck B'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'non-last skip swipe shows floating SnackBar: Swipe recorded + UNDO',
        (WidgetTester tester) async {
      final movieProvider = MovieProvider()
        ..replaceSwipeDeckForTest(testDeck());

      await tester.pumpWidget(harness(movieProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final Finder movieSwiper = find.byKey(const ValueKey<int>(91001));
      expect(movieSwiper, findsOneWidget);

      await tester.drag(movieSwiper, const Offset(0, 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Integration Deck B'), findsWidgets);
      expect(find.text('Swipe recorded'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('last remaining card skip does not show undo SnackBar',
        (WidgetTester tester) async {
      final singleDeck = <Movie>[
        Movie(
          id: 91099,
          title: 'Integration Deck Only',
          overview: 'x',
          releaseDate: '2020-01-01',
          genreIds: const <int>[28],
        ),
      ];
      final movieProvider = MovieProvider()
        ..replaceSwipeDeckForTest(singleDeck);


      await tester.pumpWidget(harness(movieProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final Finder movieSwiper = find.byKey(const ValueKey<int>(91099));
      expect(movieSwiper, findsOneWidget);

      await tester.drag(movieSwiper, const Offset(0, 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Swipe recorded'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Shows swipe deck (integration)', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    setUp(() {
      TMDBService.setTestMode(true);
      RetroCinemaMovieCard.disableAsyncColorExtraction = true;
      RetroCinemaShowCard.disableAsyncColorExtraction = true;
      SwipeScreen.debugDisableBufferMaintenance = true;
    });

    tearDown(() {
      RetroCinemaMovieCard.disableAsyncColorExtraction = false;
      RetroCinemaShowCard.disableAsyncColorExtraction = false;
      SwipeScreen.debugDisableBufferMaintenance = false;
    });

    List<TvShow> testShowDeck() {
      return <TvShow>[
        TvShow(
          id: 92001,
          name: 'Show Alpha',
          overview: 'a',
          firstAirDate: '2020-01-01',
          genreIds: const <int>[18],
          voteAverage: 8.0,
        ),
        TvShow(
          id: 92002,
          name: 'Show Beta',
          overview: 'b',
          firstAirDate: '2021-01-01',
          genreIds: const <int>[18],
          voteAverage: 7.5,
        ),
        TvShow(
          id: 92003,
          name: 'Show Gamma',
          overview: 'c',
          firstAirDate: '2022-01-01',
          genreIds: const <int>[18],
          voteAverage: 7.0,
        ),
      ];
    }

    Widget showHarness(ShowProvider showProvider) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider<MovieProvider>(
            create: (_) => MovieProvider()..replaceSwipeDeckForTest([
              Movie(
                id: 99001,
                title: 'Filler Movie',
                overview: 'x',
                releaseDate: '2020-01-01',
                genreIds: const <int>[28],
              ),
            ]),
          ),
          ChangeNotifierProvider<ShowProvider>.value(value: showProvider),
          ChangeNotifierProvider<RecommendationsProvider>(
            create: (_) => RecommendationsProvider(),
          ),
          ChangeNotifierProvider<StreamingProvider>(
            create: (_) => StreamingProvider(),
          ),
          ChangeNotifierProvider<SocialProvider>(
            create: (_) => SocialProvider(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          home: const SwipeScreen(),
        ),
      );
    }

    testWidgets('Shows tab renders seeded show cards',
        (WidgetTester tester) async {
      final showProvider = ShowProvider()
        ..replaceSwipeDeckForTest(testShowDeck());

      await tester.pumpWidget(showHarness(showProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Switch to SHOWS tab
      await tester.tap(find.text('SHOWS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Show Alpha'), findsWidgets);
      expect(find.byType(CardSwiper), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Shows tab: removeShow keeps front card aligned',
        (WidgetTester tester) async {
      final showProvider = ShowProvider()
        ..replaceSwipeDeckForTest(testShowDeck());

      await tester.pumpWidget(showHarness(showProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Switch to SHOWS tab
      await tester.tap(find.text('SHOWS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Show Alpha'), findsWidgets);

      showProvider.removeShow(92001, user: null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Show Alpha'), findsNothing);
      expect(find.text('Show Beta'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TMDB test mode returns sample shows (not empty)',
        (WidgetTester tester) async {
      // This regression test ensures getPopularShows returns sample data in
      // test mode, not [], which was the original bug that starved the shows tab.
      final shows = await TMDBService().getPopularShows();
      expect(shows, isNotEmpty);
      expect(shows.first.name, isNotEmpty);
    });
  });
}
