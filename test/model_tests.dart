import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/video.dart';

void main() {
  group('Movie Model Tests', () {
    test('should create Movie with basic properties', () {
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Test overview',
        posterPath: '/test.jpg',
        voteAverage: 8.5,
        releaseDate: '2023-01-01',
      );

      expect(movie.id, 1);
      expect(movie.title, 'Test Movie');
      expect(movie.overview, 'Test overview');
      expect(movie.voteAverage, 8.5);
      expect(movie.year, '2023');
      expect(movie.formattedRating, '8.5');
    });

    test('should create CastMember correctly', () {
      final castMember = CastMember(
        id: 1,
        name: 'John Doe',
        character: 'Hero',
        profilePath: '/profile.jpg',
        order: 1,
      );

      expect(castMember.id, 1);
      expect(castMember.name, 'John Doe');
      expect(castMember.character, 'Hero');
      expect(castMember.profileUrl, 'https://image.tmdb.org/t/p/w185/profile.jpg');
    });

    test('should create CrewMember correctly', () {
      final crewMember = CrewMember(
        id: 1,
        name: 'Jane Smith',
        job: 'Director',
        department: 'Directing',
        profilePath: '/profile.jpg',
      );

      expect(crewMember.id, 1);
      expect(crewMember.name, 'Jane Smith');
      expect(crewMember.job, 'Director');
      expect(crewMember.department, 'Directing');
      expect(crewMember.profileUrl, 'https://image.tmdb.org/t/p/w185/profile.jpg');
    });

    test('should create Video correctly', () {
      final video = Video(
        id: 'video1',
        key: 'abc123',
        name: 'Trailer',
        site: 'YouTube',
        type: 'Trailer',
        official: 'true',
        publishedAt: '2023-01-01',
        size: 1080,
      );

      expect(video.id, 'video1');
      expect(video.key, 'abc123');
      expect(video.name, 'Trailer');
      expect(video.site, 'YouTube');
      expect(video.youtubeUrl, 'https://www.youtube.com/watch?v=abc123');
      expect(video.thumbnailUrl, 'https://img.youtube.com/vi/abc123/maxresdefault.jpg');
    });

    test('should create Movie from JSON with cast, crew, and videos', () {
      final json = {
        'id': 1,
        'title': 'Test Movie',
        'overview': 'Test overview',
        'poster_path': '/test.jpg',
        'vote_average': 8.5,
        'release_date': '2023-01-01',
        'cast': [
          {
            'id': 1,
            'name': 'John Doe',
            'character': 'Hero',
            'profile_path': '/profile.jpg',
            'order': 1,
          }
        ],
        'crew': [
          {
            'id': 1,
            'name': 'Jane Smith',
            'job': 'Director',
            'department': 'Directing',
            'profile_path': '/profile.jpg',
          }
        ],
        'videos': {
          'results': [
            {
              'id': 'video1',
              'key': 'abc123',
              'name': 'Trailer',
              'site': 'YouTube',
              'type': 'Trailer',
              'official': 'true',
              'published_at': '2023-01-01',
              'size': 1080,
            }
          ]
        },
      };

      final movie = Movie.fromJson(json);

      expect(movie.id, 1);
      expect(movie.title, 'Test Movie');
      expect(movie.cast, isNotNull);
      expect(movie.cast!.length, 1);
      expect(movie.cast!.first.name, 'John Doe');
      expect(movie.crew, isNotNull);
      expect(movie.crew!.length, 1);
      expect(movie.crew!.first.name, 'Jane Smith');
      expect(movie.videos, isNotNull);
      expect(movie.videos!.length, 1);
      expect(movie.videos!.first.name, 'Trailer');
    });

    test('should convert Movie to JSON correctly', () {
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Test overview',
        posterPath: '/test.jpg',
        voteAverage: 8.5,
        releaseDate: '2023-01-01',
        cast: [
          CastMember(
            id: 1,
            name: 'John Doe',
            character: 'Hero',
            profilePath: '/profile.jpg',
            order: 1,
          )
        ],
        crew: [
          CrewMember(
            id: 1,
            name: 'Jane Smith',
            job: 'Director',
            department: 'Directing',
            profilePath: '/profile.jpg',
          )
        ],
        videos: [
          Video(
            id: 'video1',
            key: 'abc123',
            name: 'Trailer',
            site: 'YouTube',
            type: 'Trailer',
          )
        ],
      );

      final json = movie.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Test Movie');
      expect(json['cast'], isNotNull);
      expect(json['crew'], isNotNull);
      expect(json['videos'], isNotNull);
    });

    test('should create Movie copy with new properties', () {
      final original = Movie(
        id: 1,
        title: 'Original Movie',
        overview: 'Original overview',
        voteAverage: 8.0,
      );

      final copy = original.copyWith(
        title: 'Updated Movie',
        voteAverage: 9.0,
      );

      expect(copy.id, 1);
      expect(copy.title, 'Updated Movie');
      expect(copy.overview, 'Original overview');
      expect(copy.voteAverage, 9.0);
    });
  });
} 