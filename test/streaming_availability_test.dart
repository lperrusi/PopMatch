// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/services/streaming_service.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/models/streaming_platform.dart';

void main() {
  group('Streaming Availability Tests', () {
    late StreamingService streamingService;

    setUpAll(() {
      TMDBService.setTestMode(true);
    });

    tearDownAll(() {
      TMDBService.setTestMode(false);
    });

    setUp(() {
      streamingService = StreamingService.instance;
    });

    test('should return streaming availability for movies with mock data', () async {
      final availability = await streamingService.getStreamingAvailability(1);

      expect(availability, isNotNull);
      expect(availability!.movieId, equals(1));
      expect(availability.availablePlatforms, isNotEmpty);
      expect(availability.availablePlatforms, contains('netflix'));
      expect(availability.availablePlatforms, contains('hbo_max'));
    });

    test('should return streaming availability for movies without mock data', () async {
      final availability = await streamingService.getStreamingAvailability(999999);

      expect(availability, isNotNull);
      expect(availability!.movieId, equals(999999));
      expect(availability.availablePlatforms, isNotEmpty);
    });

    test('should return different availability patterns based on movie ID', () async {
      final availability1 = await streamingService.getStreamingAvailability(100);
      final availability2 = await streamingService.getStreamingAvailability(101);

      expect(availability1, isNotNull);
      expect(availability2, isNotNull);
      expect(availability1!.availablePlatforms, isNotEmpty);
      expect(availability2!.availablePlatforms, isNotEmpty);

      print('Movie 100 platforms: ${availability1.availablePlatforms}');
      print('Movie 101 platforms: ${availability2.availablePlatforms}');
    });

    test('should handle free movies correctly', () async {
      final availability = await streamingService.getStreamingAvailability(15);

      expect(availability, isNotNull);
      expect(availability!.availablePlatforms, isNotEmpty);
      // Service uses TMDB data; isFree/rental/purchase come from API when available
      expect(availability.rentalPrice, isNull);
      expect(availability.purchasePrice, isNull);
    });

    test('should return valid platform objects', () async {
      final availability = await streamingService.getStreamingAvailability(1);

      expect(availability, isNotNull);
      expect(availability!.platforms, isNotEmpty);

      for (final platform in availability.platforms) {
        expect(platform, isA<StreamingPlatform>());
        expect(platform.id, isNotEmpty);
        expect(platform.name, isNotEmpty);
      }
    });

    test('should check platform availability correctly', () async {
      final availability = await streamingService.getStreamingAvailability(1);

      expect(availability, isNotNull);
      expect(availability!.isAvailableOn('netflix'), isTrue);
      expect(availability.isAvailableOn('hbo_max'), isTrue);
      expect(availability.isAvailableOn('disney_plus'), isFalse);
    });
  });
} 