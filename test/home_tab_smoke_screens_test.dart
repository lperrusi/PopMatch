import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/tv_show.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/movie_detail_screen.dart';
import 'package:popmatch/screens/home/show_detail_screen.dart';
import 'package:popmatch/screens/home/watchlist_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/movie_cache_service.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/detail/detail_color_extraction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home tab smoke', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      TMDBService.setTestMode(true);
      FirebaseConfig.setTestMode(true);
      // Detail screens gate their reveal on poster-colour extraction, which
      // can't resolve against a real image in tests — skip it so they reach
      // the ready state.
      DetailColorExtractionMixin.disableForTest = true;
    });

    tearDown(() {
      FirebaseConfig.setTestMode(false);
      TMDBService.setTestMode(false);
      DetailColorExtractionMixin.disableForTest = false;
    });

    Widget wrap(Widget child, {AuthProvider? auth}) {
      final AuthProvider a;
      if (auth != null) {
        a = auth;
      } else {
        final created = AuthProvider();
        created.setTestUserData(
          User(
            id: 'smoke-user',
            email: 'smoke@test.com',
            displayName: 'Smoke',
          ),
        );
        a = created;
      }
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: a),
          ChangeNotifierProvider(create: (_) => MovieProvider()),
          ChangeNotifierProvider(create: (_) => ShowProvider()),
          ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
          ChangeNotifierProvider(create: (_) => StreamingProvider()),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets('WatchlistScreen shows WATCHLIST and empty copy', (tester) async {
      await tester.pumpWidget(wrap(const WatchlistScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('WATCHLIST'), findsOneWidget);
      expect(find.text('Your watchlist is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MovieDetailScreen shows title and overview', (tester) async {
      final movie = Movie(
        id: 424242,
        title: 'Smoke Test Movie',
        overview: 'Overview line for widget smoke test.',
        releaseDate: '2021-06-01',
        genreIds: const <int>[28],
        cast: const <CastMember>[],
      );
      // Seed the cache so the "reveal when ready" gate clears with this movie's
      // data (test mode otherwise returns a sample movie).
      MovieCacheService.instance.cacheMovieForTest(movie.id, movie);

      await tester.pumpWidget(wrap(MovieDetailScreen(movie: movie)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Smoke Test Movie'), findsWidgets);
      expect(find.textContaining('Overview line for widget'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShowDetailScreen shows name and overview', (tester) async {
      final show = TvShow(
        id: 919191,
        name: 'Smoke Test Show',
        overview: 'TV overview for smoke test.',
        firstAirDate: '2022-01-01',
        genreIds: const <int>[18],
      );
      // Seed the cache so the "reveal when ready" gate clears with this show's
      // data (test mode otherwise returns a sample show).
      MovieCacheService.instance.cacheShowForTest(show.id, show);

      await tester.pumpWidget(wrap(ShowDetailScreen(show: show)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Smoke Test Show'), findsWidgets);
      expect(find.textContaining('TV overview for smoke'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
