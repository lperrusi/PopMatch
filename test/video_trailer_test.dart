import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/services/tmdb_service.dart';

void main() {
  group('Video/Trailer Tests', () {
    late TMDBService tmdbService;

    setUpAll(() {
      TMDBService.setTestMode(true);
    });

    tearDownAll(() {
      TMDBService.setTestMode(false);
    });

    setUp(() {
      tmdbService = TMDBService();
    });

    test('should return sample videos for development', () async {
      // Test with a movie that should return sample videos
      final videos = await tmdbService.getMovieVideos(1);

      expect(videos, isNotEmpty);
      expect(videos.length, equals(3));

      // Check first video
      final firstVideo = videos.first;
      expect(firstVideo.name, equals('Official Trailer'));
      expect(firstVideo.type, equals('Trailer'));
      expect(firstVideo.site, equals('YouTube'));
      expect(firstVideo.official, equals('true'));

      // Check second video
      final secondVideo = videos[1];
      expect(secondVideo.name, equals('Teaser Trailer'));
      expect(secondVideo.type, equals('Teaser'));
      expect(secondVideo.site, equals('YouTube'));

      // Check third video
      final thirdVideo = videos[2];
      expect(thirdVideo.name, equals('Behind the Scenes'));
      expect(thirdVideo.type, equals('Behind the Scenes'));
      expect(thirdVideo.official, equals('false'));
    });

    test('should generate YouTube URLs correctly', () async {
      final videos = await tmdbService.getMovieVideos(1);
      final firstVideo = videos.first;

      expect(firstVideo.youtubeUrl, isNotNull);
      expect(firstVideo.youtubeUrl, contains('youtube.com/watch?v='));
      expect(firstVideo.youtubeUrl, contains('dQw4w9WgXcQ'));
    });

    test('should generate thumbnail URLs correctly', () async {
      final videos = await tmdbService.getMovieVideos(1);
      final firstVideo = videos.first;

      expect(firstVideo.thumbnailUrl, isNotNull);
      expect(firstVideo.thumbnailUrl, contains('img.youtube.com/vi/'));
      expect(firstVideo.thumbnailUrl, contains('maxresdefault.jpg'));
    });

    test('should handle different video types', () async {
      final videos = await tmdbService.getMovieVideos(1);

      final trailer = videos.firstWhere((v) => v.type == 'Trailer');
      final teaser = videos.firstWhere((v) => v.type == 'Teaser');
      final behindScenes =
          videos.firstWhere((v) => v.type == 'Behind the Scenes');

      expect(trailer, isNotNull);
      expect(teaser, isNotNull);
      expect(behindScenes, isNotNull);

      expect(trailer.official, equals('true'));
      expect(teaser.official, equals('true'));
      expect(behindScenes.official, equals('false'));
    });

    test('should return videos for any movie ID', () async {
      // Test with different movie IDs
      final videos1 = await tmdbService.getMovieVideos(999);
      final videos2 = await tmdbService.getMovieVideos(12345);

      expect(videos1, isNotEmpty);
      expect(videos2, isNotEmpty);
      expect(videos1.length, equals(3));
      expect(videos2.length, equals(3));
    });

    test('should have valid video properties', () async {
      final videos = await tmdbService.getMovieVideos(1);

      for (final video in videos) {
        expect(video.id, isNotEmpty);
        expect(video.key, isNotEmpty);
        expect(video.name, isNotEmpty);
        expect(video.site, isNotEmpty);
        expect(video.type, isNotEmpty);
        expect(video.official, isNotNull);
      }
    });
  });
}
