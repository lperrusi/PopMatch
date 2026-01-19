import 'streaming_platform.dart';
import 'video.dart';
import 'movie.dart'; // For CastMember, CrewMember

/// TV Show model representing a TV show from TMDB API
class TvShow {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? firstAirDate;
  final List<int>? genreIds;
  final List<String>? genres;
  final bool? isAdult;
  final String? originalLanguage;
  final String? originalName;
  final double? popularity;
  final String? mediaType;
  double? weight; // For recommendation ranking - made mutable
  final double? rating; // User rating
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<CastMember>? cast;
  final List<CrewMember>? crew;
  final List<Video>? videos;
  final MovieStreamingAvailability? streamingAvailability;

  TvShow({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.firstAirDate,
    this.genreIds,
    this.genres,
    this.isAdult,
    this.originalLanguage,
    this.originalName,
    this.popularity,
    this.mediaType,
    this.weight,
    this.rating,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.cast,
    this.crew,
    this.videos,
    this.streamingAvailability,
  });

  /// Creates a TvShow instance from JSON data
  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: json['vote_average']?.toDouble(),
      voteCount: json['vote_count'],
      firstAirDate: json['first_air_date'],
      genreIds: json['genre_ids'] != null 
          ? List<int>.from(json['genre_ids'])
          : null,
      genres: json['genres'] != null 
          ? List<String>.from(json['genres'].map((g) => g['name']))
          : null,
      isAdult: json['adult'],
      originalLanguage: json['original_language'],
      originalName: json['original_name'],
      popularity: json['popularity']?.toDouble(),
      mediaType: json['media_type'] ?? 'tv',
      weight: json['weight']?.toDouble(),
      rating: json['rating']?.toDouble(),
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      cast: json['cast'] != null 
          ? List<CastMember>.from(json['cast'].map((c) => CastMember.fromJson(c)))
          : null,
      crew: json['crew'] != null 
          ? List<CrewMember>.from(json['crew'].map((c) => CrewMember.fromJson(c)))
          : null,
      videos: json['videos'] != null 
          ? List<Video>.from(json['videos']['results'].map((v) => Video.fromJson(v)))
          : null,
      streamingAvailability: json['streamingAvailability'] != null 
          ? MovieStreamingAvailability.fromJson(json['streamingAvailability'])
          : null,
    );
  }

  /// Converts TvShow instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'first_air_date': firstAirDate,
      'genre_ids': genreIds,
      'genres': genres,
      'adult': isAdult,
      'original_language': originalLanguage,
      'original_name': originalName,
      'popularity': popularity,
      'media_type': mediaType ?? 'tv',
      'weight': weight,
      'rating': rating,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
      'cast': cast?.map((c) => c.toJson()).toList(),
      'crew': crew?.map((c) => c.toJson()).toList(),
      'videos': videos?.map((v) => v.toJson()).toList(),
      'streamingAvailability': streamingAvailability?.toJson(),
    };
  }

  /// Gets the full poster URL
  String? get posterUrl {
    if (posterPath == null) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Gets the full backdrop URL
  String? get backdropUrl {
    if (backdropPath == null) return null;
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }

  /// Gets the year from first air date
  String? get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return null;
    return firstAirDate!.split('-')[0];
  }

  /// Gets formatted rating
  String get formattedRating {
    if (voteAverage == null) return 'N/A';
    return voteAverage!.toStringAsFixed(1);
  }

  /// Gets display title (alias for name to match Movie interface)
  String get title => name;

  /// Gets release date (alias for firstAirDate to match Movie interface)
  String? get releaseDate => firstAirDate;

  @override
  String toString() {
    return 'TvShow(id: $id, name: $name, rating: $voteAverage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvShow && other.id == id;
  }

  /// Creates a copy of this TvShow with the given fields replaced by new values
  TvShow copyWith({
    int? id,
    String? name,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? firstAirDate,
    List<int>? genreIds,
    List<String>? genres,
    bool? isAdult,
    String? originalLanguage,
    String? originalName,
    double? popularity,
    String? mediaType,
    double? weight,
    double? rating,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    List<CastMember>? cast,
    List<CrewMember>? crew,
    List<Video>? videos,
    MovieStreamingAvailability? streamingAvailability,
  }) {
    return TvShow(
      id: id ?? this.id,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount ?? this.voteCount,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      genreIds: genreIds ?? this.genreIds,
      genres: genres ?? this.genres,
      isAdult: isAdult ?? this.isAdult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      originalName: originalName ?? this.originalName,
      popularity: popularity ?? this.popularity,
      mediaType: mediaType ?? this.mediaType,
      weight: weight ?? this.weight,
      rating: rating ?? this.rating,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      videos: videos ?? this.videos,
      streamingAvailability: streamingAvailability ?? this.streamingAvailability,
    );
  }

  @override
  int get hashCode => id.hashCode;
}
