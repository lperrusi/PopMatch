import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/utils/recommendation_reason.dart';

void main() {
  const genres = {28: 'Action', 878: 'Sci-Fi', 35: 'Comedy'};

  group('buildRecommendationReason', () {
    test('genre intersection → becauseYouLikeGenre with the matched name', () {
      final r = buildRecommendationReason(
        strategy: 'trending', // overridden by the specific genre match
        genreIds: [12, 878, 28],
        userGenreIds: {878, 99},
        genres: genres,
      );
      expect(r.kind, RecommendationReasonKind.becauseYouLikeGenre);
      expect(r.genreName, 'Sci-Fi');
    });

    test('picks the first matching genre in the title order', () {
      final r = buildRecommendationReason(
        strategy: null,
        genreIds: [28, 878],
        userGenreIds: {878, 28},
        genres: genres,
      );
      expect(r.kind, RecommendationReasonKind.becauseYouLikeGenre);
      expect(r.genreName, 'Action');
    });

    test('matched genre not in the names map → falls back to strategy', () {
      final r = buildRecommendationReason(
        strategy: 'top_rated',
        genreIds: [99],
        userGenreIds: {99},
        genres: genres, // 99 not present
      );
      expect(r.kind, RecommendationReasonKind.topRated);
      expect(r.genreName, isNull);
    });

    test('no genre match → strategy fallback (popular maps to trending)', () {
      final r = buildRecommendationReason(
        strategy: 'popular',
        genreIds: [12],
        userGenreIds: {878},
        genres: genres,
      );
      expect(r.kind, RecommendationReasonKind.trending);
    });

    test('embedding/contentBased → personalized', () {
      expect(
        buildRecommendationReason(
                strategy: 'embedding',
                genreIds: null,
                userGenreIds: {},
                genres: genres)
            .kind,
        RecommendationReasonKind.personalized,
      );
      expect(
        buildRecommendationReason(
                strategy: 'contentBased',
                genreIds: const [],
                userGenreIds: {28},
                genres: genres)
            .kind,
        RecommendationReasonKind.personalized,
      );
    });

    test('unknown/null strategy with no genre match → none', () {
      expect(
        buildRecommendationReason(
                strategy: null,
                genreIds: null,
                userGenreIds: {},
                genres: genres)
            .kind,
        RecommendationReasonKind.none,
      );
      expect(
        buildRecommendationReason(
                strategy: 'mystery',
                genreIds: [12],
                userGenreIds: {28},
                genres: genres)
            .kind,
        RecommendationReasonKind.none,
      );
    });
  });
}
