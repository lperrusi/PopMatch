import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/user.dart';

/// Service for evaluating recommendation quality using various metrics
class RecommendationMetricsService {
  static final RecommendationMetricsService _instance = RecommendationMetricsService._internal();
  factory RecommendationMetricsService() => _instance;
  RecommendationMetricsService._internal();

  // Store metrics history
  final List<RecommendationMetrics> _metricsHistory = [];
  
  /// Evaluates recommendations using multiple metrics
  Future<RecommendationMetrics> evaluateRecommendations({
    required List<Movie> recommendations,
    required User user,
    required Set<int> shownMovieIds,
    int k = 10,
  }) async {
    final likedMovieIds = user.likedMovies.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final dislikedMovieIds = user.dislikedMovies.map((id) => int.tryParse(id)).whereType<int>().toSet();
    
    // Get top K recommendations
    final topK = recommendations.take(k).toList();
    final topKIds = topK.map((m) => m.id).toSet();
    
    // Calculate metrics
    final precision = _calculatePrecision(topKIds, likedMovieIds, dislikedMovieIds);
    final recall = _calculateRecall(topKIds, likedMovieIds, shownMovieIds);
    final ndcg = _calculateNDCG(topK, likedMovieIds, k);
    final diversity = _calculateDiversity(topK);
    final novelty = _calculateNovelty(topK);
    final coverage = _calculateCoverage(recommendations, shownMovieIds);
    
    final metrics = RecommendationMetrics(
      precision: precision,
      recall: recall,
      ndcg: ndcg,
      diversity: diversity,
      novelty: novelty,
      coverage: coverage,
      timestamp: DateTime.now(),
      k: k,
    );
    
    // Store metrics
    _metricsHistory.add(metrics);
    await _saveMetrics(metrics);
    
    return metrics;
  }
  
  /// Precision@K: Fraction of recommended items that are relevant (liked)
  double _calculatePrecision(Set<int> recommendedIds, Set<int> likedIds, Set<int> dislikedIds) {
    if (recommendedIds.isEmpty) return 0.0;
    
    int relevantCount = 0;
    for (final id in recommendedIds) {
      if (likedIds.contains(id)) {
        relevantCount++;
      }
    }
    
    return relevantCount / recommendedIds.length;
  }
  
  /// Recall@K: Fraction of relevant items that are recommended
  double _calculateRecall(Set<int> recommendedIds, Set<int> likedIds, Set<int> shownIds) {
    if (likedIds.isEmpty) return 0.0;
    
    // Only consider liked movies that were shown (not all possible movies)
    final shownLikedIds = likedIds.intersection(shownIds);
    if (shownLikedIds.isEmpty) return 0.0;
    
    int recommendedRelevantCount = 0;
    for (final id in recommendedIds) {
      if (shownLikedIds.contains(id)) {
        recommendedRelevantCount++;
      }
    }
    
    return recommendedRelevantCount / shownLikedIds.length;
  }
  
  /// Normalized Discounted Cumulative Gain (NDCG@K)
  /// Measures ranking quality - higher positions for relevant items = better score
  double _calculateNDCG(List<Movie> recommendations, Set<int> likedIds, int k) {
    if (recommendations.isEmpty || likedIds.isEmpty) return 0.0;
    
    double dcg = 0.0;
    for (int i = 0; i < recommendations.length && i < k; i++) {
      final movie = recommendations[i];
      if (likedIds.contains(movie.id)) {
        // Relevance = 1 if liked, 0 otherwise
        final relevance = 1.0;
        // Discount: log2(i+2) because position is 0-indexed
        dcg += relevance / (log(i + 2) / log(2));
      }
    }
    
    // Calculate ideal DCG (IDCG) - all relevant items at top
    double idcg = 0.0;
    final relevantCount = min(likedIds.length, k);
    for (int i = 0; i < relevantCount; i++) {
      idcg += 1.0 / (log(i + 2) / log(2));
    }
    
    if (idcg == 0.0) return 0.0;
    return dcg / idcg;
  }
  
  /// Diversity: Measures how different recommended items are from each other
  /// Uses genre diversity as a proxy
  double _calculateDiversity(List<Movie> recommendations) {
    if (recommendations.length < 2) return 0.0;
    
    final allGenres = <int>{};
    for (final movie in recommendations) {
      if (movie.genreIds != null) {
        allGenres.addAll(movie.genreIds!);
      }
    }
    
    // Diversity = unique genres / total possible genres
    // Higher diversity = more variety
    final avgGenresPerMovie = recommendations
        .where((m) => m.genreIds != null && m.genreIds!.isNotEmpty)
        .map((m) => m.genreIds!.length)
        .fold(0, (sum, count) => sum + count) / 
        recommendations.length;
    
    if (avgGenresPerMovie == 0) return 0.0;
    
    // Normalize: unique genres / (avg genres per movie * num movies)
    // Max diversity = 1.0 when all movies have unique genres
    return allGenres.length / (avgGenresPerMovie * recommendations.length);
  }
  
