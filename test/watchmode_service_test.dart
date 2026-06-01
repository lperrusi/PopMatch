import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/services/watchmode_service.dart';

void main() {
  // A trimmed sample of the Watchmode /sources/ payload shape.
  final sources = <dynamic>[
    {
      'name': 'Netflix',
      'type': 'sub',
      'region': 'US',
      'ios_url': 'nflx://title/100',
      'android_url': 'https://play.netflix/100',
      'web_url': 'https://www.netflix.com/title/100',
    },
    {
      'name': 'Apple TV', // rent on a different store
      'type': 'rent',
      'region': 'US',
      'web_url': 'https://tv.apple.com/title/200',
    },
    {
      'name': 'Max', // alias → hbo_max
      'type': 'sub',
      'region': 'US',
      'ios_url': '',
      'web_url': 'https://play.max.com/title/300',
    },
    {
      'name': 'Netflix', // wrong region — must be filtered out
      'type': 'sub',
      'region': 'GB',
      'ios_url': 'nflx://title/gb',
      'web_url': 'https://www.netflix.com/gb/title/gb',
    },
  ];

  group('WatchmodeService.deepLinkFromSources', () {
    test('prefers the native iOS link for a matching platform/region', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'netflix',
        preferIos: true,
        region: 'US',
      );
      expect(url, 'nflx://title/100');
    });

    test('falls back to web_url when the native link is empty', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'hbo_max', // matched via the "Max" alias
        preferIos: true,
        region: 'US',
      );
      expect(url, 'https://play.max.com/title/300');
    });

    test('uses android_url when preferIos is false', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'netflix',
        preferIos: false,
        region: 'US',
      );
      expect(url, 'https://play.netflix/100');
    });

    test('filters by region (no US Netflix → null for GB-only lookups)', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'netflix',
        preferIos: true,
        region: 'GB',
      );
      expect(url, 'nflx://title/gb');
    });

    test('returns null when the platform has no source', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'disney_plus',
        preferIos: true,
        region: 'US',
      );
      expect(url, isNull);
    });

    test('rent/buy is still returned when no sub/free source exists', () {
      final url = WatchmodeService.deepLinkFromSources(
        sources,
        platformId: 'apple_tv',
        preferIos: true,
        region: 'US',
      );
      expect(url, 'https://tv.apple.com/title/200');
    });
  });

  group('WatchmodeService.getDeepLink', () {
    test('returns null in test mode (no network / no key)', () async {
      WatchmodeService.setTestMode(true);
      final url = await WatchmodeService.instance.getDeepLink(
        tmdbId: 123,
        isMovie: true,
        platformId: 'netflix',
      );
      expect(url, isNull);
      WatchmodeService.setTestMode(false);
    });
  });
}
