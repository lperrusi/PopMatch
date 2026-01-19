import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/video.dart';

void main() {
  group('PopMatch Model Tests', () {
    test('Movie model should create correctly', () {
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

    test('CastMember model should create correctly', () {
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

    test('CrewMember model should create correctly', () {
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

    test('Video model should create correctly', () {
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
  });
} 