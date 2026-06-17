import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/tv_show.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/services/tmdb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TMDBService.setTestMode(true);
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
  });

  group('TvShow.fromSearchMovie', () {
    test('maps a TV-typed search Movie onto a TvShow', () {
      final movie = Movie(
        id: 1399,
        title: 'Game of Thrones',
        overview: 'Nine noble families fight for control.',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        voteAverage: 8.4,
        voteCount: 21000,
        releaseDate: '2011-04-17',
        genreIds: const [18, 10765],
        popularity: 350.0,
        originalTitle: 'Game of Thrones',
        originalLanguage: 'en',
        mediaType: 'tv',
      );

      final show = TvShow.fromSearchMovie(movie);

      expect(show.id, 1399);
      expect(show.name, 'Game of Thrones');
      expect(show.posterPath, '/poster.jpg');
      expect(show.backdropPath, '/backdrop.jpg');
      expect(show.firstAirDate, '2011-04-17');
      expect(show.voteAverage, 8.4);
      expect(show.genreIds, const [18, 10765]);
      expect(show.mediaType, 'tv');
    });
  });

  group('Search ranking + cleaning', () {
    late MovieProvider provider;

    Movie make(
      int id,
      String title, {
      double popularity = 1.0,
      double voteAverage = 5.0,
      int voteCount = 100,
      bool? isAdult,
      String? posterPath = '/p.jpg',
      String mediaType = 'movie',
    }) {
      return Movie(
        id: id,
        title: title,
        popularity: popularity,
        voteAverage: voteAverage,
        voteCount: voteCount,
        isAdult: isAdult,
        posterPath: posterPath,
        mediaType: mediaType,
      );
    }

    setUp(() {
      provider = MovieProvider();
    });

    test('exact title match outranks a more popular fuzzy match', () {
      final results = [
        make(1, 'Batman Begins', popularity: 200), // substring of nothing here
        make(2, 'Batman', popularity: 50), // exact match, less popular
      ];

      final ranked = provider.rankSearchResultsForTest(results, 'batman');

      expect(ranked.first.title, 'Batman');
    });

    test('prefix match outranks a substring-only match', () {
      final results = [
        make(1, 'The Dark Knight', popularity: 10), // contains "dark"
        make(2, 'Dark Waters', popularity: 10), // prefix "dark"
      ];

      final ranked = provider.rankSearchResultsForTest(results, 'dark');

      expect(ranked.first.title, 'Dark Waters');
    });

    test('drops adult content and poster-less stubs', () {
      final results = [
        make(1, 'Good Movie'),
        make(2, 'Adult Movie', isAdult: true),
        make(3, 'No Poster', posterPath: null),
        make(4, 'Empty Poster', posterPath: ''),
      ];

      final ranked = provider.rankSearchResultsForTest(results, 'movie');

      final titles = ranked.map((m) => m.title).toList();
      expect(titles, contains('Good Movie'));
      expect(titles, isNot(contains('Adult Movie')));
      expect(titles, isNot(contains('No Poster')));
      expect(titles, isNot(contains('Empty Poster')));
    });

    test('de-duplicates by media-type and id but keeps movie/tv with same id',
        () {
      final results = [
        make(100, 'Title A', mediaType: 'movie'),
        make(100, 'Title A dup', mediaType: 'movie'), // duplicate -> dropped
        make(100, 'Title A show', mediaType: 'tv'), // same id, different type
      ];

      final ranked = provider.rankSearchResultsForTest(results, 'title');

      expect(ranked.length, 2);
      expect(
        ranked.map((m) => m.mediaType).toSet(),
        {'movie', 'tv'},
      );
    });
  });
}
