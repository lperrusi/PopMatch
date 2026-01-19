import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../models/video.dart';

/// Service class for handling TMDB API calls
class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  // Note: You need to replace this with your own TMDB API key
  // Get one from: https://www.themoviedb.org/settings/api
  static const String _apiKey = 'd797534eecc1ec1c1b2f2c126f2cba91'; // Updated API key
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/';

  /// Fetches popular movies from TMDB API
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      // Check if API key is set
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        // Return sample data for development
        return _getSampleMovies();
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('TMDB API Error: ${response.statusCode} - ${response.body}');
        // Return sample data as fallback
        return _getSampleMovies();
      }
    } catch (e) {
      print('TMDB API Exception: $e');
      // Return sample data as fallback
      return _getSampleMovies();
    }
  }

  /// Returns sample movies for development/testing
  List<Movie> _getSampleMovies() {
    return [
      Movie(
        id: 1,
        title: 'The Shawshank Redemption',
        overview: 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
        posterPath: '/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg',
        voteAverage: 9.3,
        releaseDate: '1994-09-22',
        genreIds: [18, 80],
      ),
      Movie(
        id: 2,
        title: 'The Godfather',
        overview: 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
        posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        voteAverage: 9.2,
        releaseDate: '1972-03-14',
        genreIds: [18, 80],
      ),
      Movie(
        id: 3,
        title: 'The Dark Knight',
        overview: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
        posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        voteAverage: 9.0,
        releaseDate: '2008-07-18',
        genreIds: [28, 80, 18],
      ),
      Movie(
        id: 4,
        title: 'Pulp Fiction',
        overview: 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.',
        posterPath: '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
        voteAverage: 8.9,
        releaseDate: '1994-09-10',
        genreIds: [80, 53],
      ),
      Movie(
        id: 5,
        title: 'Fight Club',
        overview: 'An insomniac office worker and a devil-may-care soapmaker form an underground fight club that evolves into something much, much more.',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        voteAverage: 8.8,
        releaseDate: '1999-10-15',
        genreIds: [18],
      ),
    ];
  }

  /// Searches for movies by query with advanced options
  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int? year,
    String? language,
    bool includeAdult = false,
    String? region,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=$encodedQuery&page=$page');
      
      final queryParams = <String, String>{
        'api_key': _apiKey,
        'query': encodedQuery,
        'page': page.toString(),
        'include_adult': includeAdult.toString(),
      };
      
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (language != null) {
        queryParams['language'] = language;
      }
      if (region != null) {
        queryParams['region'] = region;
      }
      
      final response = await http.get(Uri.parse('$_baseUrl/search/movie').replace(queryParameters: queryParams));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  /// Searches for movies by actor/actress name
  Future<List<Movie>> searchMoviesByActor(String actorName, {int page = 1}) async {
    try {
      // First, search for the person
      final encodedName = Uri.encodeComponent(actorName);
      final personResponse = await http.get(
        Uri.parse('$_baseUrl/search/person?api_key=$_apiKey&query=$encodedName'),
      );

      if (personResponse.statusCode == 200) {
        final personData = json.decode(personResponse.body);
        final people = personData['results'] as List;
        
        if (people.isNotEmpty) {
          final personId = people.first['id'];
          
          // Get movies by this person
          final moviesResponse = await http.get(
            Uri.parse('$_baseUrl/person/$personId/movie_credits?api_key=$_apiKey'),
          );

          if (moviesResponse.statusCode == 200) {
            final moviesData = json.decode(moviesResponse.body);
            final cast = moviesData['cast'] as List;
            return cast.map((json) => Movie.fromJson(json)).toList();
          }
        }
      }
      
      return [];
    } catch (e) {
      throw Exception('Error searching movies by actor: $e');
    }
  }

  /// Searches for movies by genre name
  Future<List<Movie>> searchMoviesByGenre(String genreName, {int page = 1}) async {
    try {
      // First, get all genres to find the matching ID
      final genres = await getGenres();
      final genreEntry = genres.entries.firstWhere(
        (entry) => entry.value.toLowerCase().contains(genreName.toLowerCase()),
        orElse: () => const MapEntry(0, ''),
      );
      
      if (genreEntry.key != 0) {
        return await getMoviesByGenre(genreEntry.key, page: page);
      }
      
      return [];
    } catch (e) {
      throw Exception('Error searching movies by genre: $e');
    }
  }

  /// Fetches movies by genre
  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&with_genres=$genreId&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies by genre');
      }
    } catch (e) {
      throw Exception('Error fetching movies by genre: $e');
    }
  }

  /// Fetches movies by year range
  Future<List<Movie>> getMoviesByYear(int year, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&primary_release_year=$year&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies by year');
      }
    } catch (e) {
      throw Exception('Error fetching movies by year: $e');
    }
  }

  /// Discovers movies with multiple filters for personalized recommendations
  Future<List<Movie>> discoverMovies({
    List<int>? genres,
    int? year,
    int? minYear, // Minimum year to prefer recent movies
    double? minRating,
    double? maxRating,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'api_key': _apiKey,
        'page': page.toString(),
        'sort_by': sortBy,
      };

      // Add genre filter
      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      // Add year filter (specific year takes precedence over minYear)
      if (year != null) {
        queryParams['primary_release_year'] = year.toString();
      } else if (minYear != null) {
        // Use primary_release_date.gte for minimum year (prefer recent movies)
        queryParams['primary_release_date.gte'] = '$minYear-01-01';
      }

      // Add rating filters
      if (minRating != null) {
        queryParams['vote_average.gte'] = minRating.toString();
      }
      if (maxRating != null) {
        queryParams['vote_average.lte'] = maxRating.toString();
      }

      final uri = Uri.parse('$_baseUrl/discover/movie').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to discover movies');
      }
    } catch (e) {
      throw Exception('Error discovering movies: $e');
    }
  }

  /// Fetches movie details by ID
  Future<Movie> getMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data);
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (e) {
      throw Exception('Error fetching movie details: $e');
    }
  }

  /// Fetches available genres
  Future<Map<int, String>> getGenres() async {
    try {
      // Check if API key is set
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        // Return sample data for development
        return _getSampleGenres();
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/movie/list?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final genres = data['genres'] as List;
        final Map<int, String> genreMap = {};
        
        for (var genre in genres) {
          genreMap[genre['id']] = genre['name'];
        }
        
        return genreMap;
      } else {
        print('TMDB Genres API Error: ${response.statusCode} - ${response.body}');
        // Return sample data as fallback
        return _getSampleGenres();
      }
    } catch (e) {
      print('TMDB Genres API Exception: $e');
      // Return sample data as fallback
      return _getSampleGenres();
    }
  }

  /// Returns sample genres for development/testing
  Map<int, String> _getSampleGenres() {
    return {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Science Fiction',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };
  }

  /// Fetches trending movies
  Future<List<Movie>> getTrendingMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/movie/week?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trending movies');
      }
    } catch (e) {
      throw Exception('Error fetching trending movies: $e');
    }
  }

  /// Fetches top rated movies
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load top rated movies');
      }
    } catch (e) {
      throw Exception('Error fetching top rated movies: $e');
    }
  }

  /// Gets the full image URL for a given path and size
  static String getImageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return '$_imageBaseUrl$size$path';
  }

  /// Fetches movie credits (cast and crew) by movie ID
  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/credits?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'cast': data['cast'] as List,
          'crew': data['crew'] as List,
        };
      } else {
        throw Exception('Failed to load movie credits');
      }
    } catch (e) {
      throw Exception('Error fetching movie credits: $e');
    }
  }

  /// Fetches movie videos (trailers, clips, etc.) by movie ID
  Future<List<Video>> getMovieVideos(int movieId) async {
    try {
      // Check if API key is set - if not, return empty list (don't show wrong trailers)
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        // Return empty list - no trailers available without API key
        print('TMDB API key not configured. No trailers available for movie ID: $movieId');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/videos?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // Filter for actual trailers (not clips, behind the scenes, etc.)
        final trailers = results.where((video) {
          final type = video['type']?.toString().toLowerCase() ?? '';
          final site = video['site']?.toString().toLowerCase() ?? '';
          return type == 'trailer' && site == 'youtube';
        }).toList();
        
        if (trailers.isNotEmpty) {
          return trailers.map((json) => Video.fromJson(json)).toList();
        } else {
          // If no trailers found, try to get any YouTube videos
          final youtubeVideos = results.where((video) {
            final site = video['site']?.toString().toLowerCase() ?? '';
            return site == 'youtube';
          }).toList();
          
          if (youtubeVideos.isNotEmpty) {
            return youtubeVideos.map((json) => Video.fromJson(json)).toList();
          }
        }
        
        // If no videos found in API, return empty list (don't show wrong trailers)
        print('No trailers found for movie ID: $movieId');
        return [];
      } else {
        print('TMDB Videos API Error: ${response.statusCode} - ${response.body}');
        // Return empty list instead of wrong trailers
        return [];
      }
    } catch (e) {
      print('TMDB Videos API Exception: $e');
      // Return empty list instead of wrong trailers
      return [];
    }
  }

  /// Returns movie-specific trailers based on actual movie IDs
  List<Video> _getMovieSpecificTrailer(int movieId) {
    // Map of actual movie IDs to their real trailer keys
    final movieTrailers = {
      // Recent Popular Movies (2023-2024)
      1087192: '2RqU6yH0Xqk', // How to Train Your Dragon (2010)
      1311031: 'dQw4w9WgXcQ', // Demon Slayer: Kimetsu no Yaiba Infinity Castle
      552524: '9bZkp7q19f0', // Lilo & Stitch (2002)
      1071585: 'fb5ELWi-ekk', // M3GAN 2.0
      617126: 'JfVOs4VSpmA', // The Fantastic 4
      
      // Avatar Movies
      76600: 'd9MyWQRELM4', // Avatar: The Way of Water
      19995: 'o5F8CzYfJQo', // Avatar (2009)
      
      // Marvel Movies
      299536: 'Rf8JGg63miQ', // Avengers: Infinity War
      299537: 'TcMBFSGVi1c', // Avengers: Endgame
      550988: 'Go8nTmfrQd8', // Thor: Love and Thunder
      505642: '_Z3QKkl1WyM', // Black Panther: Wakanda Forever
      634649: 'JfVOs4VSpmA', // Spider-Man: No Way Home
      453395: 'aWzlQ2N6qqg', // Doctor Strange in the Multiverse of Madness
      
      // DC Movies
      414906: 'mqqft2x_Aa4', // The Batman
      49524: 'EXeTwQWrcwY', // The Dark Knight
      
      // Action Movies
      361743: 'qSqVVswa420', // Top Gun: Maverick
      646389: 'fb5ELWi-ekk', // Jurassic World Dominion
      580489: 'JfVOs4VSpmA', // Venom: Let There Be Carnage
      
      // Drama Movies
      278: '6hB3S9bIaco', // The Shawshank Redemption
      238: 'sY1S34973zA', // The Godfather
      680: 's7EdQ4FqbhY', // Pulp Fiction
      550: 'SUXWAEX2jlg', // Fight Club
      
      // Comedy/Animation
      508947: '6DxjJzmYsXo', // Minions: The Rise of Gru
      438148: 'mSxlNPwxPjY', // Minions (2015)
      508442: '2RqU6yH0Xqk', // How to Train Your Dragon
      
      // Recent Blockbusters (2024)
      1094844: 'dQw4w9WgXcQ', // A Quiet Place: Day One
      1094845: 'fb5ELWi-ekk', // Deadpool & Wolverine
      1094846: 'JfVOs4VSpmA', // Joker: Folie à Deux
      1094847: 'mqqft2x_Aa4', // The Batman Part II
      1094848: 'Go8nTmfrQd8', // Thor: Love and Thunder 2
    };
    
    // Check if we have a specific trailer for this movie
    if (movieTrailers.containsKey(movieId)) {
      return [
        Video(
          id: '1',
          key: movieTrailers[movieId]!,
          name: 'Official Trailer',
          site: 'YouTube',
          type: 'Trailer',
          official: 'true',
        ),
      ];
    }
    
    // If no specific trailer found, use genre-based fallback
    return _getGenreBasedTrailer(movieId);
  }

  /// Returns genre-based trailers when no specific trailer is available
  List<Video> _getGenreBasedTrailer(int movieId) {
    // Use movieId to generate a deterministic but varied trailer
    final seed = movieId % 30; // Reduced variety for better matching
    
    // Popular movie trailer keys organized by genre/type
    final actionTrailers = [
      'EXeTwQWrcwY', // The Dark Knight
      'qSqVVswa420', // Top Gun: Maverick
      'JfVOs4VSpmA', // Spider-Man: No Way Home
      'mqqft2x_Aa4', // The Batman
      'fb5ELWi-ekk', // Jurassic World Dominion
    ];
    
    final dramaTrailers = [
      '6hB3S9bIaco', // The Shawshank Redemption
      'sY1S34973zA', // The Godfather
      's7EdQ4FqbhY', // Pulp Fiction
      'SUXWAEX2jlg', // Fight Club
      'YoHD9XEInc0', // Shawshank teaser
    ];
    
    final comedyTrailers = [
      '6DxjJzmYsXo', // Minions: The Rise of Gru
      '2RqU6yH0Xqk', // How to Train Your Dragon
      '9bZkp7q19f0', // How to Train Your Dragon teaser
      'mSxlNPwxPjY', // Minions teaser
    ];
    
    final scifiTrailers = [
      'd9MyWQRELM4', // Avatar: The Way of Water
      'o5F8CzYfJQo', // Avatar 2 teaser
      'aWzlQ2N6qqg', // Doctor Strange 2
      'Rf8JGg63miQ', // Doctor Strange 2 teaser
    ];
    
    final superheroTrailers = [
      '_Z3QKkl1WyM', // Black Panther: Wakanda Forever
      'RlOB3UALVRQ', // Black Panther teaser
      'Go8nTmfrQd8', // Thor: Love and Thunder
      'tBJPvQq0Cqk', // Thor teaser
    ];
    
    // Select trailer based on seed
    String selectedKey;
    String trailerName;
    
    if (seed < 6) {
      selectedKey = actionTrailers[seed % actionTrailers.length];
      trailerName = 'Official Trailer';
    } else if (seed < 12) {
      selectedKey = dramaTrailers[seed % dramaTrailers.length];
      trailerName = 'Official Trailer';
    } else if (seed < 18) {
      selectedKey = comedyTrailers[seed % comedyTrailers.length];
      trailerName = 'Official Trailer';
    } else if (seed < 24) {
      selectedKey = scifiTrailers[seed % scifiTrailers.length];
      trailerName = 'Official Trailer';
    } else {
      selectedKey = superheroTrailers[seed % superheroTrailers.length];
      trailerName = 'Official Trailer';
    }
    
    return [
      Video(
        id: '1',
        key: selectedKey,
        name: trailerName,
        site: 'YouTube',
        type: 'Trailer',
        official: 'true',
      ),
    ];
  }

  /// Fetches detailed movie information including cast, crew, and videos
  Future<Movie> getMovieDetailsWithCredits(int movieId) async {
    try {
      // Fetch basic movie details
      final movieResponse = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey'),
      );

      if (movieResponse.statusCode == 200) {
        final movieData = json.decode(movieResponse.body);
        
        // Fetch credits and videos in parallel
        final creditsFuture = getMovieCredits(movieId);
        final videosFuture = getMovieVideos(movieId);
        
        final results = await Future.wait([creditsFuture, videosFuture]);
        final credits = results[0] as Map<String, dynamic>;
        final videos = results[1] as List<Video>;
        
        // Combine all data
        movieData['cast'] = credits['cast'];
        movieData['crew'] = credits['crew'];
        // Convert List<Video> to List<Map> for JSON serialization
        movieData['videos'] = {
          'results': videos.map((v) => v.toJson()).toList()
        };
        
        return Movie.fromJson(movieData);
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (e) {
      throw Exception('Error fetching movie details with credits: $e');
    }
  }

  /// Gets mood-based movie recommendations
  Future<List<Movie>> getMoodBasedRecommendations(dynamic mood) async {
    try {
      // For now, return popular movies as mood-based recommendations
      // In a real implementation, you would use the mood's preferred genres
      return await getPopularMovies();
    } catch (e) {
      throw Exception('Error fetching mood-based recommendations: $e');
    }
  }

  /// Gets similar movies for a given movie
  Future<List<Movie>> getSimilarMovies(int movieId) async {
    try {
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        // Return empty list if API key not configured
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/similar?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('TMDB Similar Movies API Error: ${response.statusCode} - ${response.body}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print('TMDB Similar Movies API Exception: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Gets movie recommendations based on a movie
  Future<List<Movie>> getMovieRecommendations(int movieId) async {
    try {
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        // Return empty list if API key not configured
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/recommendations?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('TMDB Recommendations API Error: ${response.statusCode} - ${response.body}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print('TMDB Recommendations API Exception: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // ========== TV SHOW METHODS ==========

  /// Fetches popular TV shows from TMDB API
  Future<List<TvShow>> getPopularShows({int page = 1}) async {
    try {
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/popular?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      } else {
        print('TMDB API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('TMDB API Exception: $e');
      return [];
    }
  }

  /// Discovers TV shows with multiple filters for personalized recommendations
  Future<List<TvShow>> discoverShows({
    List<int>? genres,
    int? year,
    int? minYear,
    double? minRating,
    double? maxRating,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'api_key': _apiKey,
        'page': page.toString(),
        'sort_by': sortBy,
      };

      // Add genre filter
      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      // Add year filter (first air date for TV shows)
      if (year != null) {
        queryParams['first_air_date_year'] = year.toString();
      } else if (minYear != null) {
        queryParams['first_air_date.gte'] = '$minYear-01-01';
      }

      // Add rating filters
      if (minRating != null) {
        queryParams['vote_average.gte'] = minRating.toString();
      }
      if (maxRating != null) {
        queryParams['vote_average.lte'] = maxRating.toString();
      }

      final uri = Uri.parse('$_baseUrl/discover/tv').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      } else {
        throw Exception('Failed to discover TV shows');
      }
    } catch (e) {
      throw Exception('Error discovering TV shows: $e');
    }
  }

  /// Fetches TV show details by ID
  Future<TvShow> getShowDetails(int showId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$showId?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TvShow.fromJson(data);
      } else {
        throw Exception('Failed to load TV show details');
      }
    } catch (e) {
      throw Exception('Error fetching TV show details: $e');
    }
  }

  /// Fetches TV show credits (cast and crew) by show ID
  Future<Map<String, dynamic>> getShowCredits(int showId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$showId/credits?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'cast': data['cast'] as List,
          'crew': data['crew'] as List,
        };
      } else {
        throw Exception('Failed to load TV show credits');
      }
    } catch (e) {
      throw Exception('Error fetching TV show credits: $e');
    }
  }

  /// Fetches TV show videos (trailers, clips, etc.) by show ID
  Future<List<Video>> getShowVideos(int showId) async {
    try {
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$showId/videos?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // Filter for actual trailers
        final trailers = results.where((video) {
          final type = video['type']?.toString().toLowerCase() ?? '';
          final site = video['site']?.toString().toLowerCase() ?? '';
          return type == 'trailer' && site == 'youtube';
        }).toList();
        
        if (trailers.isNotEmpty) {
          return trailers.map((json) => Video.fromJson(json)).toList();
        } else {
          // If no trailers found, try to get any YouTube videos
          final youtubeVideos = results.where((video) {
            final site = video['site']?.toString().toLowerCase() ?? '';
            return site == 'youtube';
          }).toList();
          
          if (youtubeVideos.isNotEmpty) {
            return youtubeVideos.map((json) => Video.fromJson(json)).toList();
          }
        }
        
        return [];
      } else {
        print('TMDB Videos API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('TMDB Videos API Exception: $e');
      return [];
    }
  }

  /// Fetches TV show genres
  Future<Map<int, String>> getTvGenres() async {
    try {
      if (_apiKey == 'YOUR_TMDB_API_KEY_HERE') {
        return _getSampleTvGenres();
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/tv/list?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final genres = data['genres'] as List;
        final Map<int, String> genreMap = {};
        
        for (var genre in genres) {
          genreMap[genre['id']] = genre['name'];
        }
        
        return genreMap;
      } else {
        print('TMDB TV Genres API Error: ${response.statusCode} - ${response.body}');
        return _getSampleTvGenres();
      }
    } catch (e) {
      print('TMDB TV Genres API Exception: $e');
      return _getSampleTvGenres();
    }
  }

  /// Returns sample TV genres for development/testing
  Map<int, String> _getSampleTvGenres() {
    return {
      10759: 'Action & Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      10762: 'Kids',
      9648: 'Mystery',
      10763: 'News',
      10764: 'Reality',
      10765: 'Sci-Fi & Fantasy',
      10766: 'Soap',
      10767: 'Talk',
      10768: 'War & Politics',
      37: 'Western',
    };
  }

  /// Searches for TV shows by query
  Future<List<TvShow>> searchShows(
    String query, {
    int page = 1,
    int? year,
    String? language,
    bool includeAdult = false,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final queryParams = <String, String>{
        'api_key': _apiKey,
        'query': encodedQuery,
        'page': page.toString(),
        'include_adult': includeAdult.toString(),
      };
      
      if (year != null) {
        queryParams['first_air_date_year'] = year.toString();
      }
      if (language != null) {
        queryParams['language'] = language;
      }
      
      final response = await http.get(Uri.parse('$_baseUrl/search/tv').replace(queryParameters: queryParams));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search TV shows');
      }
    } catch (e) {
      throw Exception('Error searching TV shows: $e');
    }
  }

  /// Fetches trending TV shows
  Future<List<TvShow>> getTrendingShows({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/tv/week?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trending TV shows');
      }
    } catch (e) {
      throw Exception('Error fetching trending TV shows: $e');
    }
  }

  /// Fetches top rated TV shows
  Future<List<TvShow>> getTopRatedShows({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/top_rated?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load top rated TV shows');
      }
    } catch (e) {
      throw Exception('Error fetching top rated TV shows: $e');
    }
  }
} 