  /// Novelty: Measures how "surprising" or "new" recommendations are
  /// Based on popularity - less popular = more novel
  double _calculateNovelty(List<Movie> recommendations) {
    if (recommendations.isEmpty) return 0.0;
    
    // Calculate average inverse popularity
    // Less popular movies = higher novelty
    double totalInversePopularity = 0.0;
    int count = 0;
    
    for (final movie in recommendations) {
      if (movie.popularity != null && movie.popularity! > 0) {
        // Inverse popularity: 1 / (popularity + 1) to avoid division by zero
        totalInversePopularity += 1.0 / (movie.popularity! + 1);
        count++;
      }
    }
    
    if (count == 0) return 0.0;
    
    final avgInversePopularity = totalInversePopularity / count;
    // Normalize to 0-1 range (assuming max popularity ~100)
    return (avgInversePopularity * 10).clamp(0.0, 1.0);
  }
  
  /// Coverage: Fraction of catalog that can be recommended
  /// Measures how much of the movie space the algorithm can cover
  double _calculateCoverage(List<Movie> recommendations, Set<int> shownMovieIds) {
    if (shownMovieIds.isEmpty) return 0.0;
    
    final recommendedIds = recommendations.map((m) => m.id).toSet();
    final coveredIds = recommendedIds.intersection(shownMovieIds);
    
    return coveredIds.length / shownMovieIds.length;
  }
  
  /// Gets average metrics over time
  RecommendationMetrics getAverageMetrics({int? days}) {
    List<RecommendationMetrics> metricsToAverage = _metricsHistory;
    
    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      metricsToAverage = _metricsHistory
          .where((m) => m.timestamp.isAfter(cutoffDate))
          .toList();
    }
    
    if (metricsToAverage.isEmpty) {
      return RecommendationMetrics(
        precision: 0.0,
        recall: 0.0,
        ndcg: 0.0,
        diversity: 0.0,
        novelty: 0.0,
        coverage: 0.0,
        timestamp: DateTime.now(),
        k: 10,
      );
    }
    
    return RecommendationMetrics(
      precision: metricsToAverage.map((m) => m.precision).reduce((a, b) => a + b) / metricsToAverage.length,
      recall: metricsToAverage.map((m) => m.recall).reduce((a, b) => a + b) / metricsToAverage.length,
      ndcg: metricsToAverage.map((m) => m.ndcg).reduce((a, b) => a + b) / metricsToAverage.length,
      diversity: metricsToAverage.map((m) => m.diversity).reduce((a, b) => a + b) / metricsToAverage.length,
      novelty: metricsToAverage.map((m) => m.novelty).reduce((a, b) => a + b) / metricsToAverage.length,
      coverage: metricsToAverage.map((m) => m.coverage).reduce((a, b) => a + b) / metricsToAverage.length,
      timestamp: DateTime.now(),
      k: metricsToAverage.first.k,
    );
  }
  
  /// Saves metrics to local storage
  Future<void> _saveMetrics(RecommendationMetrics metrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = {
        'precision': metrics.precision,
        'recall': metrics.recall,
        'ndcg': metrics.ndcg,
        'diversity': metrics.diversity,
        'novelty': metrics.novelty,
        'coverage': metrics.coverage,
        'timestamp': metrics.timestamp.toIso8601String(),
        'k': metrics.k,
      };
      
      final existingMetrics = prefs.getStringList('recommendation_metrics') ?? [];
      existingMetrics.add(metricsJson.toString());
      
      // Keep only last 1000 metrics
      if (existingMetrics.length > 1000) {
        existingMetrics.removeRange(0, existingMetrics.length - 1000);
      }
      
      await prefs.setStringList('recommendation_metrics', existingMetrics);
    } catch (e) {
      // Silently fail - metrics are not critical
    }
  }
  
  /// Clears metrics history
  void clearHistory() {
    _metricsHistory.clear();
  }
}

/// Data class for recommendation metrics
class RecommendationMetrics {
  final double precision; // Precision@K
  final double recall; // Recall@K
  final double ndcg; // Normalized Discounted Cumulative Gain@K
  final double diversity; // Diversity score (0-1)
  final double novelty; // Novelty score (0-1)
  final double coverage; // Coverage score (0-1)
  final DateTime timestamp;
  final int k;
  
  RecommendationMetrics({
    required this.precision,
    required this.recall,
    required this.ndcg,
    required this.diversity,
    required this.novelty,
    required this.coverage,
    required this.timestamp,
    required this.k,
  });
  
  /// Overall quality score (weighted combination)
  double get overallScore {
    // Weighted combination of metrics
    return (precision * 0.3) + 
           (recall * 0.25) + 
           (ndcg * 0.25) + 
           (diversity * 0.1) + 
           (novelty * 0.05) + 
           (coverage * 0.05);
  }
  
  @override
  String toString() {
    return 'Metrics(P@$k: ${precision.toStringAsFixed(3)}, '
           'R@$k: ${recall.toStringAsFixed(3)}, '
           'NDCG@$k: ${ndcg.toStringAsFixed(3)}, '
           'Diversity: ${diversity.toStringAsFixed(3)}, '
           'Novelty: ${novelty.toStringAsFixed(3)}, '
           'Coverage: ${coverage.toStringAsFixed(3)})';
  }
}
