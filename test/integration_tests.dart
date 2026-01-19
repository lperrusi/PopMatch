import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/main.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/movie_provider.dart';

void main() {
  group('PopMatch Integration Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const PopMatchApp());
      
      // Verify that the app starts without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('Movie provider should handle data correctly', () {
      final movieProvider = MovieProvider();
      
      // Test initial state
      expect(movieProvider.movies, isEmpty);
      expect(movieProvider.isLoading, isFalse);
      expect(movieProvider.error, isNull);
      expect(movieProvider.hasMorePages, isTrue);
      
      // Test that the provider can be initialized
      expect(movieProvider.genres, isEmpty);
      expect(movieProvider.filteredMovies, isEmpty);
    });

    test('Movie model should handle edge cases', () {
      // Test with minimal data
      final minimalMovie = Movie(
        id: 1,
        title: 'Minimal Movie',
      );
      
      expect(minimalMovie.id, 1);
      expect(minimalMovie.title, 'Minimal Movie');
      expect(minimalMovie.overview, isNull);
      expect(minimalMovie.voteAverage, isNull);
      expect(minimalMovie.formattedRating, 'N/A');
      expect(minimalMovie.year, isNull);
    });

    test('User model should work correctly', () {
      final user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
      );
      
      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoURL, 'https://example.com/photo.jpg');
    });

    test('Movie fromJson should handle missing fields', () {
      final json = {
        'id': 1,
        'title': 'Test Movie',
        // Missing other fields
      };
      
      final movie = Movie.fromJson(json);
      
      expect(movie.id, 1);
      expect(movie.title, 'Test Movie');
      expect(movie.overview, isNull);
      expect(movie.voteAverage, isNull);
      expect(movie.cast, isNull);
      expect(movie.crew, isNull);
      expect(movie.videos, isNull);
    });

    test('Movie copyWith should work correctly', () {
      final original = Movie(
        id: 1,
        title: 'Original Title',
        overview: 'Original overview',
        voteAverage: 8.0,
      );
      
      final updated = original.copyWith(
        title: 'Updated Title',
        voteAverage: 9.0,
      );
      
      expect(updated.id, 1);
      expect(updated.title, 'Updated Title');
      expect(updated.overview, 'Original overview');
      expect(updated.voteAverage, 9.0);
    });

    test('User model methods should work correctly', () {
      final user = User(
        id: 'user123',
        email: 'test@example.com',
      );
      
      // Test watchlist operations
      final userWithWatchlist = user.addToWatchlist('movie1');
      expect(userWithWatchlist.watchlist, contains('movie1'));
      
      final userWithoutWatchlist = userWithWatchlist.removeFromWatchlist('movie1');
      expect(userWithoutWatchlist.watchlist, isEmpty);
      
      // Test liked movies operations
      final userWithLiked = user.addLikedMovie('movie2');
      expect(userWithLiked.likedMovies, contains('movie2'));
      
      // Test disliked movies operations
      final userWithDisliked = user.addDislikedMovie('movie3');
      expect(userWithDisliked.dislikedMovies, contains('movie3'));
    });

    test('MovieProvider methods should work correctly', () {
      final movieProvider = MovieProvider();
      
      // Test initial state
      expect(movieProvider.movies, isEmpty);
      expect(movieProvider.isLoading, isFalse);
      expect(movieProvider.error, isNull);
      
      // Test clear filters
      movieProvider.clearFilters();
      expect(movieProvider.selectedGenreId, isNull);
      expect(movieProvider.selectedYear, isNull);
      expect(movieProvider.searchQuery, isEmpty);
      
      // Test clear error
      movieProvider.clearError();
      expect(movieProvider.error, isNull);
    });
  });
} 