import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/user.dart';

/// Service for deep learning-based recommendations
/// This sets up the infrastructure for TensorFlow Lite models
/// Note: Full implementation requires trained models (server-side training needed)
class DeepLearningService {
  static final DeepLearningService _instance = DeepLearningService._internal();
  factory DeepLearningService() => _instance;
  DeepLearningService._internal();

  final bool _isModelLoaded = false;
  String? _modelPath;

  /// Initializes the deep learning service
  /// In production, this would load a TensorFlow Lite model
  Future<void> initialize() async {
    // Placeholder: TensorFlow Lite model loading not implemented
    // Example:
    // try {
    //   _modelPath = await _loadModelFromAssets('recommendation_model.tflite');
    //   _isModelLoaded = true;
    // } catch (e) {
    //   debugPrint('Error loading deep learning model: $e');
    // }

    debugPrint(
        'Deep Learning Service initialized (model loading not yet implemented)');
  }

  /// Prepares feature vector for model input
  /// This converts user and movie data into a format the model expects
  List<double> prepareFeatureVector(User user, Movie movie) {
    final features = <double>[];

    // User features
    features.add(user.likedMovies.length.toDouble());
    features.add(user.dislikedMovies.length.toDouble());

    // Movie features
    features.add(movie.voteAverage ?? 0.0);
    features.add((movie.popularity ?? 0.0) / 100.0); // Normalize
    features.add((movie.voteCount ?? 0) / 1000.0); // Normalize

    // Genre features (one-hot encoding for top genres)
    final topGenres = [28, 18, 35, 27, 878, 10749, 53, 16, 80, 14];
    for (final genreId in topGenres) {
      features.add(movie.genreIds?.contains(genreId) == true ? 1.0 : 0.0);
    }

    // Year feature (normalized)
    if (movie.year != null) {
      final year = int.tryParse(movie.year!);
      if (year != null) {
        features.add((year - 1900) / 130.0);
      } else {
        features.add(0.5);
      }
    } else {
      features.add(0.5);
    }

    // Runtime feature (normalized)
    if (movie.runtime != null) {
      features.add(movie.runtime! / 200.0);
    } else {
      features.add(0.5);
    }

    return features;
  }

  /// Gets deep learning prediction score for a movie
  /// In production, this would run inference on the TensorFlow Lite model
  Future<double> getPredictionScore(User user, Movie movie) async {
    if (!_isModelLoaded) {
      // Fallback to rule-based scoring if model not loaded
      return _getFallbackScore(user, movie);
    }

    // Placeholder: TensorFlow Lite inference not implemented
    // Example:
    // final features = prepareFeatureVector(user, movie);
    // final interpreter = await tflite.Interpreter.fromAsset(_modelPath!);
    // final input = [features];
    // final output = List.filled(1, 0.0).reshape([1, 1]);
    // interpreter.run(input, output);
    // return output[0][0];

    return _getFallbackScore(user, movie);
  }

  /// Fallback scoring when model is not available.
  /// Uses online ratings (TMDB, IMDb, Rotten Tomatoes), user likes/dislikes, and popularity.
  double _getFallbackScore(User user, Movie movie) {
    double score = 0.5; // Base score

    // Penalize if user already disliked this movie
    if (user.dislikedMovies.contains(movie.id.toString())) {
      return 0.2; // Low score so it gets down-ranked
    }

    // Composite rating from online sources (0–1)
    double ratingScore = 0.5;
    final ratings = <double>[];
    if (movie.voteAverage != null && (movie.voteCount ?? 0) >= 10) {
      ratings.add((movie.voteAverage! / 10.0).clamp(0.0, 1.0));
    }
    if (movie.imdbRating != null && (movie.imdbVotes ?? 0) >= 100) {
      ratings.add((movie.imdbRating! / 10.0).clamp(0.0, 1.0));
    }
    if (movie.rottenTomatoesAudienceScore != null) {
      ratings.add((movie.rottenTomatoesAudienceScore! / 100.0).clamp(0.0, 1.0));
    }
    if (movie.rottenTomatoesTomatometer != null) {
      ratings.add((movie.rottenTomatoesTomatometer! / 100.0).clamp(0.0, 1.0));
    }
    if (ratings.isNotEmpty) {
      ratingScore = ratings.reduce((a, b) => a + b) / ratings.length;
      score += (ratingScore - 0.5) * 0.4; // ±0.2 from rating
    } else if (movie.voteAverage != null && movie.voteAverage! > 7.0) {
      score += 0.1;
    }

    // Credibility: more votes = more reliable rating
    if (movie.voteCount != null && movie.voteCount! >= 100) {
      score += 0.05;
    }
    if (movie.voteCount != null && movie.voteCount! >= 1000) {
      score += 0.05;
    }

    // Popularity (trending / well-known)
    if (movie.popularity != null && movie.popularity! > 50) {
      score += 0.05;
    }
    if (movie.popularity != null && movie.popularity! > 100) {
      score += 0.05;
    }

    // Slight boost when user has likes (preference signal) and movie has genres
    if (movie.genreIds != null && movie.genreIds!.isNotEmpty && user.likedMovies.isNotEmpty) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Gets deep learning weight multiplier for a movie
  Future<double> getDeepLearningWeight(User user, Movie movie) async {
    final prediction = await getPredictionScore(user, movie);

    // Convert prediction (0-1) to weight multiplier (0.5-1.5)
    return 0.5 + (prediction * 1.0);
  }

  /// Batch prediction for multiple movies (more efficient)
  Future<List<double>> getBatchPredictions(
      User user, List<Movie> movies) async {
    final predictions = <double>[];

    for (final movie in movies) {
      final prediction = await getPredictionScore(user, movie);
      predictions.add(prediction);
    }

    return predictions;
  }

  /// Checks if model is loaded and ready
  bool get isModelReady => _isModelLoaded;

  /// Model information
  String? get modelInfo => _isModelLoaded
      ? 'Model loaded from: $_modelPath'
      : 'Model not loaded (using fallback scoring)';
}
