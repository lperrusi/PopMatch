import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/swipe_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/retro_cinema_movie_card.dart';

/// Right-swipe (like) on seeded Discover deck with a signed-in test user (no TMDB).
///
/// Run on a simulator/device:
///   flutter test integration_test/swipe_like_integration_test.dart -d <deviceId>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Swipe like (integration)', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    setUp(() {
      TMDBService.setTestMode(true);
      FirebaseConfig.setTestMode(true);
      RetroCinemaMovieCard.disableAsyncColorExtraction = true;
      SwipeScreen.debugDisableBufferMaintenance = true;
    });

    tearDown(() {
      RetroCinemaMovieCard.disableAsyncColorExtraction = false;
      SwipeScreen.debugDisableBufferMaintenance = false;
      FirebaseConfig.setTestMode(false);
    });

    List<Movie> testDeck() {
      return <Movie>[
        Movie(
          id: 92001,
          title: 'Like Deck A',
          overview: 'a',
          releaseDate: '2020-01-01',
          genreIds: const <int>[28],
        ),
        Movie(
          id: 92002,
          title: 'Like Deck B',
          overview: 'b',
          releaseDate: '2020-01-02',
          genreIds: const <int>[28],
        ),
      ];
    }

    Widget harness(MovieProvider movieProvider, AuthProvider authProvider) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
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

    testWidgets('right swipe advances deck after like', (WidgetTester tester) async {
      final auth = AuthProvider()
        ..setTestUserData(
          User(
            id: 'like-int',
            email: 'like@test.com',
            displayName: 'Like Test',
          ),
        );
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());

      await tester.pumpWidget(harness(movieProvider, auth));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Like Deck A'), findsWidgets);

      final Finder movieSwiper = find.byKey(const ValueKey<int>(92001));
      expect(movieSwiper, findsOneWidget);

      await tester.drag(movieSwiper, const Offset(380, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Like Deck B'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
