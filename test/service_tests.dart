import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';

void main() {
  group('Service Tests', () {
    test('TMDB Service should handle API responses correctly', () {
      // Test movie JSON parsing
      final movieJson = {
        'id': 123,
        'title': 'Test Movie',
        'overview': 'A test movie for testing',
        'poster_path': '/test-poster.jpg',
        'backdrop_path': '/test-backdrop.jpg',
        'vote_average': 8.5,
        'vote_count': 1000,
        'release_date': '2023-01-15',
        'genre_ids': [28, 12],
        'adult': false,
        'original_language': 'en',
        'original_title': 'Test Movie',
        'popularity': 100.0,
        'video': false,
        'media_type': 'movie',
      };

      final movie = Movie.fromJson(movieJson);

      expect(movie.id, 123);
      expect(movie.title, 'Test Movie');
      expect(movie.overview, 'A test movie for testing');
      expect(movie.voteAverage, 8.5);
      expect(movie.voteCount, 1000);
      expect(movie.releaseDate, '2023-01-15');
      expect(movie.year, '2023');
      expect(movie.formattedRating, '8.5');
      expect(
          movie.posterUrl, 'https://image.tmdb.org/t/p/w500/test-poster.jpg');
      expect(movie.backdropUrl,
          'https://image.tmdb.org/t/p/original/test-backdrop.jpg');
    });

    test('Movie should handle null values correctly', () {
      final movieJson = {
        'id': 456,
        'title': 'Minimal Movie',
        // Missing optional fields
      };

      final movie = Movie.fromJson(movieJson);

      expect(movie.id, 456);
      expect(movie.title, 'Minimal Movie');
      expect(movie.overview, isNull);
      expect(movie.voteAverage, isNull);
      expect(movie.voteCount, isNull);
      expect(movie.releaseDate, isNull);
      expect(movie.year, isNull);
      expect(movie.formattedRating, 'N/A');
      expect(movie.posterUrl, isNull);
      expect(movie.backdropUrl, isNull);
    });

    test('Movie should handle cast and crew data', () {
      final movieJson = {
        'id': 789,
        'title': 'Movie with Cast',
        'cast': [
          {
            'id': 1,
            'name': 'Actor One',
            'character': 'Hero',
            'profile_path': '/actor1.jpg',
            'order': 1,
          },
          {
            'id': 2,
            'name': 'Actor Two',
            'character': 'Villain',
            'profile_path': '/actor2.jpg',
            'order': 2,
          }
        ],
        'crew': [
          {
            'id': 3,
            'name': 'Director One',
            'job': 'Director',
            'department': 'Directing',
            'profile_path': '/director1.jpg',
          }
        ],
      };

      final movie = Movie.fromJson(movieJson);

      expect(movie.cast, isNotNull);
      expect(movie.cast!.length, 2);
      expect(movie.cast!.first.name, 'Actor One');
      expect(movie.cast!.first.character, 'Hero');
      expect(movie.cast!.first.profileUrl,
          'https://image.tmdb.org/t/p/w185/actor1.jpg');

      expect(movie.crew, isNotNull);
      expect(movie.crew!.length, 1);
      expect(movie.crew!.first.name, 'Director One');
      expect(movie.crew!.first.job, 'Director');
    });

    test('Movie should handle video data', () {
      final movieJson = {
        'id': 999,
        'title': 'Movie with Videos',
        'videos': {
          'results': [
            {
              'id': 'video1',
              'key': 'abc123',
              'name': 'Official Trailer',
              'site': 'YouTube',
              'type': 'Trailer',
              'official': 'true',
              'published_at': '2023-01-01',
              'size': 1080,
            },
            {
              'id': 'video2',
              'key': 'def456',
              'name': 'Teaser',
              'site': 'YouTube',
              'type': 'Teaser',
              'official': 'false',
              'published_at': '2023-01-02',
              'size': 720,
            }
          ]
        }
      };

      final movie = Movie.fromJson(movieJson);

      expect(movie.videos, isNotNull);
      expect(movie.videos!.length, 2);
      expect(movie.videos!.first.name, 'Official Trailer');
      expect(movie.videos!.first.site, 'YouTube');
      expect(movie.videos!.first.youtubeUrl,
          'https://www.youtube.com/watch?v=abc123');
      expect(movie.videos!.first.thumbnailUrl,
          'https://img.youtube.com/vi/abc123/maxresdefault.jpg');
    });

    test('Movie toJson should work correctly', () {
      final movie = Movie(
        id: 123,
        title: 'Test Movie',
        overview: 'Test overview',
        posterPath: '/test.jpg',
        voteAverage: 8.5,
        releaseDate: '2023-01-01',
      );

      final json = movie.toJson();

      expect(json['id'], 123);
      expect(json['title'], 'Test Movie');
      expect(json['overview'], 'Test overview');
      expect(json['poster_path'], '/test.jpg');
      expect(json['vote_average'], 8.5);
      expect(json['release_date'], '2023-01-01');
    });

    test('Movie equality should work correctly', () {
      final movie1 = Movie(id: 1, title: 'Movie 1');
      final movie2 = Movie(id: 1, title: 'Movie 1');
      final movie3 = Movie(id: 2, title: 'Movie 2');

      expect(movie1, equals(movie2));
      expect(movie1, isNot(equals(movie3)));
      expect(movie1.hashCode, equals(movie2.hashCode));
    });
  });
}
