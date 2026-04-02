import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Matrix Factorization service for collaborative filtering
/// Uses simplified SVD-like approach to learn latent factors
/// 
/// This service learns user and movie embeddings from interaction patterns
/// and can predict ratings/relevance for unseen movies
class MatrixFactorizationService {
  static final MatrixFactorizationService _instance = MatrixFactorizationService._internal();
  factory MatrixFactorizationService() => _instance;
  MatrixFactorizationService._internal();

  bool _isLoaded = false;
  Future<void>? _loadInFlight;

  // User embeddings: userId -> List<double> (latent factors)
  final Map<String, List<double>> _userEmbeddings = {};
  
  // Movie embeddings: movieId -> List<double> (latent factors)
  final Map<int, List<double>> _movieEmbeddings = {};
  
  // Number of latent factors (dimensions)
  static const int _numFactors = 20;
  
  // Learning rate for gradient descent
  static const double _learningRate = 0.01;
  
  // Regularization parameter
  static const double _regularization = 0.1;
  
  // Random number generator
  final Random _random = Random();

  /// Initializes embeddings for a user (if not exists)
  void _initializeUserEmbedding(String userId) {
    if (!_userEmbeddings.containsKey(userId)) {
      _userEmbeddings[userId] = List.generate(
        _numFactors,
        (_) => _random.nextDouble() * 0.1 - 0.05, // Small random values
      );
    }
  }

  /// Initializes embeddings for a movie (if not exists)
  void _initializeMovieEmbedding(int movieId) {
    if (!_movieEmbeddings.containsKey(movieId)) {
      _movieEmbeddings[movieId] = List.generate(
        _numFactors,
        (_) => _random.nextDouble() * 0.1 - 0.05, // Small random values
      );
    }
  }

  /// Raw dot product prediction (can be negative for dislike target).
  double _rawPredict(String userId, int movieId) {
    _initializeUserEmbedding(userId);
    _initializeMovieEmbedding(movieId);
    final userVec = _userEmbeddings[userId]!;
    final movieVec = _movieEmbeddings[movieId]!;
    double prediction = 0.0;
    for (int i = 0; i < _numFactors; i++) {
      prediction += userVec[i] * movieVec[i];
    }
    return prediction;
  }

  /// Predicts rating/relevance for a user-movie pair (0-1 normalized).
  double predict(String userId, int movieId) {
    final raw = _rawPredict(userId, movieId);
    return ((raw + 0.5) / 1.5).clamp(0.0, 1.0);
  }

  /// Updates embeddings based on user feedback (online learning).
  /// [actualRating] like=1.0, dislike=-0.5, neutral=0.0.
  Future<void> updateFromFeedback(
    String userId,
    int movieId,
    double actualRating,
  ) async {
    _initializeUserEmbedding(userId);
    _initializeMovieEmbedding(movieId);
    
    final userVec = _userEmbeddings[userId]!;
    final movieVec = _movieEmbeddings[movieId]!;
    
    final rawPredicted = _rawPredict(userId, movieId);
    final error = actualRating - rawPredicted;
    
    // Update embeddings using gradient descent
    for (int i = 0; i < _numFactors; i++) {
      final userFactor = userVec[i];
      final movieFactor = movieVec[i];
      
      // Gradient for user embedding
      final userGradient = error * movieFactor - _regularization * userFactor;
      userVec[i] = userFactor + _learningRate * userGradient;
      
      // Gradient for movie embedding
      final movieGradient = error * userFactor - _regularization * movieFactor;
      movieVec[i] = movieFactor + _learningRate * movieGradient;
    }
    
    await _saveToStorage();
  }

  /// Batch updates embeddings from user's liked movies
  /// More efficient than individual updates
  Future<void> updateFromUserLikes(String userId, List<int> likedMovieIds) async {
    _initializeUserEmbedding(userId);
    
    // Update for each liked movie
    for (final movieId in likedMovieIds) {
      _initializeMovieEmbedding(movieId);
      await updateFromFeedback(userId, movieId, 1.0);
    }
  }

