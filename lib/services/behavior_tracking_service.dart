import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks user behavior patterns for real-time learning.
///
/// The learning signals (swipe sequences, interest scores, revisits, detail-view
/// counts) and a skip "resurface" counter are persisted to SharedPreferences so
/// the 10% behavior weight survives app restarts. Transient timing data
/// (view timestamps, swipe speeds, view durations) stays in-memory only.
class BehaviorTrackingService {
  static final BehaviorTrackingService _instance =
      BehaviorTrackingService._internal();
  factory BehaviorTrackingService() => _instance;
  BehaviorTrackingService._internal();

  /// A skipped movie stays hidden for this many app launches, then resurfaces.
  static const int kSkipResurfaceLaunches = 3;

  /// Upper bound on persisted per-map entries to keep storage bounded.
  static const int _maxEntries = 500;

  // Persisted SharedPreferences keys.
  static const _kSkipsKey = 'behavior_skips'; // userId -> {movieId: counter}
  static const _kSequencesKey = 'behavior_sequences'; // userId -> [movieId]
  static const _kInterestKey = 'behavior_interest'; // movieId -> score
  static const _kRevisitsKey = 'behavior_revisits'; // movieId -> count
  static const _kDetailCountsKey = 'behavior_detail_counts'; // movieId -> count

  // ── Transient (in-memory only) ──────────────────────────────────────────────
  final Map<int, List<DateTime>> _movieViewTimes = {};
  final Map<int, double> _swipeSpeeds = {}; // milliseconds between views
  final Map<int, List<Duration>> _detailViewDurations = {};

  // ── Persisted learning signals ──────────────────────────────────────────────
  final Map<int, int> _movieRevisits = {};
  final Map<int, int> _detailViewCounts = {};
  final Map<String, List<int>> _swipeSequences = {};
  final Map<int, double> _movieInterestScores = {};

  // Skipped movies per user with a resurface counter: userId -> {movieId: count}.
  final Map<String, Map<int, int>> _skippedMovies = {};

  bool _initialized = false;

  /// Loads persisted behavior data and ages the skip counters by one launch
  /// (entries reaching zero are dropped so those movies resurface). Call once at
  /// app startup. Safe to call repeatedly (no-op after the first call per run).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      final seq = _decodeMap(prefs.getString(_kSequencesKey));
      seq?.forEach((userId, ids) {
        if (ids is List) {
          _swipeSequences[userId] =
              ids.map((e) => _asInt(e)).whereType<int>().toList();
        }
      });

      _decodeMap(prefs.getString(_kInterestKey))?.forEach((k, v) {
        final id = int.tryParse(k);
        final score = (v is num) ? v.toDouble() : null;
        if (id != null && score != null) _movieInterestScores[id] = score;
      });

      _decodeMap(prefs.getString(_kRevisitsKey))?.forEach((k, v) {
        final id = int.tryParse(k);
        final c = _asInt(v);
        if (id != null && c != null) _movieRevisits[id] = c;
      });

      _decodeMap(prefs.getString(_kDetailCountsKey))?.forEach((k, v) {
        final id = int.tryParse(k);
        final c = _asInt(v);
        if (id != null && c != null) _detailViewCounts[id] = c;
      });

      // Skips: decrement each counter by one launch; drop when it hits zero.
      _decodeMap(prefs.getString(_kSkipsKey))?.forEach((userId, byMovie) {
        if (byMovie is! Map) return;
        final aged = <int, int>{};
        byMovie.forEach((k, v) {
          final id = int.tryParse(k.toString());
          final counter = _asInt(v);
          if (id == null || counter == null) return;
          final next = counter - 1;
          if (next > 0) aged[id] = next; // else resurfaces
        });
        if (aged.isNotEmpty) _skippedMovies[userId] = aged;
      });

