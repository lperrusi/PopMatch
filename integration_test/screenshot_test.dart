import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/auth/login_screen.dart';
import 'package:popmatch/screens/auth/register_screen.dart';
import 'package:popmatch/screens/home/favorites_screen.dart';
import 'package:popmatch/screens/home/profile_screen.dart';
import 'package:popmatch/screens/home/search_screen.dart';
import 'package:popmatch/screens/home/swipe_screen.dart';
import 'package:popmatch/screens/home/watchlist_screen.dart';
import 'package:popmatch/screens/onboarding/onboarding_screen.dart';
import 'package:popmatch/screens/splash_screen.dart';
import 'package:popmatch/screens/tutorial/tutorial_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/retro_cinema_movie_card.dart';

/// Screenshot capture for all key PopMatch screens.
///
/// Run on a connected device or simulator:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d <device-id>
///
/// Output: screenshots/app-screens/*.png (18 files)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
    RetroCinemaMovieCard.disableAsyncColorExtraction = true;
    SwipeScreen.debugDisableBufferMaintenance = true;
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
    FirebaseConfig.setTestMode(false);
    RetroCinemaMovieCard.disableAsyncColorExtraction = false;
    SwipeScreen.debugDisableBufferMaintenance = false;
  });

  // ─── Seed data ────────────────────────────────────────────────────────────

  List<Movie> testDeck() => [
        Movie(
          id: 91001,
          title: 'The Grand Illusion',
          overview: 'A timeless wartime drama.',
          releaseDate: '1937-06-04',
          genreIds: const <int>[18],
          voteAverage: 8.1,
        ),
        Movie(
          id: 91002,
          title: 'Metropolis',
          overview: 'A visionary sci-fi classic.',
          releaseDate: '1927-03-13',
          genreIds: const <int>[878],
          voteAverage: 8.3,
        ),
        Movie(
          id: 91003,
          title: 'Casablanca',
          overview: 'Romance and intrigue in wartime Morocco.',
          releaseDate: '1942-11-26',
          genreIds: const <int>[10749, 18],
          voteAverage: 8.5,
        ),
      ];

  User emptyUser() => User(
        id: 'screenshot-user',
        email: 'demo@popmatch.app',
        displayName: 'Demo User',
        watchlist: const [],
        likedMovies: const [],
        preferences: const {'onboardingCompleted': true},
      );

  User fullUser() => User(
        id: 'screenshot-user',
        email: 'demo@popmatch.app',
        displayName: 'Demo User',
        watchlist: const ['91001', '91002', '91003'],
        likedMovies: const ['91001', '91002', '91003'],
        preferences: const {'onboardingCompleted': true},
      );

  // ─── Harness ──────────────────────────────────────────────────────────────

  Widget harness({
    required Widget child,
    AuthProvider? authProvider,
    MovieProvider? movieProvider,
  }) {
    final auth = authProvider ?? AuthProvider();
    final movies = movieProvider ??
        (MovieProvider()
          ..setTestGenres(
              const {28: 'Action', 18: 'Drama', 878: 'Sci-Fi', 10749: 'Romance'}));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<MovieProvider>.value(value: movies),
        ChangeNotifierProvider<ShowProvider>(create: (_) => ShowProvider()),
        ChangeNotifierProvider<RecommendationsProvider>(
            create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider<StreamingProvider>(
            create: (_) => StreamingProvider()),
        ChangeNotifierProvider<SocialProvider>(
            create: (_) => SocialProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.retroCinemaTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    Duration settle = const Duration(seconds: 2),
  }) async {
    await tester.pumpAndSettle(settle);
    await binding.takeScreenshot(name);
  }

  // ─── SplashScreen ─────────────────────────────────────────────────────────

  testWidgets('01_splash_screen', (tester) async {
    await tester.pumpWidget(harness(child: const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot('01_splash_screen');
  });

  // ─── TutorialScreen ───────────────────────────────────────────────────────

  testWidgets('02-04 tutorial pages', (tester) async {
    await tester.pumpWidget(harness(child: const TutorialScreen()));
    await shot(tester, '02_tutorial_page1');

    // Swipe to page 2
    await tester.drag(
        find.byType(PageView).first, const Offset(-400, 0));
    await shot(tester, '03_tutorial_page2');

    // Swipe to page 3
    await tester.drag(
        find.byType(PageView).first, const Offset(-400, 0));
    await shot(tester, '04_tutorial_page3');
  });

  // ─── Auth screens ─────────────────────────────────────────────────────────

  testWidgets('05_login_screen', (tester) async {
    await tester.pumpWidget(harness(child: const LoginScreen()));
    await shot(tester, '05_login_screen');
  });

  testWidgets('06_register_screen', (tester) async {
    await tester.pumpWidget(harness(child: const RegisterScreen()));
    await shot(tester, '06_register_screen');
  });

  // ─── OnboardingScreen ─────────────────────────────────────────────────────

  testWidgets('07-09 onboarding pages', (tester) async {
    final movies = MovieProvider()
      ..setTestGenres(const {
        28: 'Action',
        18: 'Drama',
        35: 'Comedy',
        878: 'Sci-Fi',
        10749: 'Romance',
        27: 'Horror',
      });
    await tester.pumpWidget(harness(
      child: const OnboardingScreen(),
      movieProvider: movies,
    ));
    await shot(tester, '07_onboarding_welcome');

    // Next page (genres)
    final nextButtons = find.byType(ElevatedButton);
    if (nextButtons.evaluate().isNotEmpty) {
      await tester.tap(nextButtons.first);
    } else {
      await tester.drag(find.byType(PageView).first, const Offset(-400, 0));
    }
    await shot(tester, '08_onboarding_genres');

    // Next page (platforms)
    if (nextButtons.evaluate().isNotEmpty) {
      await tester.tap(nextButtons.first);
    } else {
      await tester.drag(find.byType(PageView).first, const Offset(-400, 0));
    }
    await shot(tester, '09_onboarding_platforms');
  });

  // ─── SwipeScreen ──────────────────────────────────────────────────────────

  testWidgets('10_swipe_screen', (tester) async {
    final movies = MovieProvider()
      ..setTestGenres(const {28: 'Action', 18: 'Drama', 878: 'Sci-Fi'})
      ..replaceSwipeDeckForTest(testDeck());
    await tester.pumpWidget(harness(child: const SwipeScreen(), movieProvider: movies));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot('10_swipe_screen');
  });

  testWidgets('11_swipe_screen_undo', (tester) async {
    final movies = MovieProvider()
      ..setTestGenres(const {28: 'Action', 18: 'Drama', 878: 'Sci-Fi'})
      ..replaceSwipeDeckForTest(testDeck());
    await tester.pumpWidget(harness(child: const SwipeScreen(), movieProvider: movies));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Skip swipe (down) to trigger the "Swipe recorded / UNDO" SnackBar
    final card = find.byKey(const ValueKey<int>(91001));
    if (card.evaluate().isNotEmpty) {
      await tester.drag(card, const Offset(0, 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }
    await binding.takeScreenshot('11_swipe_screen_undo');
  });

  // ─── SearchScreen ─────────────────────────────────────────────────────────

  testWidgets('12_search_screen', (tester) async {
    await tester.pumpWidget(harness(child: const SearchScreen()));
    await shot(tester, '12_search_screen');
  });

  // ─── WatchlistScreen ──────────────────────────────────────────────────────

  testWidgets('13_watchlist_empty', (tester) async {
    final auth = AuthProvider()..setTestUserData(emptyUser());
    await tester.pumpWidget(harness(
      child: const WatchlistScreen(),
      authProvider: auth,
    ));
    await shot(tester, '13_watchlist_empty');
  });

  testWidgets('14_watchlist_full', (tester) async {
    final auth = AuthProvider()..setTestUserData(fullUser());
    final movies = MovieProvider()
      ..setTestGenres(const {28: 'Action', 18: 'Drama', 878: 'Sci-Fi'})
      ..replaceSwipeDeckForTest(testDeck());
    await tester.pumpWidget(harness(
      child: const WatchlistScreen(),
      authProvider: auth,
      movieProvider: movies,
    ));
    await shot(tester, '14_watchlist_full');
  });

  // ─── FavoritesScreen ──────────────────────────────────────────────────────

  testWidgets('15_favorites_empty', (tester) async {
    final auth = AuthProvider()..setTestUserData(emptyUser());
    await tester.pumpWidget(harness(
      child: const FavoritesScreen(),
      authProvider: auth,
    ));
    await shot(tester, '15_favorites_empty');
  });

  testWidgets('16_favorites_full', (tester) async {
    final auth = AuthProvider()..setTestUserData(fullUser());
    final movies = MovieProvider()
      ..setTestGenres(const {28: 'Action', 18: 'Drama', 878: 'Sci-Fi'})
      ..replaceSwipeDeckForTest(testDeck());
    await tester.pumpWidget(harness(
      child: const FavoritesScreen(),
      authProvider: auth,
      movieProvider: movies,
    ));
    await shot(tester, '16_favorites_full');
  });

  // ─── ProfileScreen ────────────────────────────────────────────────────────

  testWidgets('17_profile_screen', (tester) async {
    final auth = AuthProvider()..setTestUserData(fullUser());
    await tester.pumpWidget(harness(
      child: const ProfileScreen(),
      authProvider: auth,
    ));
    await shot(tester, '17_profile_screen');
  });

}
