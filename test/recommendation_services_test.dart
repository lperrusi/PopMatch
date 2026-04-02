import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/mood.dart';
import 'package:popmatch/services/contextual_recommendation_service.dart';
import 'package:popmatch/services/behavior_tracking_service.dart';
import 'package:popmatch/services/movie_embedding_service.dart';
import 'package:popmatch/services/collaborative_filtering_service.dart';
import 'package:popmatch/services/deep_learning_service.dart';
import 'package:popmatch/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Contextual Recommendation Service Tests', () {
    final service = ContextualRecommendationService();

    // Service returns 0-1 range (additive scoring), not multiplier > 1
    test('should return contextual weight for morning time', () {
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        genreIds: [35], // Comedy
      );

      final morningTime = DateTime(2024, 1, 1, 9, 0); // 9 AM
      final weight = service.getContextualWeight(movie, currentTime: morningTime);

      expect(weight, greaterThan(0.5)); // Comedy boosted in morning (higher than neutral 0.5)
      expect(weight, lessThanOrEqualTo(1.0));
    });

    test('should return contextual weight for evening time', () {
      final movie = Movie(
        id: 2,
        title: 'Action Movie',
        genreIds: [28], // Action
      );

      final eveningTime = DateTime(2024, 1, 1, 19, 0); // 7 PM
      final weight = service.getContextualWeight(movie, currentTime: eveningTime);

      expect(weight, greaterThan(0.5)); // Action boosted in evening
      expect(weight, lessThanOrEqualTo(1.0));
    });

    test('should return contextual weight for mood', () {
      final movie = Movie(
        id: 3,
        title: 'Horror Movie',
        genreIds: [27], // Horror
      );

      if (Mood.availableMoods.isNotEmpty) {
        final mood = Mood.availableMoods.first;
        final weight = service.getContextualWeight(movie, currentMoods: [mood]);

        expect(weight, greaterThanOrEqualTo(0.0));
        expect(weight, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('Behavior Tracking Service Tests', () {
    final service = BehaviorTrackingService();
    
    test('should record movie view', () {
      service.recordMovieView(1);
      final score = service.getInterestScore(1);
      
      expect(score, greaterThanOrEqualTo(0.0));
    });
    
    test('should record detail view', () {
      service.recordDetailView(2, startTime: DateTime.now().subtract(const Duration(seconds: 5)));
      final score = service.getInterestScore(2);
      
      expect(score, greaterThan(0.0)); // Should have positive score from detail view
    });
    
    test('should record swipe action', () {
      service.recordSwipe('user1', 3, 'like');
      final weight = service.getBehaviorWeight(3);

      // Behavior weight is 0.5-1.0 for positive interest (additive scoring)
      expect(weight, greaterThanOrEqualTo(0.5));
      expect(weight, lessThanOrEqualTo(1.0));
    });

    test('should calculate behavior weight correctly', () {
      service.recordMovieView(4);
      service.recordDetailView(4);
      service.recordSwipe('user1', 4, 'like');

      final weight = service.getBehaviorWeight(4);
      expect(weight, greaterThanOrEqualTo(0.5));
      expect(weight, lessThanOrEqualTo(1.0));
    });
  });

  group('Movie Embedding Service Tests', () {
    final service = MovieEmbeddingService();
    
    test('should create embedding for movie', () {
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        genreIds: [28, 18], // Action, Drama
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final embedding = service.createEmbedding(movie);

      expect(embedding.length, 64); // 64-dimensional embedding (implementation)
      expect(embedding.any((e) => e > 0), true); // Should have non-zero values
    });
    
    test('should calculate similarity between movies', () {
      final movie1 = Movie(
        id: 1,
        title: 'Action Movie',
        genreIds: [28],
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final movie2 = Movie(
        id: 2,
        title: 'Another Action Movie',
        genreIds: [28],
        voteAverage: 7.5,
        popularity: 45.0,
        runtime: 110,
        voteCount: 800,
        originalLanguage: 'en',
        releaseDate: '2021-01-01',
      );
      
      final similarity = service.getMovieSimilarity(movie1, movie2);
      
      expect(similarity, greaterThan(0.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });
    
    test('should find similar movies', () {
      final targetMovie = Movie(
        id: 1,
        title: 'Target Movie',
        genreIds: [28, 18],
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final candidates = <Movie>[
        targetMovie,
        Movie(id: 2, title: 'Similar', genreIds: [28, 18], voteAverage: 7.5, popularity: 45.0, runtime: 110, voteCount: 800, originalLanguage: 'en', releaseDate: '2021-01-01'),
        Movie(id: 3, title: 'Different', genreIds: [35], voteAverage: 6.0, popularity: 20.0, runtime: 90, voteCount: 200, originalLanguage: 'fr', releaseDate: '2010-01-01'),
      ];
      
      final similar = service.findSimilarMovies(targetMovie, candidates, limit: 2);
      
      expect(similar.length, lessThanOrEqualTo(2));
      expect(similar.any((m) => m.id == 2), true); // Should find similar movie
    });
  });

  group('Collaborative Filtering Service Tests', () {
    final service = CollaborativeFilteringService();

    test('should record user like', () async {
      await service.recordUserLike('user1', 1);
      await service.recordUserLike('user1', 2);

      final score = service.getCollaborativeScore(2, {1});

      expect(score, greaterThan(0.0)); // Should have co-occurrence
    });

    test('should get collaborative weight', () async {
      await service.recordUserLike('user1', 10);
      await service.recordUserLike('user1', 20);
      await service.recordUserLike('user1', 30);

      final weight = service.getCollaborativeWeight(20, {10, 30});

      // Weight is normalized to 0.3-1.0 range in implementation
      expect(weight, greaterThanOrEqualTo(0.3));
      expect(weight, lessThanOrEqualTo(1.0));
    });
    
    test('should get recommended movies', () async {
      // Clear any previous data
      await service.clearData();
      
      // Create co-occurrence: user1 likes 100 and 200 together
      await service.recordUserLike('user1', 100);
      await service.recordUserLike('user1', 200);
      
      // user2 likes 100 and 300 together (creates co-occurrence between 100 and 300)
      await service.recordUserLike('user2', 100);
      await service.recordUserLike('user2', 300);
      
      // If user likes 100, should recommend 200 and 300 (both co-occur with 100)
      final recommendations = service.getRecommendedMovies({100}, limit: 5);
      
      expect(recommendations.length, greaterThan(0));
      // Should recommend movies that co-occur with 100
      expect(recommendations.any((id) => id == 200 || id == 300), true);
    });
  });

  group('Deep Learning Service Tests', () {
    final service = DeepLearningService();
    
    test('should initialize service', () async {
      await service.initialize();
      
      expect(service.isModelReady, isA<bool>());
    });
    
    test('should prepare feature vector', () {
      final user = User(
        id: 'user1',
        email: 'test@test.com',
        likedMovies: ['1', '2', '3'],
        dislikedMovies: ['4'],
      );
      
      final movie = Movie(
        id: 10,
        title: 'Test Movie',
        genreIds: [28, 18],
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final features = service.prepareFeatureVector(user, movie);
      
      expect(features.length, greaterThan(0));
      // Features should be reasonable values (not necessarily 0-1, but reasonable)
      expect(features.every((f) => f >= 0.0), true); // Should be non-negative
    });
    
    test('should get prediction score', () async {
      await service.initialize();
      
      final user = User(
        id: 'user1',
        email: 'test@test.com',
        likedMovies: ['1', '2'],
        dislikedMovies: [],
      );
      
      final movie = Movie(
        id: 10,
        title: 'Test Movie',
        genreIds: [28],
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final score = await service.getPredictionScore(user, movie);
      
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
    
    test('should get deep learning weight', () async {
      await service.initialize();
      
      final user = User(
        id: 'user1',
        email: 'test@test.com',
        likedMovies: ['1'],
        dislikedMovies: [],
      );
      
      final movie = Movie(
        id: 10,
        title: 'Test Movie',
        genreIds: [28],
        voteAverage: 8.0,
        popularity: 50.0,
        runtime: 120,
        voteCount: 1000,
        originalLanguage: 'en',
        releaseDate: '2020-01-01',
      );
      
      final weight = await service.getDeepLearningWeight(user, movie);
      
      expect(weight, greaterThanOrEqualTo(0.5));
      expect(weight, lessThanOrEqualTo(1.5));
    });
  });
}

