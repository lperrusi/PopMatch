import 'dart:math' show sqrt, log;
import '../models/movie.dart';

/// Service for creating and using movie embeddings for semantic similarity
/// Enhanced with text-based features and better feature engineering
class MovieEmbeddingService {
  static final MovieEmbeddingService _instance = MovieEmbeddingService._internal();
  factory MovieEmbeddingService() => _instance;
  MovieEmbeddingService._internal();

  // Cache for movie embeddings
  final Map<int, List<double>> _embeddingCache = {};
  
  /// Creates an embedding vector for a movie based on its metadata
  /// ENHANCED: Now includes text-based features from descriptions
  List<double> createEmbedding(Movie movie) {
    if (_embeddingCache.containsKey(movie.id)) {
      return _embeddingCache[movie.id]!;
    }

    // Create a 64-dimensional embedding vector (increased from 50)
    final embedding = List<double>.filled(64, 0.0);
    int index = 0;

    // Genre features (first 20 dimensions)
    if (movie.genreIds != null) {
      for (final _ in movie.genreIds!) {
        if (index < 20) {
          embedding[index] = 1.0;
          index++;
        }
      }
    }

    // Rating features (dimensions 20-25)
    if (movie.voteAverage != null) {
      final normalizedRating = (movie.voteAverage! / 10.0).clamp(0.0, 1.0);
      for (int i = 20; i < 25; i++) {
        embedding[i] = normalizedRating;
      }
    }

    // Year features (dimensions 25-30)
    if (movie.year != null) {
      final year = int.tryParse(movie.year!);
      if (year != null) {
        final normalizedYear = ((year - 1900) / 130.0).clamp(0.0, 1.0);
        for (int i = 25; i < 30; i++) {
          embedding[i] = normalizedYear;
        }
      }
    }

    // Popularity features (dimensions 30-35)
    if (movie.popularity != null) {
      final normalizedPopularity = (movie.popularity! / 100.0).clamp(0.0, 1.0);
      for (int i = 30; i < 35; i++) {
        embedding[i] = normalizedPopularity;
      }
    }

    // Runtime features (dimensions 35-40)
    if (movie.runtime != null) {
      final normalizedRuntime = (movie.runtime! / 200.0).clamp(0.0, 1.0);
      for (int i = 35; i < 40; i++) {
        embedding[i] = normalizedRuntime;
      }
    }

    // Vote count features (dimensions 40-45)
    if (movie.voteCount != null) {
      final normalizedVoteCount = (log(movie.voteCount! + 1) / 15.0).clamp(0.0, 1.0);
      for (int i = 40; i < 45; i++) {
        embedding[i] = normalizedVoteCount;
      }
    }

    // Language features (dimensions 45-50)
    if (movie.originalLanguage != null) {
      final langHash = movie.originalLanguage!.hashCode.toDouble();
      for (int i = 45; i < 50; i++) {
        embedding[i] = (langHash % 100) / 100.0;
      }
    }

    // ENHANCED: Text-based features from description (dimensions 50-64)
    if (movie.overview != null && movie.overview!.isNotEmpty) {
      final overview = movie.overview!.toLowerCase();
      final words = overview.split(RegExp(r'\W+'));
      
      // Feature 50-55: Genre-related keywords in description
      final genreKeywords = ['action', 'adventure', 'comedy', 'drama', 'horror', 'thriller'];
      for (int i = 0; i < genreKeywords.length && (50 + i) < 64; i++) {
        final keyword = genreKeywords[i];
        final count = words.where((w) => w.contains(keyword)).length;
        embedding[50 + i] = (count / words.length).clamp(0.0, 1.0);
      }
      
      // Feature 56-59: Description length and complexity
      final wordCount = words.length;
      embedding[56] = (wordCount / 200.0).clamp(0.0, 1.0); // Normalized word count
      embedding[57] = (words.toSet().length / wordCount).clamp(0.0, 1.0); // Vocabulary diversity
      
      // Feature 58-59: Emotional tone indicators
      final positiveWords = ['love', 'happy', 'joy', 'success', 'win', 'hero', 'good'];
      final negativeWords = ['death', 'dark', 'fear', 'danger', 'evil', 'war', 'loss'];
      final positiveCount = words.where((w) => positiveWords.any((pw) => w.contains(pw))).length;
      final negativeCount = words.where((w) => negativeWords.any((nw) => w.contains(nw))).length;
      embedding[58] = (positiveCount / wordCount).clamp(0.0, 1.0);
      embedding[59] = (negativeCount / wordCount).clamp(0.0, 1.0);
      
      // Feature 60-63: Thematic keywords
      final themes = ['space', 'future', 'past', 'journey', 'quest', 'battle', 'mystery', 'family'];
      for (int i = 0; i < 4 && (60 + i) < 64; i++) {
        if (i < themes.length) {
          final theme = themes[i];
          final count = words.where((w) => w.contains(theme)).length;
          embedding[60 + i] = (count / wordCount).clamp(0.0, 1.0);
        }
      }
    }

    // Normalize the embedding
    final magnitude = sqrt(embedding.map((e) => e * e).reduce((a, b) => a + b));
    if (magnitude > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= magnitude;
      }
    }

    _embeddingCache[movie.id] = embedding;
    return embedding;
  }

  /// Calculates cosine similarity between two movie embeddings
  double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0.0 || magnitude2 == 0.0) return 0.0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Gets similarity score between two movies
  double getMovieSimilarity(Movie movie1, Movie movie2) {
    final embedding1 = createEmbedding(movie1);
    final embedding2 = createEmbedding(movie2);
    return cosineSimilarity(embedding1, embedding2);
  }

  /// Finds most similar movies to a given movie
  List<Movie> findSimilarMovies(Movie targetMovie, List<Movie> candidateMovies, {int limit = 10}) {
    final targetEmbedding = createEmbedding(targetMovie);
    final similarities = <Movie, double>{};

    for (final movie in candidateMovies) {
      if (movie.id == targetMovie.id) continue;
      
      final candidateEmbedding = createEmbedding(movie);
      final similarity = cosineSimilarity(targetEmbedding, candidateEmbedding);
      similarities[movie] = similarity;
    }

    // Sort by similarity and return top results
    final sorted = similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Gets embedding-based weight for a movie recommendation
  /// IMPROVED: Better normalization and average similarity for more stable scores
  double getEmbeddingWeight(Movie candidateMovie, List<Movie> likedMovies) {
    if (likedMovies.isEmpty) return 1.0;

    double maxSimilarity = 0.0;
    double avgSimilarity = 0.0;
    final candidateEmbedding = createEmbedding(candidateMovie);

    for (final likedMovie in likedMovies) {
      final likedEmbedding = createEmbedding(likedMovie);
      final similarity = cosineSimilarity(candidateEmbedding, likedEmbedding);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
      }
      avgSimilarity += similarity;
    }
    
    avgSimilarity /= likedMovies.length;

    // IMPROVED: Use combination of max and average similarity
    // Max finds best match, average finds consistent patterns
    // Convert to 0-1 range for scoring (similarity is already 0-1)
    // Use 60% max, 40% average for balanced scoring
    final combinedSimilarity = (maxSimilarity * 0.6) + (avgSimilarity * 0.4);
    
    // Convert similarity (0-1) to weight (0-1 range for additive scoring)
    // Higher similarity = higher weight, but ensure minimum of 0.3 for any match
    return 0.3 + (combinedSimilarity * 0.7);
  }

  /// Clears embedding cache
  void clearCache() {
    _embeddingCache.clear();
  }
}

