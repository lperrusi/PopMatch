import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/tv_show.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/movie_detail_screen.dart';
import 'package:popmatch/screens/home/recommendations_screen.dart';
import 'package:popmatch/screens/home/show_detail_screen.dart';
import 'package:popmatch/screens/home/watchlist_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home tab smoke', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      TMDBService.setTestMode(true);
      FirebaseConfig.setTestMode(true);
    });

    tearDown(() {
      FirebaseConfig.setTestMode(false);
      TMDBService.setTestMode(false);
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
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          home: child,
        ),
      );
    }

    testWidgets('RecommendationsScreen shows Search chrome and empty state',
        (tester) async {
      await tester.pumpWidget(wrap(const RecommendationsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Search'), findsWidgets);
      expect(find.text('Search movies and shows'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

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
      );

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

      await tester.pumpWidget(wrap(ShowDetailScreen(show: show)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Smoke Test Show'), findsWidgets);
      expect(find.textContaining('TV overview for smoke'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
