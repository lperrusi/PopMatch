import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:popmatch/screens/home/swipe_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/premium_service.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/discover_undo_snackbar.dart';
import 'package:popmatch/widgets/retro_cinema_movie_card.dart';

/// Host (flutter_tester) widget tests for the Discover UNDO flow.
///
/// Runs with `flutter test` (no device build). Asserts on the set of movie ids
/// currently shown in the deck (via [RetroCinemaMovieCard.movie]) rather than
/// rendered text, since only the front card paints its title detail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discover UNDO', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      TMDBService.setTestMode(true);
      FirebaseConfig.setTestMode(true);
      RetroCinemaMovieCard.disableAsyncColorExtraction = true;
      SwipeScreen.debugDisableBufferMaintenance = true;
    });

    tearDown(() {
      RetroCinemaMovieCard.disableAsyncColorExtraction = false;
      SwipeScreen.debugDisableBufferMaintenance = false;
      TMDBService.setTestMode(false);
      FirebaseConfig.setTestMode(false);
    });

    List<Movie> testDeck() => <Movie>[
          Movie(id: 91001, title: 'Undo Deck A', overview: 'a', releaseDate: '2020-01-01', genreIds: const <int>[28]),
          Movie(id: 91002, title: 'Undo Deck B', overview: 'b', releaseDate: '2020-01-02', genreIds: const <int>[28]),
          Movie(id: 91003, title: 'Undo Deck C', overview: 'c', releaseDate: '2020-01-03', genreIds: const <int>[28]),
        ];

    Widget harness(MovieProvider movieProvider, {AuthProvider? auth}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => auth ?? AuthProvider()),
          ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
          ChangeNotifierProvider<ShowProvider>(create: (_) => ShowProvider()),
          ChangeNotifierProvider<RecommendationsProvider>(create: (_) => RecommendationsProvider()),
          ChangeNotifierProvider<StreamingProvider>(create: (_) => StreamingProvider()),
          ChangeNotifierProvider<SocialProvider>(create: (_) => SocialProvider()),
          ChangeNotifierProvider<PremiumService>(create: (_) => PremiumService()),
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SwipeScreen(),
        ),
      );
    }

    Set<int> visibleMovieIds(WidgetTester tester) => tester
        .widgetList<RetroCinemaMovieCard>(find.byType(RetroCinemaMovieCard))
        .map((c) => c.movie.id)
        .toSet();

    // True when any undo banner is currently shown (visible). Only the movies
    // banner is built here since the shows deck is empty.
    bool bannerVisible(WidgetTester tester) => tester
        .widgetList<DiscoverSwipeFeedback>(find.byType(DiscoverSwipeFeedback))
        .any((w) => w.visible);

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> afterSwipe(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('tapping UNDO brings the swiped card back into the deck',
        (tester) async {
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());
      await tester.pumpWidget(harness(movieProvider));
      await settle(tester);

      expect(visibleMovieIds(tester), contains(91001));

      // Skip A → A leaves the visible stack, undo banner appears.
      await tester.drag(find.byKey(const ValueKey<int>(91001)), const Offset(0, 380));
      await afterSwipe(tester);
      expect(visibleMovieIds(tester), isNot(contains(91001)));
      expect(find.text('UNDO'), findsOneWidget);

      // Undo → A is back in the deck.
      await tester.tap(find.text('UNDO'));
      await afterSwipe(tester);
      expect(visibleMovieIds(tester), contains(91001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('removal is immediate and the undo banner auto-hides after 4s',
        (tester) async {
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());
      await tester.pumpWidget(harness(movieProvider));
      await settle(tester);

      await tester.drag(find.byKey(const ValueKey<int>(91001)), const Offset(0, 380));
      await afterSwipe(tester);

      // Removal happens immediately on swipe; the banner is shown for undo.
      expect(movieProvider.filteredMovies.any((m) => m.id == 91001), isFalse);
      expect(bannerVisible(tester), isTrue);

      // After the 4s window the banner auto-hides (removal already committed).
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(bannerVisible(tester), isFalse);
      expect(visibleMovieIds(tester), contains(91002));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rapid consecutive swipes advance to the correct next card',
        (tester) async {
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());
      await tester.pumpWidget(harness(movieProvider));
      await settle(tester);

      // Skip A, then skip the new front (B) before the timer fires. Removal is
      // immediate, so the swiper re-keys to the new front (91002) after swipe 1.
      await tester.drag(find.byKey(const ValueKey<int>(91001)), const Offset(0, 380));
      await afterSwipe(tester);
      await tester.drag(find.byKey(const ValueKey<int>(91002)), const Offset(0, 380));
      await afterSwipe(tester);

      // C must be visible; A and B must not have reappeared.
      final ids = visibleMovieIds(tester);
      expect(ids, contains(91003));
      expect(ids, isNot(contains(91001)));
      expect(ids, isNot(contains(91002)));

      await tester.pump(const Duration(seconds: 5)); // flush pending timer
      expect(tester.takeException(), isNull);
    });

    testWidgets('UNDO rolls back a like in auth state', (tester) async {
      final auth = AuthProvider()
        ..setTestUserData(User(id: 'u1', email: 'u@test.com', displayName: 'U'));
      final movieProvider = MovieProvider()..replaceSwipeDeckForTest(testDeck());
      await tester.pumpWidget(harness(movieProvider, auth: auth));
      await settle(tester);

      // Like A (swipe right).
      await tester.drag(find.byKey(const ValueKey<int>(91001)), const Offset(380, 0));
      await afterSwipe(tester);
      expect(auth.userData!.likedMovies.contains('91001'), isTrue);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await afterSwipe(tester);
      expect(auth.userData!.likedMovies.contains('91001'), isFalse);
      expect(visibleMovieIds(tester), contains(91001));
      expect(tester.takeException(), isNull);
    });
  });
}
