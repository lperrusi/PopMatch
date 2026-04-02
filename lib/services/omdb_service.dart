import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// External ratings model
class ExternalRatings {
    final double? imdbRating; // 0-10 scale
    final int? imdbVotes;
    final int? rottenTomatoesTomatometer; // 0-100%
    final int? rottenTomatoesAudienceScore; // 0-100%
    final String? metacriticScore; // 0-100 (as string, e.g., "85/100")
    
    ExternalRatings({
      this.imdbRating,
      this.imdbVotes,
      this.rottenTomatoesTomatometer,
      this.rottenTomatoesAudienceScore,
      this.metacriticScore,
    });
    
    /// Gets normalized IMDb rating (0-1 scale)
    double? get normalizedImdbRating => imdbRating != null ? imdbRating! / 10.0 : null;
    
    /// Gets normalized Rotten Tomatoes Tomatometer (0-1 scale)
    double? get normalizedRottenTomatoes => rottenTomatoesTomatometer != null ? rottenTomatoesTomatometer! / 100.0 : null;
    
    /// Gets normalized Rotten Tomatoes Audience Score (0-1 scale)
    double? get normalizedRottenTomatoesAudience => rottenTomatoesAudienceScore != null ? rottenTomatoesAudienceScore! / 100.0 : null;
    
    /// Gets a combined quality score from all available ratings (0-1 scale)
    /// Weights: IMDb 40%, RT Tomatometer 30%, RT Audience 20%, Metacritic 10%
    double? get combinedQualityScore {
      final scores = <double>[];
      final weights = <double>[];
      
      if (normalizedImdbRating != null) {
        scores.add(normalizedImdbRating!);
        weights.add(0.40);
      }
      if (normalizedRottenTomatoes != null) {
        scores.add(normalizedRottenTomatoes!);
        weights.add(0.30);
      }
      if (normalizedRottenTomatoesAudience != null) {
        scores.add(normalizedRottenTomatoesAudience!);
        weights.add(0.20);
      }
      if (metacriticScore != null && metacriticScore!.isNotEmpty) {
        try {
          final metaScore = int.parse(metacriticScore!.split('/').first);
          scores.add(metaScore / 100.0);
          weights.add(0.10);
        } catch (e) {
          // Ignore parsing errors
        }
      }
      
      if (scores.isEmpty) return null;
      
      // Normalize weights
      final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
      if (totalWeight == 0) return null;
      
      double weightedSum = 0.0;
      for (int i = 0; i < scores.length; i++) {
        weightedSum += scores[i] * (weights[i] / totalWeight);
      }
      
      return weightedSum;
    }
}

/// Cached rating entry
class _CachedRating {
    final ExternalRatings ratings;
    final DateTime cachedAt;
    
    _CachedRating(this.ratings, this.cachedAt);
    
    bool isExpired(Duration cacheExpiry) => DateTime.now().difference(cachedAt) > cacheExpiry;
}

/// Service for fetching external ratings (IMDb, Rotten Tomatoes) from OMDb API
///
/// Configure the key via [setApiKey], [loadApiKey] (SharedPreferences), or at app
/// startup: `flutter run --dart-define=OMDB_API_KEY=...`.
///
/// OMDb API provides:
/// - IMDb rating (0-10 scale)
/// - Rotten Tomatoes Tomatometer (0-100%)
/// - Rotten Tomatoes Audience Score (0-100%)
/// 
/// Free tier: 1,000 requests per day
/// Get API key from: http://www.omdbapi.com/apikey.aspx
class OMDbService {
  static OMDbService? _instance;
  static OMDbService get instance => _instance ??= OMDbService._();
  
  OMDbService._();

  // OMDb API base URL
  static const String _baseUrl = 'http://www.omdbapi.com/';
  
  // API key - set via setApiKey() method
  String? _apiKey;
  
