import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/utils/recommendation_filters.dart';

Movie movie({
  required int id,
  int voteCount = 500,
  double voteAverage = 7.5,
  String? posterPath = '/p.jpg',
  List<int>? genreIds,
}) {
  return Movie(
    id: id,
    title: 'M$id',
    overview: '',
    posterPath: posterPath,
    voteCount: voteCount,
    voteAverage: voteAverage,
    genreIds: genreIds,
  );
}

void main() {
  group('isQualityPick', () {
    test('accepts a well-rated, well-voted title with a poster', () {
      expect(isQualityPick(movie(id: 1)), isTrue);
    });
    test('rejects low vote count, low rating, or missing poster', () {
      expect(isQualityPick(movie(id: 1, voteCount: 10)), isFalse);
      expect(isQualityPick(movie(id: 1, voteAverage: 4.0)), isFalse);
      expect(isQualityPick(movie(id: 1, posterPath: null)), isFalse);
    });
  });

  group('filterForYou', () {
    test('excludes liked/disliked ids and de-dupes', () {
      final list = [
        movie(id: 1),
        movie(id: 2),
        movie(id: 2), // duplicate
        movie(id: 3),
      ];
      final out = filterForYou(list, excludeIds: {2});
      expect(out.map((m) => m.id), [1, 3]);
    });

    test('drops sub-quality titles', () {
      final list = [
        movie(id: 1, voteCount: 5),
        movie(id: 2, voteAverage: 3.0),
        movie(id: 3),
      ];
      final out = filterForYou(list, excludeIds: const {});
      expect(out.map((m) => m.id), [3]);
    });

    test('requireGenreOverlap keeps only on-genre titles', () {
      final list = [
        movie(id: 1, genreIds: const [28, 12]),
        movie(id: 2, genreIds: const [99]),
        movie(id: 3, genreIds: null),
      ];
      final out =
          filterForYou(list, excludeIds: const {}, requireGenreOverlap: {28});
      expect(out.map((m) => m.id), [1]);
    });
  });

  group('mostRecentLikedMovieId', () {
    test('returns the last valid id (likes are appended)', () {
      expect(mostRecentLikedMovieId(['10', '20', '30']), 30);
    });
    test('skips trailing non-numeric / blank entries', () {
      expect(mostRecentLikedMovieId(['10', '20', 'bad', '  ']), 20);
    });
    test('ignores non-positive ids', () {
      expect(mostRecentLikedMovieId(['5', '0', '-3']), 5);
    });
    test('returns null when there are no valid ids', () {
      expect(mostRecentLikedMovieId(const []), isNull);
      expect(mostRecentLikedMovieId(['', 'nope']), isNull);
    });
  });

  group('likedDislikedIds', () {
    test('parses and merges liked + disliked id strings', () {
      final ids = likedDislikedIds(
        liked: ['10', '20', 'bad'],
        disliked: ['30', '20'],
      );
      expect(ids, {10, 20, 30});
    });
  });
}
