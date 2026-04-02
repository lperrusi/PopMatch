import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/models/movie.dart';
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

/// Exercises the Discover swipe deck with a seeded [MovieProvider] (no TMDB).
///
/// Run on host (fast):
///   flutter test integration_test/swipe_deck_test.dart
///
/// Run on a device/simulator:
///   flutter test integration_test/swipe_deck_test.dart -d <deviceId>
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
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());

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

    testWidgets('skip swipe shows next seeded title', (WidgetTester tester) async {
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());

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
  });
}