      await _save();
    } catch (_) {
      // Start fresh if persisted data is malformed.
    }
  }

  /// Records a movie view (when movie appears in swipe stack).
  void recordMovieView(int movieId) {
    final now = DateTime.now();
    _movieViewTimes.putIfAbsent(movieId, () => []).add(now);

    final views = _movieViewTimes[movieId]!;
    if (views.length > 1) {
      final timeDiff =
          views[views.length - 1].difference(views[views.length - 2]);
      _swipeSpeeds[movieId] = timeDiff.inMilliseconds.toDouble();
    }
  }

  /// Records when user views movie details.
  void recordDetailView(int movieId, {DateTime? startTime}) {
    _detailViewCounts[movieId] = (_detailViewCounts[movieId] ?? 0) + 1;

    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _detailViewDurations.putIfAbsent(movieId, () => []).add(duration);
    }
    unawaited(_save());
  }

  /// Records when user revisits a movie (swipes back).
  void recordMovieRevisit(int movieId) {
    _movieRevisits[movieId] = (_movieRevisits[movieId] ?? 0) + 1;
    unawaited(_save());
  }

  /// Records a swipe action (like/dislike/skip).
  void recordSwipe(String userId, int movieId, String action) {
    _swipeSequences.putIfAbsent(userId, () => []).add(movieId);

    // Track skipped movies with a resurface counter for filtering.
    if (action == 'skip') {
      _skippedMovies.putIfAbsent(userId, () => <int, int>{})[movieId] =
          kSkipResurfaceLaunches;
    }

    // Update interest score based on action.
    if (action == 'like' || action == 'match') {
      _movieInterestScores[movieId] =
          (_movieInterestScores[movieId] ?? 0.0) + 1.0;
    } else if (action == 'dislike') {
      _movieInterestScores[movieId] =
          (_movieInterestScores[movieId] ?? 0.0) - 0.5;
    }
    // Skip action is neutral - doesn't affect interest score.
    unawaited(_save());
  }

  /// Gets all currently-active skipped movies for a user (counter > 0).
  Set<int> getSkippedMovies(String userId) {
    final byMovie = _skippedMovies[userId];
    if (byMovie == null) return <int>{};
    return byMovie.entries.where((e) => e.value > 0).map((e) => e.key).toSet();
  }

  /// Checks if a movie is currently skip-filtered for a user.
  bool isSkipped(String userId, int movieId) {
    return (_skippedMovies[userId]?[movieId] ?? 0) > 0;
  }

  /// Calculates interest score for a movie based on behavior.
  double getInterestScore(int movieId) {
    double score = 0.0;

    final detailViews = _detailViewCounts[movieId] ?? 0;
    score += detailViews * 0.3;

    final durations = _detailViewDurations[movieId] ?? [];
    if (durations.isNotEmpty) {
      final avgDuration =
          durations.map((d) => d.inSeconds).reduce((a, b) => a + b) /
              durations.length;
      score += (avgDuration / 10.0).clamp(0.0, 2.0);
    }

    final revisits = _movieRevisits[movieId] ?? 0;
    score += revisits * 0.5;

    final swipeSpeed = _swipeSpeeds[movieId];
    if (swipeSpeed != null && swipeSpeed > 2000) {
      score += 0.2;
    }

    score += _movieInterestScores[movieId] ?? 0.0;

    return score;
  }

  /// Gets behavior-based weight multiplier for a movie (0-1 range).
  double getBehaviorWeight(int movieId) {
    final interestScore = getInterestScore(movieId);

    if (interestScore > 0) {
      final normalized = (interestScore / 5.0).clamp(0.0, 1.0);
      return 0.5 + (normalized * 0.5);
    } else if (interestScore < 0) {
      final normalized = (interestScore.abs() / 2.0).clamp(0.0, 1.0);
      return 0.5 - (normalized * 0.5);
    }

    return 0.5;
  }

  /// Gets similar movies based on user's swipe patterns.
  List<int> getSimilarMoviesFromBehavior(String userId, int movieId) {
    final userSequence = _swipeSequences[userId] ?? [];
    final movieIndex = userSequence.indexOf(movieId);

    if (movieIndex == -1 || movieIndex == 0) return [];

    final similarMovies = <int>[];
    final startIndex = (movieIndex - 3).clamp(0, userSequence.length);
    final endIndex = (movieIndex + 3).clamp(0, userSequence.length);

    for (int i = startIndex; i < endIndex; i++) {
      if (i != movieIndex && userSequence[i] != movieId) {
        similarMovies.add(userSequence[i]);
      }
    }

    return similarMovies;
  }

  /// Clears persisted + in-memory behavior data for a user (privacy).
  void clearUserData(String userId) {
    _swipeSequences.remove(userId);
    _skippedMovies.remove(userId);
    unawaited(_save());
  }

  /// Gets behavior insights for recommendations.
  Map<String, dynamic> getBehaviorInsights(String userId) {
    final userSequence = _swipeSequences[userId] ?? [];

    return {
      'totalInteractions': userSequence.length,
      'avgSwipeSpeed': _swipeSpeeds.values.isEmpty
          ? 0.0
          : _swipeSpeeds.values.reduce((a, b) => a + b) / _swipeSpeeds.length,
      'mostViewedMovies': _detailViewCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).map((e) => e.key).toList(),
      'highInterestMovies': _movieInterestScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).map((e) => e.key).toList(),
    };
  }

  // ── Persistence helpers ─────────────────────────────────────────────────────

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final skips = <String, Map<String, int>>{};
      _skippedMovies.forEach((userId, byMovie) {
        skips[userId] = {
          for (final e in byMovie.entries) e.key.toString(): e.value,
        };
      });

      final sequences = <String, List<int>>{};
      _swipeSequences.forEach((userId, ids) {
        sequences[userId] =
            ids.length > _maxEntries ? ids.sublist(ids.length - _maxEntries) : ids;
      });

      await prefs.setString(_kSkipsKey, jsonEncode(skips));
      await prefs.setString(_kSequencesKey, jsonEncode(sequences));
      await prefs.setString(
          _kInterestKey, jsonEncode(_capIntKeyed(_movieInterestScores)));
      await prefs.setString(
          _kRevisitsKey, jsonEncode(_capIntKeyed(_movieRevisits)));
      await prefs.setString(
          _kDetailCountsKey, jsonEncode(_capIntKeyed(_detailViewCounts)));
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Stringifies int keys and trims to the most-recent [_maxEntries] entries.
  Map<String, T> _capIntKeyed<T>(Map<int, T> source) {
    final entries = source.entries.toList();
    final kept = entries.length > _maxEntries
        ? entries.sublist(entries.length - _maxEntries)
        : entries;
    return {for (final e in kept) e.key.toString(): e.value};
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  int? _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()));

  /// Clears all in-memory state and the initialized guard (tests only).
  @visibleForTesting
  void resetForTest() {
    _movieViewTimes.clear();
    _swipeSpeeds.clear();
    _detailViewDurations.clear();
    _movieRevisits.clear();
    _detailViewCounts.clear();
    _swipeSequences.clear();
    _movieInterestScores.clear();
    _skippedMovies.clear();
    _initialized = false;
  }

  /// Flushes current state to storage deterministically (tests only).
  @visibleForTesting
  Future<void> saveForTest() => _save();
}
