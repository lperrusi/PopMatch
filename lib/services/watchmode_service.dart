import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/streaming_platform.dart';

/// Resolves **direct-to-title** streaming deep links via the Watchmode API.
///
/// TMDB only gives provider IDs (good enough to show "where to watch"), but not
/// per-provider deep links. Watchmode's `/title/{movie|tv}-{tmdbId}/sources/`
/// returns `ios_url` / `android_url` / `web_url` that open the exact title inside
/// the platform app. Looked up **lazily, only when a platform is tapped** — never
/// per swipe-card — so the free tier (~1000 req/mo) is preserved.
///
/// No key / error / unknown platform → returns `null`, and the caller falls back
/// to the existing in-app title search (no regression).
class WatchmodeService {
  static WatchmodeService? _instance;
  static WatchmodeService get instance => _instance ??= WatchmodeService._();
  WatchmodeService._();

  static const String _apiKey =
      String.fromEnvironment('WATCHMODE_API_KEY', defaultValue: '');

  static const String _baseUrl = 'https://api.watchmode.com/v1';

  bool _testMode = false;

  /// Disables network calls in tests (returns null → caller falls back).
  @visibleForTesting
  static void setTestMode(bool value) => instance._testMode = value;

  /// Session cache of raw sources keyed by "{movie|tv}-{tmdbId}-{region}".
  final Map<String, List<dynamic>> _sourcesCache = {};

  bool get hasKey => _apiKey.isNotEmpty;

  /// Returns a deep link that opens [tmdbId] on [platformId] in the platform app
  /// (or its web title page), or `null` if unavailable.
  Future<String?> getDeepLink({
    required int tmdbId,
    required bool isMovie,
    required String platformId,
    String? region,
    bool preferIos = true,
  }) async {
    if (_testMode || _apiKey.isEmpty) return null;
    final reg = (region == null || region.isEmpty) ? 'US' : region;
    try {
      final sources = await _getSources(tmdbId: tmdbId, isMovie: isMovie, region: reg);
      if (sources == null) return null;
      return deepLinkFromSources(
        sources,
        platformId: platformId,
        preferIos: preferIos,
        region: reg,
      );
    } catch (e) {
      debugPrint('Watchmode deep link error for $tmdbId: $e');
      return null;
    }
  }

  Future<List<dynamic>?> _getSources({
    required int tmdbId,
    required bool isMovie,
    required String region,
  }) async {
    final titleId = '${isMovie ? 'movie' : 'tv'}-$tmdbId';
    final cacheKey = '$titleId-$region';
    final cached = _sourcesCache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.parse(
        '$_baseUrl/title/$titleId/sources/?apiKey=$_apiKey&regions=$region');
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final decoded = json.decode(response.body);
    if (decoded is! List) return null;
    _sourcesCache[cacheKey] = decoded;
    return decoded;
  }

  /// Pure: picks the best deep link for [platformId] from Watchmode [sources].
  ///
  /// Prefers subscription/free access over rent/buy, and the native app link
  /// ([preferIos] → `ios_url`, else `android_url`) over the `web_url`.
  static String? deepLinkFromSources(
    List<dynamic> sources, {
    required String platformId,
    required bool preferIos,
    String? region,
  }) {
    const typeRank = {'sub': 0, 'free': 1, 'tve': 2, 'rent': 3, 'buy': 4};

    final matches = <Map<String, dynamic>>[];
    for (final s in sources) {
      if (s is! Map<String, dynamic>) continue;
      if (region != null && s['region'] != null && s['region'] != region) {
        continue;
      }
      final name = s['name'];
      if (name is! String) continue;
      if (_watchmodeNameToPlatformId(name) != platformId) continue;
      matches.add(s);
    }
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final ra = typeRank[a['type']] ?? 9;
      final rb = typeRank[b['type']] ?? 9;
      return ra.compareTo(rb);
    });

    for (final s in matches) {
      final native = preferIos ? s['ios_url'] : s['android_url'];
      final url = (native is String && native.isNotEmpty)
          ? native
          : (s['web_url'] is String && (s['web_url'] as String).isNotEmpty
              ? s['web_url'] as String
              : null);
      if (url != null) return url;
    }
    return null;
  }

  /// Maps a Watchmode source `name` to our [StreamingPlatform] id.
  static String? _watchmodeNameToPlatformId(String name) {
    final direct = StreamingPlatform.idFromNameOrId(name);
    if (direct != null) return direct;
    switch (name.toLowerCase().trim()) {
      case 'max':
      case 'hbo max':
        return 'hbo_max';
      case 'amazon prime video':
      case 'prime video':
      case 'amazon video':
        return 'amazon_prime';
      case 'apple tv+':
      case 'apple tv plus':
      case 'apple tv':
        return 'apple_tv';
      case 'paramount+':
      case 'paramount plus':
      case 'paramount+ with showtime':
        return 'paramount_plus';
      case 'disney+':
        return 'disney_plus';
      case 'pluto tv':
        return 'pluto_tv';
      case 'youtube tv':
        return 'youtube_tv';
      default:
        return null;
    }
  }
}
