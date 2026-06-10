import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/utils/detail_actions.dart';

void main() {
  group('buildShareText', () {
    test('movie: 🎬, Year label, no seasons/episodes, "movie" noun', () {
      final text = buildShareText(
        isShow: false,
        title: 'The Matrix',
        overview: 'A hacker learns the truth.',
        rating: '8.2',
        year: '1999',
        genres: ['Action', 'Sci-Fi'],
      );
      expect(text, contains('🎬 The Matrix'));
      expect(text, contains('📅 Year: 1999'));
      expect(text, contains('🎭 Genres: Action, Sci-Fi'));
      expect(text, contains('Check out this movie on PopMatch!'));
      expect(text, isNot(contains('Seasons')));
      expect(text, isNot(contains('First Aired')));
    });

    test('show: 📺, First Aired, seasons + episodes, "show" noun', () {
      final text = buildShareText(
        isShow: true,
        title: 'Breaking Bad',
        overview: 'A teacher turns to crime.',
        rating: '9.5',
        year: '2008',
        genres: ['Drama'],
        seasons: 5,
        episodes: 62,
      );
      expect(text, contains('📺 Breaking Bad'));
      expect(text, contains('📅 First Aired: 2008'));
      expect(text, contains('📚 Seasons: 5'));
      expect(text, contains('🎬 Episodes: 62'));
      expect(text, contains('Check out this show on PopMatch!'));
    });

    test('falls back gracefully on missing fields', () {
      final text = buildShareText(
        isShow: false,
        title: 'Untitled',
        rating: 'N/A',
      );
      expect(text, contains('No description available'));
      expect(text, contains('📅 Year: Unknown'));
      expect(text, contains('🎭 Genres: Unknown'));
    });

    test('show omits seasons/episodes lines when null', () {
      final text = buildShareText(
        isShow: true,
        title: 'Pilot Only',
        rating: '7.0',
        year: '2024',
      );
      expect(text, isNot(contains('Seasons')));
      expect(text, isNot(contains('Episodes')));
    });
  });
}