  // Cache for ratings to avoid repeated API calls
  final Map<String, _CachedRating> _ratingsCache = {};
  static const Duration _cacheExpiry = Duration(hours: 24); // Cache for 24 hours
  
  /// Sets the OMDb API key
  /// Get one from: http://www.omdbapi.com/apikey.aspx
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omdb_api_key', apiKey);
  }
  
  /// Loads API key from storage
  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('omdb_api_key');
  }
  
  /// Fetches external ratings for a movie/show by IMDb ID
  /// Returns null if API key is not set or if ratings are not available
  Future<ExternalRatings?> getRatingsByImdbId(String imdbId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      await loadApiKey();
      if (_apiKey == null || _apiKey!.isEmpty) {
        return null; // No API key configured
      }
    }
    
    // Check cache first
    if (_ratingsCache.containsKey(imdbId)) {
      final cached = _ratingsCache[imdbId]!;
      if (!cached.isExpired(_cacheExpiry)) {
        return cached.ratings;
      } else {
        _ratingsCache.remove(imdbId); // Remove expired cache
      }
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?apikey=$_apiKey&i=$imdbId&tomatoes=true'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['Response'] == 'False') {
          // Movie/show not found or API error
          return null;
        }
        
        // Parse ratings
        final ratings = _parseRatings(data);
        
        // Cache the result
        _ratingsCache[imdbId] = _CachedRating(ratings, DateTime.now());
        
        return ratings;
      } else {
        return null;
      }
    } catch (e) {
      // Return null on error (don't throw, just fail silently)
      return null;
    }
  }
  
  /// Parses ratings from OMDb API response
  ExternalRatings _parseRatings(Map<String, dynamic> data) {
    double? imdbRating;
    int? imdbVotes;
    int? rottenTomatoesTomatometer;
    int? rottenTomatoesAudienceScore;
    String? metacriticScore;
    
    // Parse IMDb rating
    if (data['imdbRating'] != null && data['imdbRating'] != 'N/A') {
      try {
        imdbRating = double.parse(data['imdbRating']);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Parse IMDb votes
    if (data['imdbVotes'] != null && data['imdbVotes'] != 'N/A') {
      try {
        final votesStr = (data['imdbVotes'] as String).replaceAll(',', '');
        imdbVotes = int.parse(votesStr);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Parse Rotten Tomatoes ratings from Ratings array
    if (data['Ratings'] != null && data['Ratings'] is List) {
      final ratings = data['Ratings'] as List;
      for (final rating in ratings) {
        final source = rating['Source'] as String? ?? '';
        final value = rating['Value'] as String? ?? '';
        
        if (source.contains('Rotten Tomatoes')) {
          try {
            // Value format: "85%" or "85/100"
            final percentage = value.replaceAll('%', '').split('/').first;
            final score = int.parse(percentage);
            
            if (source.contains('Tomatometer')) {
              rottenTomatoesTomatometer = score;
            } else if (source.contains('Audience')) {
              rottenTomatoesAudienceScore = score;
            }
          } catch (e) {
            // Ignore parsing errors
          }
        } else if (source == 'Metacritic') {
          metacriticScore = value; // Keep as string, e.g., "85/100"
        }
      }
    }
    
    return ExternalRatings(
      imdbRating: imdbRating,
      imdbVotes: imdbVotes,
      rottenTomatoesTomatometer: rottenTomatoesTomatometer,
      rottenTomatoesAudienceScore: rottenTomatoesAudienceScore,
      metacriticScore: metacriticScore,
    );
  }
  
  /// Clears the ratings cache
  void clearCache() {
    _ratingsCache.clear();
  }
  
  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    int expired = 0;
    int valid = 0;
    
    for (final entry in _ratingsCache.values) {
      if (entry.isExpired(_cacheExpiry)) {
        expired++;
      } else {
        valid++;
      }
    }
    
    return {
      'total': _ratingsCache.length,
      'valid': valid,
      'expired': expired,
    };
  }
}
