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
      final analyzer = UserPreferenceAnalyzer();
      final prefs = await analyzer.analyzePreferences(user);
      _cached = prefs;
      _cachedSig = sig;
      _lastComputedAt = DateTime.now();
      return prefs;
    }();

    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }
}

