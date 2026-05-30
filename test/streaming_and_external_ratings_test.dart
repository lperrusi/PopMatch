import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/streaming_platform.dart';
import 'package:popmatch/providers/movie_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreamingPlatform.idFromNameOrId (single source of truth)', () {
    test('canonical id maps to itself', () {
      expect(StreamingPlatform.idFromNameOrId('netflix'), 'netflix');
    });

    test('display name maps to canonical id', () {
      expect(StreamingPlatform.idFromNameOrId('Disney+'), 'disney_plus');
      expect(StreamingPlatform.idFromNameOrId('Amazon Prime'), 'amazon_prime');
      expect(StreamingPlatform.idFromNameOrId('YouTube TV'), 'youtube_tv');
    });

    test('unknown legacy value returns null (e.g. "YouTube Premium")', () {
      expect(StreamingPlatform.idFromNameOrId('YouTube Premium'), isNull);
      expect(StreamingPlatform.idFromNameOrId(''), isNull);
    });
  });

  group('OMDb external-quality fold-in', () {
    final provider = MovieProvider();

    Movie movie({double? imdb, int? rt}) => Movie(
          id: 1,
          title: 't',
          overview: '',
          releaseDate: '2020-01-01',
          imdbRating: imdb,
          rottenTomatoesTomatometer: rt,
        );

    test('null when the movie has no external ratings', () {
      expect(provider.externalQualityScoreForTest(movie()), isNull);
    });

    test('IMDb only → normalized 0-1', () {
      expect(provider.externalQualityScoreForTest(movie(imdb: 8.0)),
          closeTo(0.8, 1e-9));
    });

    test('blends IMDb and Rotten Tomatoes', () {
      expect(provider.externalQualityScoreForTest(movie(imdb: 8.0, rt: 90)),
          closeTo((0.8 + 0.9) / 2, 1e-9));
    });
  });
}
