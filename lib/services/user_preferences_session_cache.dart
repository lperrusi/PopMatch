import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'user_preference_analyzer.dart';

/// Shared in-memory cache for expensive `UserPreferenceAnalyzer.analyzePreferences`.
/// This is intentionally cross-provider (MovieProvider + ShowProvider) so tab switching
/// doesn't recompute preferences twice.
class UserPreferencesSessionCache {
  static final UserPreferencesSessionCache _instance =
      UserPreferencesSessionCache._internal();
  factory UserPreferencesSessionCache() => _instance;
  UserPreferencesSessionCache._internal();

  UserPreferences? _cached;
  String? _cachedSig;
  Future<UserPreferences>? _inFlight;
  DateTime? _lastComputedAt;

  int _hashStringList(List<String> values) {
    var h = 0;
    for (final v in values) {
      h = (h * 31) ^ v.hashCode;
    }
    return h;
  }

  String _signature(User user) {
    final likedHash = _hashStringList(user.likedMovies);
    final dislikedHash = _hashStringList(user.dislikedMovies);
    return '${user.id}|$likedHash|$dislikedHash';
  }

  Future<UserPreferences> getOrCompute(
    User user, {
    required bool forceRefresh,
  }) async {
    final sig = _signature(user);
    // If the signature matches, we can always reuse cached preferences.
    // This matters because tab switching can pass `refresh: true` but doesn't
    // necessarily mean liked/disliked sets changed.
    if (_cached != null && _cachedSig == sig) {
      return _cached!;
    }

    // If we're in the middle of a compute (or just computed recently),
    // reuse the cached preferences to avoid blocking “load more” during
    // active swiping.
    if (!forceRefresh && _cached != null) {
      final last = _lastComputedAt;
      const minInterval = Duration(seconds: 15);
      final now = DateTime.now();
      if (last != null && now.difference(last) < minInterval) {
        return _cached!;
      }
      if (_inFlight != null) {
        return _cached!;
      }
    }

    if (_inFlight != null) {
      return _inFlight!;
    }

    _inFlight = () async {
      // Try disk cache before making 60+ TMDB API calls
      if (await _loadFromDisk(sig)) {
        return _cached!;
      }
      final analyzer = UserPreferenceAnalyzer();
      final prefs = await analyzer.analyzePreferences(user);
      _cached = prefs;
      _cachedSig = sig;
      _lastComputedAt = DateTime.now();
      // Persist to disk so next session skips recomputation
      unawaited(_saveToDisk(prefs, sig));
      return prefs;
    }();

    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  static const String _prefsKey = 'user_preferences_cache';

  Future<bool> _loadFromDisk(String sig) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final json = sp.getString(_prefsKey);
      if (json == null) return false;
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['sig'] != sig) return false;
      final p = map['prefs'] as Map<String, dynamic>;
      _cached = UserPreferences(
        topGenres: List<int>.from(p['topGenres'] as List),
        preferredYears: List<int>.from(p['preferredYears'] as List),
        preferredMinRating: (p['preferredMinRating'] as num?)?.toDouble(),
        preferredMaxRating: (p['preferredMaxRating'] as num?)?.toDouble(),
        preferredActors: List<String>.from(p['preferredActors'] as List),
        preferredDirectors: List<String>.from(p['preferredDirectors'] as List),
      );
      _cachedSig = sig;
      _lastComputedAt = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveToDisk(UserPreferences prefs, String sig) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _prefsKey,
        jsonEncode({
          'sig': sig,
          'prefs': {
            'topGenres': prefs.topGenres,
            'preferredYears': prefs.preferredYears,
            'preferredMinRating': prefs.preferredMinRating,
            'preferredMaxRating': prefs.preferredMaxRating,
            'preferredActors': prefs.preferredActors,
            'preferredDirectors': prefs.preferredDirectors,
          },
        }),
      );
    } catch (_) {}
  }
}

