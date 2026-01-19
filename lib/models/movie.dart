import 'streaming_platform.dart';
import 'video.dart';

/// Cast member model
class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int? order;

  CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'],
      profilePath: json['profile_path'],
      order: json['order'],
    );
  }

  String? get profileUrl {
    if (profilePath == null) return null;
    return 'https://image.tmdb.org/t/p/w185$profilePath';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character': character,
      'profile_path': profilePath,
      'order': order,
    };
  }
}

/// Crew member model
class CrewMember {
  final int id;
  final String name;
  final String? job;
  final String? department;
  final String? profilePath;

  CrewMember({
    required this.id,
    required this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }

  String? get profileUrl {
    if (profilePath == null) return null;
    return 'https://image.tmdb.org/t/p/w185$profilePath';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'job': job,
      'department': department,
      'profile_path': profilePath,
    };
  }
}

/// Movie model representing a movie from TMDB API
class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? releaseDate;
  final List<int>? genreIds;
  final List<String>? genres;
  final bool? isAdult;
  final String? originalLanguage;
  final String? originalTitle;
  final double? popularity;
  final bool? video;
  final String? mediaType;
  double? weight; // For recommendation ranking - made mutable
  final double? rating; // User rating
  final int? runtime; // Movie runtime in minutes
  final List<CastMember>? cast;
  final List<CrewMember>? crew;
  final List<Video>? videos;
  final MovieStreamingAvailability? streamingAvailability;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.releaseDate,
    this.genreIds,
    this.genres,
    this.isAdult,
    this.originalLanguage,
    this.originalTitle,
    this.popularity,
    this.video,
    this.mediaType,
    this.weight,
    this.rating,
    this.runtime,
    this.cast,
    this.crew,
    this.videos,
    this.streamingAvailability,
  });

  /// Creates a Movie instance from JSON data
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: json['vote_average']?.toDouble(),
      voteCount: json['vote_count'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: json['genre_ids'] != null 
          ? List<int>.from(json['genre_ids'])
          : null,
      genres: json['genres'] != null 
          ? List<String>.from(json['genres'].map((g) => g['name']))
          : null,
      isAdult: json['adult'],
      originalLanguage: json['original_language'],
      originalTitle: json['original_title'] ?? json['original_name'],
      popularity: json['popularity']?.toDouble(),
      video: json['video'],
      mediaType: json['media_type'],
      weight: json['weight']?.toDouble(),
      rating: json['rating']?.toDouble(),
      runtime: json['runtime'],
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

  /// Converts Movie instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'genres': genres,
      'adult': isAdult,
      'original_language': originalLanguage,
      'original_title': originalTitle,
      'popularity': popularity,
      'video': video,
      'media_type': mediaType,
      'weight': weight,
      'rating': rating,
      'runtime': runtime,
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

  /// Gets the year from release date
  String? get year {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    return releaseDate!.split('-')[0];
  }

  /// Gets formatted rating
  String get formattedRating {
    if (voteAverage == null) return 'N/A';
    return voteAverage!.toStringAsFixed(1);
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, rating: $voteAverage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.id == id;
  }

  /// Creates a copy of this Movie with the given fields replaced by new values
  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<int>? genreIds,
    List<String>? genres,
    bool? isAdult,
    String? originalLanguage,
    String? originalTitle,
    double? popularity,
    bool? video,
    String? mediaType,
    double? weight,
    double? rating,
    int? runtime,
    List<CastMember>? cast,
    List<CrewMember>? crew,
    List<Video>? videos,
    MovieStreamingAvailability? streamingAvailability,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      genres: genres ?? this.genres,
      isAdult: isAdult ?? this.isAdult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      originalTitle: originalTitle ?? this.originalTitle,
      popularity: popularity ?? this.popularity,
      video: video ?? this.video,
      mediaType: mediaType ?? this.mediaType,
      weight: weight ?? this.weight,
      rating: rating ?? this.rating,
      runtime: runtime ?? this.runtime,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      videos: videos ?? this.videos,
      streamingAvailability: streamingAvailability ?? this.streamingAvailability,
    );
  }

  @override
  int get hashCode => id.hashCode;
} 