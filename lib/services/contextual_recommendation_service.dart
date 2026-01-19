import '../models/movie.dart';
import '../models/mood.dart';

/// Service for contextual recommendations based on time, mood, and other context factors
class ContextualRecommendationService {
  static final ContextualRecommendationService _instance = ContextualRecommendationService._internal();
  factory ContextualRecommendationService() => _instance;
  ContextualRecommendationService._internal();

  /// Gets contextual weight multiplier for a movie based on current context
  /// IMPROVED: Returns 0-1 range for additive scoring instead of multiplier
  double getContextualWeight(Movie movie, {
    List<Mood>? currentMoods,
    DateTime? currentTime,
  }) {
    double weight = 0.5; // Start at neutral (0.5)
    
    // Time-based context (adds/subtracts from base)
    if (currentTime != null) {
      final timeWeight = _getTimeBasedWeight(movie, currentTime);
      // Convert multiplier (0.8-1.2) to additive (0.3-0.7)
      weight = 0.5 + ((timeWeight - 1.0) * 0.5);
    }
    
    // Mood-based context (adds to weight)
    if (currentMoods != null && currentMoods.isNotEmpty) {
      final moodWeight = _getMoodBasedWeight(movie, currentMoods);
      // Convert multiplier (1.0-1.5) to additive boost
      final moodBoost = (moodWeight - 1.0) * 0.3;
      weight = (weight + moodBoost).clamp(0.0, 1.0);
    }
    
    return weight.clamp(0.0, 1.0);
  }

  /// Calculates time-based weight (morning vs evening preferences)
  double _getTimeBasedWeight(Movie movie, DateTime time) {
    final hour = time.hour;
    final isWeekend = time.weekday >= 6;
    
    // Morning (6-12): Prefer lighter content, comedies, animations
    if (hour >= 6 && hour < 12) {
      if (movie.genreIds != null) {
        if (movie.genreIds!.contains(35)) return 1.2; // Comedy
        if (movie.genreIds!.contains(16)) return 1.15; // Animation
        if (movie.genreIds!.contains(27)) return 0.8; // Horror (less preferred)
        if (movie.genreIds!.contains(80)) return 0.85; // Crime (less preferred)
      }
    }
    
    // Afternoon (12-17): Balanced preferences
    if (hour >= 12 && hour < 17) {
      return 1.0; // Neutral
    }
    
    // Evening (17-22): Prefer action, drama, thrillers
    if (hour >= 17 && hour < 22) {
      if (movie.genreIds != null) {
        if (movie.genreIds!.contains(28)) return 1.15; // Action
        if (movie.genreIds!.contains(18)) return 1.1; // Drama
        if (movie.genreIds!.contains(53)) return 1.1; // Thriller
      }
    }
    
    // Night (22-6): Prefer darker content, horror, thrillers
    if (hour >= 22 || hour < 6) {
      if (movie.genreIds != null) {
        if (movie.genreIds!.contains(27)) return 1.2; // Horror
        if (movie.genreIds!.contains(53)) return 1.15; // Thriller
        if (movie.genreIds!.contains(16)) return 0.85; // Animation (less preferred)
      }
    }
    
    // Weekend: Prefer longer movies, blockbusters
    if (isWeekend) {
      if (movie.runtime != null && movie.runtime! > 120) {
        return 1.1; // Longer movies on weekends
      }
      // Boost popular/blockbuster movies on weekends
      if (movie.voteCount != null && movie.voteCount! > 1000) {
        return 1.05;
      }
    }
    
    // Weekday: Prefer shorter movies
    if (!isWeekend) {
      if (movie.runtime != null && movie.runtime! < 100) {
        return 1.05; // Shorter movies on weekdays
      }
    }
    
    return 1.0;
  }

  /// Calculates mood-based weight
  double _getMoodBasedWeight(Movie movie, List<Mood> moods) {
    double maxWeight = 1.0;
    
    for (final mood in moods) {
      final moodWeight = _getSingleMoodWeight(movie, mood);
      maxWeight = maxWeight > moodWeight ? maxWeight : moodWeight;
    }
    
    return maxWeight;
  }

  /// Gets weight for a single mood
  double _getSingleMoodWeight(Movie movie, Mood mood) {
    if (movie.genreIds == null) return 1.0;
    
    // Check if movie matches mood's preferred genres
    final matchingGenres = movie.genreIds!
        .where((genreId) => mood.preferredGenres.contains(genreId))
        .length;
    
    if (matchingGenres > 0) {
      // More matching genres = higher weight
      return 1.0 + (matchingGenres * 0.15);
    }
    
    return 1.0;
  }

  /// Gets recommended genres for current context
  List<int> getRecommendedGenresForContext({
    DateTime? currentTime,
    List<Mood>? currentMoods,
  }) {
    final recommendedGenres = <int>{};
    
    if (currentTime != null) {
      final hour = currentTime.hour;
      
      if (hour >= 6 && hour < 12) {
        // Morning: Comedy, Animation, Family
        recommendedGenres.addAll([35, 16, 10751]);
      } else if (hour >= 17 && hour < 22) {
        // Evening: Action, Drama, Thriller
        recommendedGenres.addAll([28, 18, 53]);
      } else if (hour >= 22 || hour < 6) {
        // Night: Horror, Thriller, Crime
        recommendedGenres.addAll([27, 53, 80]);
      }
    }
    
    if (currentMoods != null) {
      for (final mood in currentMoods) {
        recommendedGenres.addAll(mood.preferredGenres);
      }
    }
    
    return recommendedGenres.toList();
  }
}

