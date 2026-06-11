import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/widgets/retro_cinema_movie_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TMDBService.setTestMode(true);
    RetroCinemaMovieCard.disableAsyncColorExtraction = true;
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
    RetroCinemaMovieCard.disableAsyncColorExtraction = false;
  });

  Widget wrap(Widget child) {
    final movieProvider = MovieProvider()
      ..setTestGenres(const {28: 'Action', 878: 'Science Fiction'});
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
        ChangeNotifierProvider(create: (_) => StreamingProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 380, height: 680, child: child),
          ),
        ),
      ),
    );
  }

  final movie = Movie(
    id: 603,
    title: 'The Matrix',
    overview: 'A hacker learns the truth.',
    posterPath: '/p.jpg',
    releaseDate: '1999-03-31',
    runtime: 136,
    voteAverage: 8.2,
    genreIds: const [28, 878],
    genres: const ['Action', 'Science Fiction'],
  );

  testWidgets('friend-liked badge renders in-flow without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(wrap(
      RetroCinemaMovieCard(movie: movie, friendLikedLabel: 'Ava'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Badge renders in the content column (no longer an absolute overlay)…
    expect(find.text('Ava liked this'), findsOneWidget);
    // …with no layout overflow.
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('no badge when friendLikedLabel is null', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 760));
    await tester.pumpWidget(wrap(RetroCinemaMovieCard(movie: movie)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('liked this'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
