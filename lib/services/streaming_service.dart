import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/streaming_platform.dart';
import '../models/movie.dart';

/// Service for handling streaming platform data and availability
class StreamingService {
  static StreamingService? _instance;
  static StreamingService get instance => _instance ??= StreamingService._();
  
  StreamingService._();

  // Mock data for demonstration - in a real app, this would come from an API
  final Map<int, MovieStreamingAvailability> _mockStreamingData = {
    1: MovieStreamingAvailability(
      movieId: 1, // The Shawshank Redemption
      availablePlatforms: ['netflix', 'hbo_max'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    2: MovieStreamingAvailability(
      movieId: 2, // The Godfather
      availablePlatforms: ['netflix', 'paramount_plus'],
      rentalPrice: '\$4.99',
      purchasePrice: '\$16.99',
      isFree: false,
    ),
    3: MovieStreamingAvailability(
      movieId: 3, // The Dark Knight
      availablePlatforms: ['netflix', 'hbo_max', 'amazon_prime'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    4: MovieStreamingAvailability(
      movieId: 4, // Pulp Fiction
      availablePlatforms: ['netflix', 'hbo_max'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    5: MovieStreamingAvailability(
      movieId: 5, // Fight Club
      availablePlatforms: ['netflix', 'amazon_prime', 'hulu'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
          // Additional movies for variety
      550: MovieStreamingAvailability(
        movieId: 550, // Fight Club (different ID)
        availablePlatforms: ['netflix', 'amazon_prime', 'hulu'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$14.99',
        isFree: false,
      ),
      // Add more movies to cover a wider range
      1087192: MovieStreamingAvailability(
        movieId: 1087192, // How to Train Your Dragon
        availablePlatforms: ['netflix', 'disney_plus', 'amazon_prime'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$14.99',
        isFree: false,
      ),
      299536: MovieStreamingAvailability(
        movieId: 299536, // Avengers: Infinity War
        availablePlatforms: ['disney_plus', 'amazon_prime'],
        rentalPrice: '\$4.99',
        purchasePrice: '\$19.99',
        isFree: false,
      ),
      181808: MovieStreamingAvailability(
        movieId: 181808, // Star Wars: The Last Jedi
        availablePlatforms: ['disney_plus', 'amazon_prime'],
        rentalPrice: '\$4.99',
        purchasePrice: '\$19.99',
        isFree: false,
      ),
      420817: MovieStreamingAvailability(
        movieId: 420817, // Aladdin (2019)
        availablePlatforms: ['disney_plus', 'amazon_prime'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$14.99',
        isFree: false,
      ),
      475557: MovieStreamingAvailability(
        movieId: 475557, // Joker
        availablePlatforms: ['hbo_max', 'amazon_prime'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$14.99',
        isFree: false,
      ),
      496243: MovieStreamingAvailability(
        movieId: 496243, // Parasite
        availablePlatforms: ['hulu', 'amazon_prime'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$12.99',
        isFree: false,
      ),
      508947: MovieStreamingAvailability(
        movieId: 508947, // Turning Red
        availablePlatforms: ['disney_plus'],
        rentalPrice: null,
        purchasePrice: null,
        isFree: true,
      ),
      508442: MovieStreamingAvailability(
        movieId: 508442, // Soul
        availablePlatforms: ['disney_plus'],
        rentalPrice: null,
        purchasePrice: null,
        isFree: true,
      ),
      508943: MovieStreamingAvailability(
        movieId: 508943, // Luca
        availablePlatforms: ['disney_plus'],
        rentalPrice: null,
        purchasePrice: null,
        isFree: true,
      ),
      315162: MovieStreamingAvailability(
        movieId: 315162, // Puss in Boots: The Last Wish
        availablePlatforms: ['netflix', 'amazon_prime'],
        rentalPrice: '\$3.99',
        purchasePrice: '\$14.99',
        isFree: false,
      ),
    13: MovieStreamingAvailability(
      movieId: 13, // Forrest Gump
      availablePlatforms: ['netflix', 'disney_plus'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$12.99',
      isFree: false,
    ),
    238: MovieStreamingAvailability(
      movieId: 238, // The Godfather (different ID)
      availablePlatforms: ['netflix', 'paramount_plus'],
      rentalPrice: '\$4.99',
      purchasePrice: '\$16.99',
      isFree: false,
    ),
    680: MovieStreamingAvailability(
      movieId: 680, // Pulp Fiction (different ID)
      availablePlatforms: ['netflix', 'hbo_max'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    155: MovieStreamingAvailability(
      movieId: 155, // The Dark Knight (different ID)
      availablePlatforms: ['netflix', 'hbo_max', 'amazon_prime'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    244786: MovieStreamingAvailability(
      movieId: 244786, // Whiplash
      availablePlatforms: ['netflix', 'hulu'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$12.99',
      isFree: false,
    ),
    278: MovieStreamingAvailability(
      movieId: 278, // The Shawshank Redemption (different ID)
      availablePlatforms: ['netflix', 'hbo_max'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    424: MovieStreamingAvailability(
      movieId: 424, // Schindler's List
      availablePlatforms: ['netflix'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    497: MovieStreamingAvailability(
      movieId: 497, // The Green Mile
      availablePlatforms: ['netflix', 'hbo_max'],
      rentalPrice: '\$3.99',
      purchasePrice: '\$14.99',
      isFree: false,
    ),
    240: MovieStreamingAvailability(
      movieId: 240, // The Godfather Part II
      availablePlatforms: ['netflix', 'paramount_plus'],
      rentalPrice: '\$4.99',
      purchasePrice: '\$16.99',
      isFree: false,
    ),
  };

  /// Gets streaming availability for a movie
  Future<MovieStreamingAvailability?> getStreamingAvailability(int movieId) async {
    try {
      print('Fetching streaming availability for movie ID: $movieId');
      
      // First try to get from mock data (for demo purposes)
      final mockData = _mockStreamingData[movieId];
      if (mockData != null) {
        print('Found mock data for movie ID $movieId: ${mockData.availablePlatforms}');
        // Simulate API delay
        await Future.delayed(const Duration(milliseconds: 500));
        return mockData;
      }

      print('No mock data found for movie ID $movieId');
      
      // Generate fallback streaming availability for demo purposes
      // In a real app, you would integrate with a streaming availability API
      // For example, JustWatch API, Streaming Availability API, etc.
      final fallbackAvailability = _generateFallbackAvailability(movieId);
      if (fallbackAvailability != null) {
        print('Generated fallback availability for movie ID $movieId');
        return fallbackAvailability;
      }
      
      return null;
    } catch (e) {
      print('Error fetching streaming availability: $e');
      return null;
    }
  }

  /// Gets streaming availability from a real API (placeholder for future implementation)
  Future<MovieStreamingAvailability?> getStreamingAvailabilityFromAPI(int movieId) async {
    try {
      // This would be the real API call to a streaming availability service
      // Example APIs: JustWatch, Streaming Availability, etc.
      
      // For now, return null as this is a placeholder
      return null;
    } catch (e) {
      print('Error fetching from streaming API: $e');
      return null;
    }
  }

  /// Gets streaming availability for multiple movies
  Future<Map<int, MovieStreamingAvailability>> getStreamingAvailabilityForMovies(List<int> movieIds) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final Map<int, MovieStreamingAvailability> result = {};
    for (final movieId in movieIds) {
      final availability = _mockStreamingData[movieId];
      if (availability != null) {
        result[movieId] = availability;
      }
    }
    
    return result;
  }

  /// Gets all available streaming platforms
  List<StreamingPlatform> getAvailablePlatforms() {
    return StreamingPlatform.getAvailablePlatforms();
  }

  /// Gets platform by ID
  StreamingPlatform? getPlatformById(String platformId) {
    return StreamingPlatform.getById(platformId);
  }

  /// Filters movies by streaming platform
  Future<List<Movie>> filterMoviesByPlatform(List<Movie> movies, String platformId) async {
    final List<Movie> filteredMovies = [];
    
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.isAvailableOn(platformId)) {
        // Add streaming availability to the movie
        final movieWithAvailability = movie.copyWith(
          streamingAvailability: availability,
        );
        filteredMovies.add(movieWithAvailability);
      }
    }
    
    return filteredMovies;
  }

  /// Gets movies available on multiple platforms
  Future<List<Movie>> getMoviesOnMultiplePlatforms(List<Movie> movies, List<String> platformIds) async {
    final List<Movie> filteredMovies = [];
    
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null) {
        bool isAvailableOnAny = false;
        for (final platformId in platformIds) {
          if (availability.isAvailableOn(platformId)) {
            isAvailableOnAny = true;
            break;
          }
        }
        
        if (isAvailableOnAny) {
          final movieWithAvailability = movie.copyWith(
            streamingAvailability: availability,
          );
          filteredMovies.add(movieWithAvailability);
        }
      }
    }
    
    return filteredMovies;
  }

  /// Gets free movies
  Future<List<Movie>> getFreeMovies(List<Movie> movies) async {
    final List<Movie> freeMovies = [];
    
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.isFree) {
        final movieWithAvailability = movie.copyWith(
          streamingAvailability: availability,
        );
        freeMovies.add(movieWithAvailability);
      }
    }
    
    return freeMovies;
  }

  /// Gets movies available for rent under a certain price
  Future<List<Movie>> getMoviesUnderRentalPrice(List<Movie> movies, double maxPrice) async {
    final List<Movie> affordableMovies = [];
    
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.rentalPrice != null) {
        // Extract price from string (e.g., "$3.99" -> 3.99)
        final priceString = availability.rentalPrice!.replaceAll('\$', '');
        final price = double.tryParse(priceString);
        
        if (price != null && price <= maxPrice) {
          final movieWithAvailability = movie.copyWith(
            streamingAvailability: availability,
          );
          affordableMovies.add(movieWithAvailability);
        }
      }
    }
    
    return affordableMovies;
  }

  /// Gets platform statistics
  Future<Map<String, int>> getPlatformStatistics(List<Movie> movies) async {
    final Map<String, int> platformStats = {};
    
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null) {
        for (final platformId in availability.availablePlatforms) {
          platformStats[platformId] = (platformStats[platformId] ?? 0) + 1;
        }
      }
    }
    
    return platformStats;
  }

  /// Generates fallback streaming availability for movies not in mock data
  MovieStreamingAvailability? _generateFallbackAvailability(int movieId) {
    // Use movie ID to generate deterministic but varied availability
    final random = movieId % 10; // Use modulo to create variety
    
    // Different availability patterns based on movie ID
    switch (random) {
      case 0:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['netflix', 'amazon_prime'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
      case 1:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['disney_plus', 'amazon_prime'],
          rentalPrice: '\$4.99',
          purchasePrice: '\$19.99',
          isFree: false,
        );
      case 2:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['hulu', 'amazon_prime'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$12.99',
          isFree: false,
        );
      case 3:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['hbo_max', 'amazon_prime'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
      case 4:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['netflix', 'hulu'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
      case 5:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['disney_plus'],
          rentalPrice: null,
          purchasePrice: null,
          isFree: true,
        );
      case 6:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['netflix', 'paramount_plus'],
          rentalPrice: '\$4.99',
          purchasePrice: '\$16.99',
          isFree: false,
        );
      case 7:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['amazon_prime', 'hulu'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
      case 8:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['netflix', 'hbo_max'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
      case 9:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['tubi'],
          rentalPrice: null,
          purchasePrice: null,
          isFree: true,
        );
      default:
        return MovieStreamingAvailability(
          movieId: movieId,
          availablePlatforms: ['netflix'],
          rentalPrice: '\$3.99',
          purchasePrice: '\$14.99',
          isFree: false,
        );
    }
  }
} 