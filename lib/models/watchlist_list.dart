// import 'movie.dart'; // Unused import

/// Model representing a custom watchlist list/collection
class WatchlistList {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final List<String> movieIds;
  final List<String> showIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  WatchlistList({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.movieIds,
    this.showIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  /// Creates a WatchlistList from JSON
  factory WatchlistList.fromJson(Map<String, dynamic> json) {
    return WatchlistList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'],
      movieIds: List<String>.from(json['movieIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isDefault: json['isDefault'] ?? false,
    );
  }

  /// Converts WatchlistList to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'movieIds': movieIds,
      'showIds': showIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Creates a copy of this WatchlistList with the given fields replaced
  WatchlistList copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    List<String>? movieIds,
    List<String>? showIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return WatchlistList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      movieIds: movieIds ?? this.movieIds,
      showIds: showIds ?? this.showIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Adds a movie to this list
  WatchlistList addMovie(String movieId) {
    if (!movieIds.contains(movieId)) {
      final newMovieIds = List<String>.from(movieIds)..add(movieId);
      return copyWith(
        movieIds: newMovieIds,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Removes a movie from this list
  WatchlistList removeMovie(String movieId) {
    if (movieIds.contains(movieId)) {
      final newMovieIds = List<String>.from(movieIds)..remove(movieId);
      return copyWith(
        movieIds: newMovieIds,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Checks if this list contains a specific movie
  bool containsMovie(String movieId) {
    return movieIds.contains(movieId);
  }

  /// Gets the number of movies in this list
  int get movieCount => movieIds.length;

  /// Gets the number of shows in this list
  int get showCount => showIds.length;

  /// Gets the total number of items (movies + shows) in this list
  int get totalCount => movieIds.length + showIds.length;

  /// Gets a display name for the list
  String get displayName {
    if (isDefault) {
      return 'All Movies & Shows';
    }
    return name;
  }

  /// Gets a display description for the list
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    return '$totalCount item${totalCount == 1 ? '' : 's'}';
  }

  /// Adds a show to this list
  WatchlistList addShow(String showId) {
    if (!showIds.contains(showId)) {
      final newShowIds = List<String>.from(showIds)..add(showId);
      return copyWith(
        showIds: newShowIds,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Removes a show from this list
  WatchlistList removeShow(String showId) {
    if (showIds.contains(showId)) {
      final newShowIds = List<String>.from(showIds)..remove(showId);
      return copyWith(
        showIds: newShowIds,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Checks if this list contains a specific show
  bool containsShow(String showId) {
    return showIds.contains(showId);
  }

  @override
  String toString() {
    return 'WatchlistList(id: $id, name: $name, movieCount: $movieCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 