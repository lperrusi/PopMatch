import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';

void main() {
  group('Recommendation preference enforcement helpers', () {
    late User userWithPreferences;

    setUp(() {
      userWithPreferences = User(
        id: 'user-1',
        email: 'user1@example.com',
        displayName: 'User One',
        watchlist: const [],
        preferences: {
          'selectedGenres': [28, '35', 'invalid', 28],
          'selectedPlatforms': ['8', 'Netflix', 'hulu', 'netflix', ''],
        },
      );
    });

    test('movie provider resolves selected genre ids from preferences', () {
      final provider = MovieProvider();
      final genreIds = provider.genreIdsFromUserPreferencesForTest(
        userWithPreferences,
      );

      expect(genreIds.toSet(), containsAll(<int>{28, 35}));
      expect(genreIds.length, genreIds.toSet().length);
    });

    test('movie provider resolves selected platform ids from ids or names', () {
      final provider = MovieProvider();
      final platformIds = provider.platformIdsFromUserPreferencesForTest(
        userWithPreferences,
      );

      expect(platformIds, contains('netflix'));
      expect(platformIds, contains('hulu'));
      expect(platformIds, isNot(contains('Netflix')));
      expect(platformIds.length, platformIds.toSet().length);
    });

    test('show provider resolves selected genre and platform preferences', () {
      final provider = ShowProvider();
      final genreIds = provider.genreIdsFromUserPreferencesForTest(
        userWithPreferences,
      );
      final platformIds = provider.platformIdsFromUserPreferencesForTest(
        userWithPreferences,
      );

      expect(genreIds.toSet(), containsAll(<int>{28, 35}));
      expect(platformIds, contains('netflix'));
      expect(platformIds, contains('hulu'));
      expect(platformIds.length, platformIds.toSet().length);
    });
  });
}
