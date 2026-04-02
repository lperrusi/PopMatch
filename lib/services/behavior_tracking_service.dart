/// Tracks user behavior patterns for real-time learning
class BehaviorTrackingService {
  static final BehaviorTrackingService _instance =
      BehaviorTrackingService._internal();
  factory BehaviorTrackingService() => _instance;
  BehaviorTrackingService._internal();

  // Track swipe interactions
  final Map<int, List<DateTime>> _movieViewTimes = {};
  final Map<int, double> _swipeSpeeds = {}; // milliseconds between views
  final Map<int, int> _movieRevisits =
      {}; // How many times user went back to a movie
  final Map<int, int> _detailViewCounts =
      {}; // How many times user viewed details
  final Map<String, List<int>> _swipeSequences =
      {}; // Track sequences of likes/dislikes

  // Track time spent on movie details
  final Map<int, List<Duration>> _detailViewDurations = {};

  // Track patterns
  final Map<int, double> _movieInterestScores =
      {}; // Calculated interest score per movie

  // Track skipped movies per user (to filter from recommendations)
  final Map<String, Set<int>> _skippedMovies = {}; // userId -> Set of movie IDs

  /// Records a movie view (when movie appears in swipe stack)
  void recordMovieView(int movieId) {
    final now = DateTime.now();
    _movieViewTimes.putIfAbsent(movieId, () => []).add(now);

    // Calculate swipe speed (time between views)
    final views = _movieViewTimes[movieId]!;
    if (views.length > 1) {
      final timeDiff =
          views[views.length - 1].difference(views[views.length - 2]);
      _swipeSpeeds[movieId] = timeDiff.inMilliseconds.toDouble();
    }
  }

  /// Records when user views movie details
  void recordDetailView(int movieId, {DateTime? startTime}) {
    _detailViewCounts[movieId] = (_detailViewCounts[movieId] ?? 0) + 1;

    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _detailViewDurations.putIfAbsent(movieId, () => []).add(duration);
    }
  }

  /// Records when user revisits a movie (swipes back)
  void recordMovieRevisit(int movieId) {
    _movieRevisits[movieId] = (_movieRevisits[movieId] ?? 0) + 1;
  }

  /// Records a swipe action (like/dislike/skip)
  void recordSwipe(String userId, int movieId, String action) {
    _swipeSequences.putIfAbsent(userId, () => []).add(movieId);

    // Track skipped movies separately for filtering
    if (action == 'skip') {
      _skippedMovies.putIfAbsent(userId, () => <int>{}).add(movieId);
    }

    // Update interest score based on action
    if (action == 'like' || action == 'match') {
      _movieInterestScores[movieId] =
          (_movieInterestScores[movieId] ?? 0.0) + 1.0;
    } else if (action == 'dislike') {
      _movieInterestScores[movieId] =
          (_movieInterestScores[movieId] ?? 0.0) - 0.5;
    }
    // Skip action is neutral - doesn't affect interest score
  }

  /// Gets all skipped movies for a user
  Set<int> getSkippedMovies(String userId) {
    return _skippedMovies[userId] ?? <int>{};
  }

  /// Checks if a movie has been skipped by a user
  bool isSkipped(String userId, int movieId) {
    return _skippedMovies[userId]?.contains(movieId) ?? false;
  }

  /// Calculates interest score for a movie based on behavior
  double getInterestScore(int movieId) {
    double score = 0.0;

    // Detail views indicate interest
    final detailViews = _detailViewCounts[movieId] ?? 0;
    score += detailViews * 0.3;

    // Time spent on details indicates strong interest
    final durations = _detailViewDurations[movieId] ?? [];
    if (durations.isNotEmpty) {
      final avgDuration =
          durations.map((d) => d.inSeconds).reduce((a, b) => a + b) /
              durations.length;
      score +=
          (avgDuration / 10.0).clamp(0.0, 2.0); // Max 2 points for time spent
    }

    // Revisits indicate strong interest
    final revisits = _movieRevisits[movieId] ?? 0;
    score += revisits * 0.5;

    // Slow swipe speed indicates consideration (interest)
    final swipeSpeed = _swipeSpeeds[movieId];
    if (swipeSpeed != null && swipeSpeed > 2000) {
      // More than 2 seconds = considering it
      score += 0.2;
    }

    // Add explicit interest score from likes/dislikes
    score += _movieInterestScores[movieId] ?? 0.0;

    return score;
  }

  /// Gets behavior-based weight multiplier for a movie
  /// IMPROVED: Better normalization for additive scoring
  double getBehaviorWeight(int movieId) {
    final interestScore = getInterestScore(movieId);

    // Convert interest score to weight (0-1 range for additive scoring)
    // Interest scores typically range from -2 to +5
    // Normalize to 0-1 range
    if (interestScore > 0) {
      // Positive interest: normalize to 0.5-1.0 range
      final normalized = (interestScore / 5.0).clamp(0.0, 1.0);
      return 0.5 + (normalized * 0.5);
    } else if (interestScore < 0) {
      // Negative interest: normalize to 0.0-0.5 range
      final normalized = (interestScore.abs() / 2.0).clamp(0.0, 1.0);
      return 0.5 - (normalized * 0.5);
    }

    return 0.5; // Neutral weight (0.5) if no behavior data
  }

  /// Gets similar movies based on user's swipe patterns
  List<int> getSimilarMoviesFromBehavior(String userId, int movieId) {
    final userSequence = _swipeSequences[userId] ?? [];
    final movieIndex = userSequence.indexOf(movieId);

    if (movieIndex == -1 || movieIndex == 0) return [];

    // Find movies that appeared near this one in the sequence
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

  /// Clears behavior data for a user (privacy)
  void clearUserData(String userId) {
    _swipeSequences.remove(userId);
    _skippedMovies.remove(userId);
  }

  /// Gets behavior insights for recommendations
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
}
