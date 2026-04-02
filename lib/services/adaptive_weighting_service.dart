import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'recommendation_metrics_service.dart';

/// Service for adaptive hybrid weighting that learns optimal algorithm weights
/// from user feedback and recommendation performance
class AdaptiveWeightingService {
  static final AdaptiveWeightingService _instance =
      AdaptiveWeightingService._internal();
  factory AdaptiveWeightingService() => _instance;
  AdaptiveWeightingService._internal();

  // Current weights for different recommendation strategies
  Map<String, double> _currentWeights = {
    'contentBased': 0.40, // Genre, actor, director matching
    'contextual': 0.20, // Time, mood-based
    'behavior': 0.15, // Real-time learning
    'embedding': 0.20, // Embedding similarity
    'collaborative': 0.05, // Collaborative filtering
  };

  // Track user feedback per strategy
  final Map<String, List<bool>> _strategyFeedback =
      {}; // true = liked, false = disliked

  /// Gets current adaptive weights
  Map<String, double> getWeights() {
    return Map.from(_currentWeights);
  }

  /// Records user feedback for a recommendation
  /// This helps learn which strategies work best for each user
  Future<void> recordFeedback({
    required String strategy,
    required bool liked, // true if user liked, false if disliked
    required User user,
  }) async {
    _strategyFeedback.putIfAbsent(strategy, () => []).add(liked);

    // Keep only last 100 feedbacks per strategy
    final feedbacks = _strategyFeedback[strategy]!;
    if (feedbacks.length > 100) {
      feedbacks.removeRange(0, feedbacks.length - 100);
    }

    // Update weights periodically based on feedback
    await _updateWeightsFromFeedback(user);
  }

  /// Updates weights based on user feedback
  Future<void> _updateWeightsFromFeedback(User user) async {
    // Only update if we have enough feedback (at least 10 per strategy)
    const minFeedbacks = 10;
    bool hasEnoughData = true;

    for (final strategy in _currentWeights.keys) {
      final feedbacks = _strategyFeedback[strategy] ?? [];
      if (feedbacks.length < minFeedbacks) {
        hasEnoughData = false;
        break;
      }
    }

    if (!hasEnoughData) return;

    // Calculate success rate for each strategy
    final successRates = <String, double>{};
    for (final strategy in _currentWeights.keys) {
      final feedbacks = _strategyFeedback[strategy] ?? [];
      if (feedbacks.isNotEmpty) {
        final successCount = feedbacks.where((f) => f).length;
        successRates[strategy] = successCount / feedbacks.length;
      } else {
        successRates[strategy] = 0.5; // Neutral if no data
      }
    }

    // Normalize success rates to create new weights
    final totalSuccess = successRates.values.reduce((a, b) => a + b);
    if (totalSuccess > 0) {
      final newWeights = <String, double>{};
      for (final strategy in _currentWeights.keys) {
        // Use exponential smoothing: 70% old weight, 30% new weight
        // This prevents sudden changes and maintains stability
        final targetWeight = successRates[strategy]! / totalSuccess;
        final currentWeight = _currentWeights[strategy]!;
        final smoothedWeight = (currentWeight * 0.7) + (targetWeight * 0.3);
        newWeights[strategy] = smoothedWeight;
      }

      // Normalize to ensure weights sum to 1.0
      final weightSum = newWeights.values.reduce((a, b) => a + b);
      if (weightSum > 0) {
        for (final strategy in newWeights.keys) {
          newWeights[strategy] = newWeights[strategy]! / weightSum;
        }
        _currentWeights = newWeights;
        await _saveWeights(user.id);
      }
    }
  }

