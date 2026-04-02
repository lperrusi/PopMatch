import '../models/movie.dart';

/// Service for handling advanced movie filtering and sorting
class FilterService {
  static FilterService? _instance;
  static FilterService get instance => _instance ??= FilterService._();
  
  FilterService._();

  /// Filter options
  static const List<String> sortOptions = [
    'relevance',
    'rating',
    'year',
    'title',
    'popularity',
    'runtime',
    'release_date',
  ];

  static const List<String> filterOptions = [
    'genre',
    'year',
    'rating',
    'runtime',
    'language',
    'adult_content',
    'availability',
  ];

  /// Sorts movies based on the specified criteria
  List<Movie> sortMovies(List<Movie> movies, String sortBy, {bool ascending = false}) {
    switch (sortBy) {
      case 'rating':
        movies.sort((a, b) {
          final ratingA = a.voteAverage ?? 0.0;
          final ratingB = b.voteAverage ?? 0.0;
          return ascending ? ratingA.compareTo(ratingB) : ratingB.compareTo(ratingA);
        });
        break;
      case 'year':
        movies.sort((a, b) {
          final yearA = int.tryParse(a.year ?? '0') ?? 0;
          final yearB = int.tryParse(b.year ?? '0') ?? 0;
          return ascending ? yearA.compareTo(yearB) : yearB.compareTo(yearA);
        });
        break;
      case 'title':
        movies.sort((a, b) {
          return ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title);
        });
        break;
      case 'popularity':
        movies.sort((a, b) {
          final popularityA = a.popularity ?? 0.0;
          final popularityB = b.popularity ?? 0.0;
          return ascending ? popularityA.compareTo(popularityB) : popularityB.compareTo(popularityA);
        });
        break;
      case 'release_date':
        movies.sort((a, b) {
          final dateA = a.releaseDate ?? '';
          final dateB = b.releaseDate ?? '';
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
      case 'relevance':
      default:
        // Keep original order for relevance
        break;
    }
    return movies;
  }

  /// Filters movies based on multiple criteria
  List<Movie> filterMovies(
    List<Movie> movies, {
    List<int>? genres,
    int? minYear,
    int? maxYear,
    double? minRating,
    double? maxRating,
    int? minRuntime,
    int? maxRuntime,
    List<String>? languages,
    bool? includeAdult,
    bool? availableOnly,
  }) {
    return movies.where((movie) {
      // Genre filter
      if (genres != null && genres.isNotEmpty) {
        if (movie.genreIds == null || 
            !genres.any((genre) => movie.genreIds!.contains(genre))) {
          return false;
        }
      }

      // Year filter
      if (minYear != null || maxYear != null) {
        final movieYear = int.tryParse(movie.year ?? '0') ?? 0;
        if (minYear != null && movieYear < minYear) return false;
        if (maxYear != null && movieYear > maxYear) return false;
      }

      // Rating filter
      if (minRating != null || maxRating != null) {
        final rating = movie.voteAverage ?? 0.0;
        if (minRating != null && rating < minRating) return false;
        if (maxRating != null && rating > maxRating) return false;
      }

      // Runtime filter (if available)
      if (minRuntime != null || maxRuntime != null) {
        // Runtime would need to be added to Movie model
        // For now, we'll skip this filter
      }

      // Language filter
      if (languages != null && languages.isNotEmpty) {
        if (movie.originalLanguage == null || 
            !languages.contains(movie.originalLanguage)) {
          return false;
        }
      }

      // Adult content filter
      if (includeAdult != null) {
        if (movie.isAdult != includeAdult) return false;
      }

      // Availability filter (placeholder for streaming availability)
      if (availableOnly == true) {
        // This would require integration with streaming availability APIs
        // For now, we'll skip this filter
      }

      return true;
    }).toList();
  }

  /// Gets available years from movie list
  List<int> getAvailableYears(List<Movie> movies) {
    final years = <int>{};
    for (final movie in movies) {
      if (movie.year != null) {
        years.add(int.parse(movie.year!));
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Gets available ratings from movie list
  List<double> getAvailableRatings(List<Movie> movies) {
    final ratings = <double>{};
    for (final movie in movies) {
      if (movie.voteAverage != null) {
        ratings.add(movie.voteAverage!);
      }
    }
    return ratings.toList()..sort();
  }

  /// Gets available languages from movie list
  List<String> getAvailableLanguages(List<Movie> movies) {
    final languages = <String>{};
    for (final movie in movies) {
      if (movie.originalLanguage != null && movie.originalLanguage!.isNotEmpty) {
        languages.add(movie.originalLanguage!);
      }
    }
    return languages.toList()..sort();
  }

  /// Gets available genres from movie list
  List<int> getAvailableGenres(List<Movie> movies) {
    final genres = <int>{};
    for (final movie in movies) {
      if (movie.genreIds != null) {
        genres.addAll(movie.genreIds!);
      }
    }
    return genres.toList()..sort();
  }

  /// Creates a filter summary
  String createFilterSummary({
    List<int>? genres,
    int? minYear,
    int? maxYear,
    double? minRating,
    double? maxRating,
    int? minRuntime,
    int? maxRuntime,
    List<String>? languages,
    bool? includeAdult,
    bool? availableOnly,
  }) {
    final filters = <String>[];

    if (genres != null && genres.isNotEmpty) {
      filters.add('${genres.length} genre${genres.length > 1 ? 's' : ''}');
    }

    if (minYear != null || maxYear != null) {
      if (minYear != null && maxYear != null) {
        filters.add('$minYear-$maxYear');
      } else if (minYear != null) {
        filters.add('$minYear+');
      } else if (maxYear != null) {
        filters.add('Up to $maxYear');
      }
    }

    if (minRating != null || maxRating != null) {
      if (minRating != null && maxRating != null) {
        filters.add('${minRating.toStringAsFixed(1)}-${maxRating.toStringAsFixed(1)} stars');
      } else if (minRating != null) {
        filters.add('${minRating.toStringAsFixed(1)}+ stars');
      } else if (maxRating != null) {
        filters.add('Up to ${maxRating.toStringAsFixed(1)} stars');
      }
    }

    if (languages != null && languages.isNotEmpty) {
      filters.add('${languages.length} language${languages.length > 1 ? 's' : ''}');
    }

    if (includeAdult != null) {
      filters.add(includeAdult ? 'Adult content' : 'Family friendly');
    }

    if (availableOnly == true) {
      filters.add('Availability filter unavailable');
    }

    return filters.isEmpty ? 'All movies' : filters.join(', ');
  }

  /// Resets all filters
  Map<String, dynamic> getDefaultFilters() {
    return {
      'genres': <int>[],
      'minYear': null,
      'maxYear': null,
      'minRating': null,
      'maxRating': null,
      'minRuntime': null,
      'maxRuntime': null,
      'languages': <String>[],
      'includeAdult': null,
      'availableOnly': false,
      'sortBy': 'relevance',
      'ascending': false,
    };
  }

  /// Validates filter parameters
  bool validateFilters(Map<String, dynamic> filters) {
    // Check year range
    final minYear = filters['minYear'] as int?;
    final maxYear = filters['maxYear'] as int?;
    if (minYear != null && maxYear != null && minYear > maxYear) {
      return false;
    }

    // Check rating range
    final minRating = filters['minRating'] as double?;
    final maxRating = filters['maxRating'] as double?;
    if (minRating != null && maxRating != null && minRating > maxRating) {
      return false;
    }

    // Check runtime range
    final minRuntime = filters['minRuntime'] as int?;
    final maxRuntime = filters['maxRuntime'] as int?;
    if (minRuntime != null && maxRuntime != null && minRuntime > maxRuntime) {
      return false;
    }

    return true;
  }
} 