  /// Gets similarity score between two movies based on embeddings
  double getMovieSimilarity(int movieId1, int movieId2) {
    if (!_movieEmbeddings.containsKey(movieId1) || 
        !_movieEmbeddings.containsKey(movieId2)) {
      return 0.0;
    }
    
    final vec1 = _movieEmbeddings[movieId1]!;
    final vec2 = _movieEmbeddings[movieId2]!;
    
    // Cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < _numFactors; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Gets similarity score between two users based on embeddings
  double getUserSimilarity(String userId1, String userId2) {
    if (!_userEmbeddings.containsKey(userId1) || 
        !_userEmbeddings.containsKey(userId2)) {
      return 0.0;
    }
    
    final vec1 = _userEmbeddings[userId1]!;
    final vec2 = _userEmbeddings[userId2]!;
    
    // Cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < _numFactors; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Gets matrix factorization weight for a movie (0-1 range)
  double getMatrixFactorizationWeight(String userId, int movieId) {
    return predict(userId, movieId);
  }

  /// Saves embeddings to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user embeddings
      final userEmbeddingsData = <String, dynamic>{};
      for (final entry in _userEmbeddings.entries) {
        userEmbeddingsData[entry.key] = entry.value;
      }
      await prefs.setString('mf_user_embeddings', jsonEncode(userEmbeddingsData));
      
      // Save movie embeddings
      final movieEmbeddingsData = <String, dynamic>{};
      for (final entry in _movieEmbeddings.entries) {
        movieEmbeddingsData[entry.key.toString()] = entry.value;
      }
      await prefs.setString('mf_movie_embeddings', jsonEncode(movieEmbeddingsData));
    } catch (e) {
      debugPrint('Error saving matrix factorization data: $e');
    }
  }

  /// Loads embeddings from persistent storage
  Future<void> loadFromStorage() async {
    if (_isLoaded) return;
    if (_loadInFlight != null) {
      await _loadInFlight;
      return;
    }

    _loadInFlight = () async {
      try {
        final prefs = await SharedPreferences.getInstance();

        // Load user embeddings
        final userEmbeddingsStr = prefs.getString('mf_user_embeddings');
        if (userEmbeddingsStr != null) {
          final userEmbeddingsData =
              jsonDecode(userEmbeddingsStr) as Map<String, dynamic>;
          _userEmbeddings.clear();
          for (final entry in userEmbeddingsData.entries) {
            final embedding = (entry.value as List)
                .map((e) => (e as num).toDouble())
                .toList();
            _userEmbeddings[entry.key] = embedding;
          }
        }

        // Load movie embeddings
        final movieEmbeddingsStr = prefs.getString('mf_movie_embeddings');
        if (movieEmbeddingsStr != null) {
          final movieEmbeddingsData =
              jsonDecode(movieEmbeddingsStr) as Map<String, dynamic>;
          _movieEmbeddings.clear();
          for (final entry in movieEmbeddingsData.entries) {
            final movieId = int.parse(entry.key);
            final embedding = (entry.value as List)
                .map((e) => (e as num).toDouble())
                .toList();
            _movieEmbeddings[movieId] = embedding;
          }
        }
      } catch (e) {
        debugPrint('Error loading matrix factorization data: $e');
      } finally {
        _isLoaded = true;
      }
    }();

    await _loadInFlight;
    _loadInFlight = null;
  }

  /// Clears all data (for testing or privacy)
  Future<void> clearData() async {
    _userEmbeddings.clear();
    _movieEmbeddings.clear();
    _isLoaded = false;
    _loadInFlight = null;
    await _saveToStorage();
  }

  /// Gets recommended movies using matrix factorization
  /// Returns movie IDs sorted by predicted rating
  List<int> getRecommendedMovies(String userId, Set<int> candidateMovieIds, {int limit = 20}) {
    _initializeUserEmbedding(userId);
    
    final movieScores = <int, double>{};
    
    for (final movieId in candidateMovieIds) {
      final score = predict(userId, movieId);
      movieScores[movieId] = score;
    }
    
    // Sort by score and return top recommendations
    final sorted = movieScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