  /// Updates weights based on recommendation metrics
  Future<void> updateWeightsFromMetrics({
    required Map<String, RecommendationMetrics> strategyMetrics,
    required User user,
  }) async {
    // Calculate overall score for each strategy
    final strategyScores = <String, double>{};
    for (final entry in strategyMetrics.entries) {
      strategyScores[entry.key] = entry.value.overallScore;
    }

    // Normalize scores
    final totalScore = strategyScores.values.reduce((a, b) => a + b);
    if (totalScore > 0) {
      final newWeights = <String, double>{};
      for (final strategy in _currentWeights.keys) {
        final score = strategyScores[strategy] ?? 0.5;
        // Exponential smoothing: 80% old, 20% new (more conservative for metrics)
        final targetWeight = score / totalScore;
        final currentWeight = _currentWeights[strategy]!;
        final smoothedWeight = (currentWeight * 0.8) + (targetWeight * 0.2);
        newWeights[strategy] = smoothedWeight;
      }

      // Normalize
      final weightSum = newWeights.values.reduce((a, b) => a + b);
      if (weightSum > 0) {
        for (final strategy in newWeights.keys) {
          newWeights[strategy] = newWeights[strategy]! / weightSum;
        }
        _currentWeights = newWeights;
        await _saveWeights(user.id);
      }
    }
  }

  /// Gets adaptive weight for a specific strategy
  double getWeight(String strategy) {
    return _currentWeights[strategy] ?? 0.0;
  }

  /// Resets weights to defaults
  Future<void> resetWeights(String userId) async {
    _currentWeights = {
      'contentBased': 0.40,
      'contextual': 0.20,
      'behavior': 0.15,
      'embedding': 0.20,
      'collaborative': 0.05,
    };
    await _saveWeights(userId);
  }

  /// Saves weights to local storage
  Future<void> _saveWeights(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightsJson = <String, String>{};
      for (final entry in _currentWeights.entries) {
        weightsJson[entry.key] = entry.value.toString();
      }

      // Save per-user weights
      await prefs.setString('adaptive_weights_$userId', weightsJson.toString());
    } catch (e) {
      // Silently fail
    }
  }

  /// Loads weights from local storage
  Future<void> loadWeights(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightsStr = prefs.getString('adaptive_weights_$userId');
      if (weightsStr != null) {
        // Parse weights (simplified - in production use proper JSON)
        // For now, keep defaults if parsing fails
      }
    } catch (e) {
      // Keep defaults if loading fails
    }
  }

  /// Gets context-aware weights based on user state
  Map<String, double> getContextualWeights({
    required User user,
    required int likedMoviesCount,
    required bool hasRecentActivity,
  }) {
    final baseWeights = Map<String, double>.from(_currentWeights);

    // Adjust weights based on user state
    if (likedMoviesCount < 5) {
      // New users: favor content-based and contextual
      baseWeights['contentBased'] = (baseWeights['contentBased'] ?? 0.4) * 1.2;
      baseWeights['contextual'] = (baseWeights['contextual'] ?? 0.2) * 1.2;
      baseWeights['embedding'] = (baseWeights['embedding'] ?? 0.2) * 0.8;
      baseWeights['collaborative'] =
          (baseWeights['collaborative'] ?? 0.05) * 0.5;
    } else if (likedMoviesCount > 20) {
      // Experienced users: favor embedding and collaborative
      baseWeights['embedding'] = (baseWeights['embedding'] ?? 0.2) * 1.3;
      baseWeights['collaborative'] =
          (baseWeights['collaborative'] ?? 0.05) * 1.5;
      baseWeights['contentBased'] = (baseWeights['contentBased'] ?? 0.4) * 0.9;
    }

    if (hasRecentActivity) {
      // Active users: increase behavior weight
      baseWeights['behavior'] = (baseWeights['behavior'] ?? 0.15) * 1.2;
    }

    // Normalize
    final sum = baseWeights.values.reduce((a, b) => a + b);
    if (sum > 0) {
      for (final key in baseWeights.keys) {
        baseWeights[key] = baseWeights[key]! / sum;
      }
    }

    return baseWeights;
  }
}
