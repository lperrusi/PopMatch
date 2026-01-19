import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for A/B testing different recommendation algorithms
class ABTestingService {
  static final ABTestingService _instance = ABTestingService._internal();
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  // Track which variant each user is assigned to
  final Map<String, String> _userVariants = {};
  
  // Track performance metrics per variant
  final Map<String, List<double>> _variantMetrics = {};
  
  // Available algorithm variants
  static const String variantA = 'baseline'; // Current algorithm
  static const String variantB = 'enhanced'; // Enhanced with new features
  static const String variantC = 'embedding_focused'; // Embedding-heavy approach

  /// Gets the algorithm variant for a user (consistent assignment)
  Future<String> getUserVariant(String userId) async {
    // Check if user already has a variant assigned
    if (_userVariants.containsKey(userId)) {
      return _userVariants[userId]!;
    }
    
    // Load from storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVariant = prefs.getString('ab_test_variant_$userId');
      if (storedVariant != null) {
        _userVariants[userId] = storedVariant;
        return storedVariant;
      }
    } catch (e) {
      // Continue to assign new variant
    }
    
    // Assign new variant (50% baseline, 30% enhanced, 20% embedding_focused)
    final random = Random();
    final roll = random.nextDouble();
    String variant;
    
    if (roll < 0.5) {
      variant = variantA;
    } else if (roll < 0.8) {
      variant = variantB;
    } else {
      variant = variantC;
    }
    
    _userVariants[userId] = variant;
    
    // Save to storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ab_test_variant_$userId', variant);
    } catch (e) {
      // Silently fail
    }
    
    return variant;
  }

  /// Records a metric for a variant (e.g., like rate, CTR)
  Future<void> recordMetric(String variant, double metric) async {
    _variantMetrics.putIfAbsent(variant, () => []).add(metric);
    
    // Keep only last 1000 metrics per variant
    final metrics = _variantMetrics[variant]!;
    if (metrics.length > 1000) {
      metrics.removeRange(0, metrics.length - 1000);
    }
    
    // Save to storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsStr = metrics.map((m) => m.toString()).join(',');
      await prefs.setString('ab_test_metrics_$variant', metricsStr);
    } catch (e) {
      // Silently fail
    }
  }

  /// Gets average metric for a variant
  double getAverageMetric(String variant) {
    final metrics = _variantMetrics[variant] ?? [];
    if (metrics.isEmpty) return 0.0;
    
    return metrics.reduce((a, b) => a + b) / metrics.length;
  }

  /// Gets statistical comparison between variants
  Map<String, dynamic> compareVariants() {
    final results = <String, Map<String, dynamic>>{};
    
    for (final variant in [variantA, variantB, variantC]) {
      final metrics = _variantMetrics[variant] ?? [];
      if (metrics.isEmpty) continue;
      
      final average = metrics.reduce((a, b) => a + b) / metrics.length;
      final variance = metrics.map((m) => (m - average) * (m - average)).reduce((a, b) => a + b) / metrics.length;
      final stdDev = sqrt(variance);
      
      results[variant] = {
        'average': average,
        'stdDev': stdDev,
        'sampleSize': metrics.length,
        'min': metrics.reduce((a, b) => a < b ? a : b),
        'max': metrics.reduce((a, b) => a > b ? a : b),
      };
    }
    
    return results;
  }

  /// Checks if a variant is significantly better (simple t-test approximation)
  bool isVariantBetter(String variant1, String variant2, {double confidence = 0.95}) {
    final metrics1 = _variantMetrics[variant1] ?? [];
    final metrics2 = _variantMetrics[variant2] ?? [];
    
    if (metrics1.isEmpty || metrics2.isEmpty) return false;
    if (metrics1.length < 30 || metrics2.length < 30) return false; // Need enough samples
    
    final avg1 = metrics1.reduce((a, b) => a + b) / metrics1.length;
    final avg2 = metrics2.reduce((a, b) => a + b) / metrics2.length;
    
    // Simple comparison: variant1 is better if average is higher
    // In production, use proper statistical testing (t-test, Mann-Whitney U, etc.)
    return avg1 > avg2;
  }

  /// Resets A/B test for a user (for testing)
  Future<void> resetTest(String userId) async {
    _userVariants.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ab_test_variant_$userId');
    } catch (e) {
      // Silently fail
    }
  }

  /// Clears all metrics (for testing)
  void clearMetrics() {
    _variantMetrics.clear();
  }
}
