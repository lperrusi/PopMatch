import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/providers/recommendations_provider.dart';

void main() {
  group('RecommendationsProvider interaction cache', () {
    late RecommendationsProvider provider;
    final movie = Movie(id: 42, title: 'Cache Test Movie');

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = RecommendationsProvider();
    });

    test('handleMovieLike marks movie as recently liked', () async {
      await provider.handleMovieLike(movie);

      expect(provider.isRecentlyLiked(movie.id), isTrue);
      expect(provider.isRecentlyInteracted(movie.id), isTrue);
      expect(provider.recentlyLikedCount, 1);
    });

    test('handleMovieSkip marks movie as recently skipped', () async {
      await provider.handleMovieSkip(movie);

      expect(provider.isRecentlySkipped(movie.id), isTrue);
      expect(provider.isRecentlyInteracted(movie.id), isTrue);
      expect(provider.recentlySkippedCount, 1);
    });
  });
}
