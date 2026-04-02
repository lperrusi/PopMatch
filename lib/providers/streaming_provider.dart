import 'package:flutter/foundation.dart';
import '../models/streaming_platform.dart';
import '../models/movie.dart';
import '../services/streaming_service.dart';

/// Provider for managing streaming platform data and filtering
class StreamingProvider with ChangeNotifier {
  final StreamingService _streamingService = StreamingService.instance;
  
  // Available platforms
  List<StreamingPlatform> _availablePlatforms = [];
  
  // Selected platforms for filtering
  final List<String> _selectedPlatformIds = [];
  
  // Filtered movies
  List<Movie> _filteredMovies = [];
  
  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StreamingPlatform> get availablePlatforms => _availablePlatforms;
  List<String> get selectedPlatformIds => _selectedPlatformIds;
  List<Movie> get filteredMovies => _filteredMovies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initializes the provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availablePlatforms = _streamingService.getAvailablePlatforms();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a platform for filtering
  void selectPlatform(String platformId) {
    if (!_selectedPlatformIds.contains(platformId)) {
      _selectedPlatformIds.add(platformId);
      notifyListeners();
    }
  }

  /// Deselects a platform
  void deselectPlatform(String platformId) {
    _selectedPlatformIds.remove(platformId);
    notifyListeners();
  }

  /// Clears all selected platforms
  void clearSelectedPlatforms() {
    _selectedPlatformIds.clear();
    notifyListeners();
  }

  /// Filters movies by selected platforms
  Future<void> filterMoviesByPlatforms(List<Movie> movies) async {
    if (_selectedPlatformIds.isEmpty) {
      _filteredMovies = movies;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredMovies = await _streamingService.getMoviesOnMultiplePlatforms(
        movies,
        _selectedPlatformIds,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters movies by a single platform
  Future<void> filterMoviesByPlatform(List<Movie> movies, String platformId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredMovies = await _streamingService.filterMoviesByPlatform(
        movies,
        platformId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets free movies
  Future<void> getFreeMovies(List<Movie> movies) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredMovies = await _streamingService.getFreeMovies(movies);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets movies under a certain rental price
  Future<void> getMoviesUnderRentalPrice(List<Movie> movies, double maxPrice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredMovies = await _streamingService.getMoviesUnderRentalPrice(
        movies,
        maxPrice,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets streaming availability for a movie (TMDB watch/providers).
  Future<MovieStreamingAvailability?> getStreamingAvailability(int movieId) async {
    try {
      return await _streamingService.getStreamingAvailability(movieId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Gets streaming availability for a TV series (TMDB watch/providers).
  Future<MovieStreamingAvailability?> getStreamingAvailabilityForTv(int seriesId) async {
    try {
      return await _streamingService.getStreamingAvailabilityForTv(seriesId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Gets platform by ID
  StreamingPlatform? getPlatformById(String platformId) {
    return _streamingService.getPlatformById(platformId);
  }

  /// Checks if a platform is selected
  bool isPlatformSelected(String platformId) {
    return _selectedPlatformIds.contains(platformId);
  }

  /// Gets selected platforms as StreamingPlatform objects
  List<StreamingPlatform> get selectedPlatforms {
    return _selectedPlatformIds
        .map((id) => getPlatformById(id))
        .whereType<StreamingPlatform>()
        .toList();
  }

  /// Gets platform statistics for a list of movies
  Future<Map<String, int>> getPlatformStatistics(List<Movie> movies) async {
    try {
      return await _streamingService.getPlatformStatistics(movies);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  /// Clears filtered movies
  void clearFilteredMovies() {
    _filteredMovies.clear();
    notifyListeners();
  }

  /// Clears error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 