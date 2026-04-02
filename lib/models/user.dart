/// User model for Firebase authentication and user data
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> watchlist;
  final List<String>? watchlistShows;
  final List<String> likedMovies;
  final List<String> dislikedMovies;
  final List<String> likedShows;
  final List<String> dislikedShows;
  final String? currentMood;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.watchlist = const [],
    this.watchlistShows,
    this.likedMovies = const [],
    this.dislikedMovies = const [],
    this.likedShows = const [],
    this.dislikedShows = const [],
    this.currentMood,
    this.preferences = const {},
  });

  /// Safe list for watchlist shows (never null for callers).
  List<String> get watchlistShowsOrEmpty => watchlistShows ?? [];

  /// Creates a User instance from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      watchlist: json['watchlist'] != null 
          ? List<String>.from(json['watchlist'])
          : [],
      watchlistShows: json['watchlistShows'] != null 
          ? List<String>.from(json['watchlistShows'])
          : null,
      likedMovies: json['likedMovies'] != null 
          ? List<String>.from(json['likedMovies'])
          : [],
      dislikedMovies: json['dislikedMovies'] != null 
          ? List<String>.from(json['dislikedMovies'])
          : [],
      likedShows: json['likedShows'] != null 
          ? List<String>.from(json['likedShows'])
          : [],
      dislikedShows: json['dislikedShows'] != null 
          ? List<String>.from(json['dislikedShows'])
          : [],
      currentMood: json['currentMood'],
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : {},
    );
  }

  /// Converts User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'watchlist': watchlist,
      'watchlistShows': watchlistShows ?? [],
      'likedMovies': likedMovies,
      'dislikedMovies': dislikedMovies,
      'likedShows': likedShows,
      'dislikedShows': dislikedShows,
      'currentMood': currentMood,
      'preferences': preferences,
    };
  }

  /// Creates a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    List<String>? watchlist,
    List<String>? watchlistShows,
    List<String>? likedMovies,
    List<String>? dislikedMovies,
    List<String>? likedShows,
    List<String>? dislikedShows,
    String? currentMood,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      watchlist: watchlist ?? this.watchlist,
      watchlistShows: watchlistShows ?? this.watchlistShows,
      likedMovies: likedMovies ?? this.likedMovies,
      dislikedMovies: dislikedMovies ?? this.dislikedMovies,
      likedShows: likedShows ?? this.likedShows,
      dislikedShows: dislikedShows ?? this.dislikedShows,
      currentMood: currentMood ?? this.currentMood,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Adds a movie to watchlist
  User addToWatchlist(String movieId) {
    if (!watchlist.contains(movieId)) {
      return copyWith(watchlist: [...watchlist, movieId]);
    }
    return this;
  }

  /// Removes a movie from watchlist
  User removeFromWatchlist(String movieId) {
    return copyWith(watchlist: watchlist.where((id) => id != movieId).toList());
  }

  /// Adds a show to watchlist
  User addShowToWatchlist(String showId) {
    final list = watchlistShowsOrEmpty;
    if (!list.contains(showId)) {
      return copyWith(watchlistShows: [...list, showId]);
    }
    return this;
  }

  /// Removes a show from watchlist
  User removeFromWatchlistShow(String showId) {
    return copyWith(
      watchlistShows: watchlistShowsOrEmpty.where((id) => id != showId).toList(),
    );
  }

  /// Adds a movie to liked movies
  User addLikedMovie(String movieId) {
    if (!likedMovies.contains(movieId)) {
      return copyWith(likedMovies: [...likedMovies, movieId]);
    }
    return this;
  }

  /// Removes a movie from liked movies
  User removeLikedMovie(String movieId) {
    return copyWith(likedMovies: likedMovies.where((id) => id != movieId).toList());
  }

  /// Adds a movie to disliked movies
  User addDislikedMovie(String movieId) {
    if (!dislikedMovies.contains(movieId)) {
      return copyWith(dislikedMovies: [...dislikedMovies, movieId]);
    }
    return this;
  }

  /// Removes a movie from disliked movies
  User removeDislikedMovie(String movieId) {
    return copyWith(dislikedMovies: dislikedMovies.where((id) => id != movieId).toList());
  }

  /// Adds a show to liked shows
  User addLikedShow(String showId) {
    if (!likedShows.contains(showId)) {
      return copyWith(likedShows: [...likedShows, showId]);
    }
    return this;
  }

  /// Removes a show from liked shows
  User removeLikedShow(String showId) {
    return copyWith(likedShows: likedShows.where((id) => id != showId).toList());
  }

  /// Adds a show to disliked shows
  User addDislikedShow(String showId) {
    if (!dislikedShows.contains(showId)) {
      return copyWith(dislikedShows: [...dislikedShows, showId]);
    }
    return this;
  }

  /// Removes a show from disliked shows
  User removeDislikedShow(String showId) {
    return copyWith(dislikedShows: dislikedShows.where((id) => id != showId).toList());
  }

  /// Updates user preferences
  User updatePreferences(Map<String, dynamic> newPreferences) {
    return copyWith(preferences: {...preferences, ...newPreferences});
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, watchlist: ${watchlist.length} movies, ${watchlistShowsOrEmpty.length} shows)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 