import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/services/user_preference_analyzer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Onboarding and Preferences Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Clear preferences before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('User preferences are saved during onboarding', () async {
      // Create a new user
      final user = User(
        id: 'test_user_1',
        email: 'test@example.com',
        displayName: 'Test User',
        preferences: {},
      );

      // Simulate onboarding completion
      final updatedUser = user.updatePreferences({
        'selectedGenres': [28, 35, 18], // Action, Comedy, Drama
        'selectedPlatforms': ['Netflix', 'Disney+'],
        'selectedYears': [2024, 2023],
        'onboardingCompleted': true,
      });

      // Verify preferences are saved
      expect(updatedUser.preferences['selectedGenres'], [28, 35, 18]);
      expect(
          updatedUser.preferences['selectedPlatforms'], ['Netflix', 'Disney+']);
      expect(updatedUser.preferences['onboardingCompleted'], true);
    });

    test('onboardingCompleted flag prevents showing onboarding again', () {
      // User with completed onboarding
      final userWithOnboarding = User(
        id: 'test_user_2',
        email: 'test2@example.com',
        preferences: {
          'onboardingCompleted': true,
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
        },
      );

      // User without completed onboarding
      final userWithoutOnboarding = User(
        id: 'test_user_3',
        email: 'test3@example.com',
        preferences: {},
      );

      // Check onboarding status
      final onboardingCompleted1 =
          userWithOnboarding.preferences['onboardingCompleted'] ?? false;
      final onboardingCompleted2 =
          userWithoutOnboarding.preferences['onboardingCompleted'] ?? false;

      expect(onboardingCompleted1, true);
      expect(onboardingCompleted2, false);
    });

    test('Preferences are preserved when updating', () {
      final user = User(
        id: 'test_user_4',
        email: 'test4@example.com',
        preferences: {
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );

      // Update with new preferences (should merge, not replace)
      final updatedUser = user.updatePreferences({
        'selectedGenres': [28, 35, 18], // Add Drama
        'selectedPlatforms': ['Netflix', 'Disney+'], // Add Disney+
      });

      // Verify all preferences are preserved
      expect(updatedUser.preferences['onboardingCompleted'], true);
      expect(updatedUser.preferences['selectedGenres'], [28, 35, 18]);
      expect(
          updatedUser.preferences['selectedPlatforms'], ['Netflix', 'Disney+']);
    });

    test('UserPreferenceAnalyzer uses selectedGenres from onboarding',
        () async {
      final user = User(
        id: 'test_user_5',
        email: 'test5@example.com',
        likedMovies: [], // No liked movies yet
        preferences: {
          'selectedGenres': [28, 35, 18], // From onboarding
        },
      );

      final analyzer = UserPreferenceAnalyzer();
      final preferences = await analyzer.analyzePreferences(user);

      // Should use genres from onboarding since no liked movies
      expect(preferences.topGenres, containsAll([28, 35, 18]));
    });

    test(
        'UserPreferenceAnalyzer falls back to defaults if no onboarding genres',
        () async {
      final user = User(
        id: 'test_user_6',
        email: 'test6@example.com',
        likedMovies: [], // No liked movies
        preferences: {}, // No onboarding preferences
      );

      final analyzer = UserPreferenceAnalyzer();
      final preferences = await analyzer.analyzePreferences(user);

      // Should use default genres (Action, Comedy, Drama)
      expect(preferences.topGenres, containsAll([28, 35, 18]));
    });

    test('Preferences are properly serialized and deserialized', () {
      final user = User(
        id: 'test_user_7',
        email: 'test7@example.com',
        preferences: {
          'selectedGenres': [28, 35, 18],
          'selectedPlatforms': ['Netflix', 'Disney+', 'HBO Max'],
          'onboardingCompleted': true,
        },
      );

      // Serialize to JSON
      final json = user.toJson();
      expect(json['preferences'], isA<Map<String, dynamic>>());
      expect(json['preferences']['selectedGenres'], [28, 35, 18]);
      expect(json['preferences']['selectedPlatforms'],
          ['Netflix', 'Disney+', 'HBO Max']);
      expect(json['preferences']['onboardingCompleted'], true);

      // Deserialize from JSON
      final deserializedUser = User.fromJson(json);
      expect(deserializedUser.preferences['selectedGenres'], [28, 35, 18]);
      expect(deserializedUser.preferences['selectedPlatforms'],
          ['Netflix', 'Disney+', 'HBO Max']);
      expect(deserializedUser.preferences['onboardingCompleted'], true);
    });

    test('Multiple preference updates merge correctly', () {
      var user = User(
        id: 'test_user_8',
        email: 'test8@example.com',
        preferences: {},
      );

      // First update: onboarding
      user = user.updatePreferences({
        'selectedGenres': [28, 35],
        'selectedPlatforms': ['Netflix'],
        'onboardingCompleted': true,
      });

      // Second update: edit preferences
      user = user.updatePreferences({
        'selectedGenres': [28, 35, 18, 53], // Add more genres
        'selectedPlatforms': ['Netflix', 'Disney+'], // Add platform
      });

      // Verify all updates are merged
      expect(user.preferences['onboardingCompleted'], true); // Still there
      expect(user.preferences['selectedGenres'], [28, 35, 18, 53]);
      expect(user.preferences['selectedPlatforms'], ['Netflix', 'Disney+']);
    });

    test('Empty preferences handled correctly', () {
      final user = User(
        id: 'test_user_9',
        email: 'test9@example.com',
        preferences: {},
      );

      // Should not crash when accessing empty preferences
      expect(user.preferences['selectedGenres'], isNull);
      expect(user.preferences['selectedPlatforms'], isNull);
      expect(user.preferences['onboardingCompleted'], isNull);

      // Should default to false for onboardingCompleted check
      final onboardingCompleted =
          user.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, false);
    });

    test('Preferences structure validation', () {
      final user = User(
        id: 'test_user_10',
        email: 'test10@example.com',
        preferences: {
          'selectedGenres': [28, 35, 18],
          'selectedPlatforms': ['Netflix', 'Disney+'],
          'onboardingCompleted': true,
        },
      );

      // Verify data types
      expect(user.preferences['selectedGenres'], isA<List>());
      expect(user.preferences['selectedPlatforms'], isA<List>());
      expect(user.preferences['onboardingCompleted'], isA<bool>());

      // Verify list contents
      final genres = user.preferences['selectedGenres'] as List;
      final platforms = user.preferences['selectedPlatforms'] as List;

      expect(genres.every((g) => g is int), true);
      expect(platforms.every((p) => p is String), true);
    });
  });

  group('Streaming Platforms Integration Tests', () {
    test('Platform list can be converted to string list', () {
      final platforms = ['Netflix', 'Disney+', 'HBO Max'];
      final platformList = platforms.map((p) => p.toString()).toList();

      expect(platformList, ['Netflix', 'Disney+', 'HBO Max']);
    });

    test('Platform preferences loaded from user data', () {
      final user = User(
        id: 'test_user_11',
        email: 'test11@example.com',
        preferences: {
          'selectedPlatforms': ['Netflix', 'Amazon Prime', 'Disney+'],
        },
      );

      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      expect(selectedPlatforms, isNotNull);
      expect(selectedPlatforms!.length, 3);
      expect(selectedPlatforms.contains('Netflix'), true);
      expect(selectedPlatforms.contains('Amazon Prime'), true);
      expect(selectedPlatforms.contains('Disney+'), true);
    });

    test('Empty platform list handled correctly', () {
      final user = User(
        id: 'test_user_12',
        email: 'test12@example.com',
        preferences: {
          'selectedPlatforms': [],
        },
      );

      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      expect(selectedPlatforms, isNotNull);
      expect(selectedPlatforms!.isEmpty, true);
    });
  });

  group('Onboarding Flow Simulation Tests', () {
    test('Complete onboarding flow simulation', () {
      // Step 1: New user signs up
      var user = User(
        id: 'new_user_1',
        email: 'newuser@example.com',
        preferences: {},
      );
      expect(user.preferences['onboardingCompleted'], isNull);

      // Step 2: User completes onboarding
      user = user.updatePreferences({
        'selectedGenres': [28, 35, 18],
        'selectedPlatforms': ['Netflix', 'Disney+'],
        'onboardingCompleted': true,
      });
      expect(user.preferences['onboardingCompleted'], true);

      // Step 3: User signs in again (simulate)
      final onboardingCompleted =
          user.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, true); // Should skip onboarding

      // Step 4: User edits preferences
      user = user.updatePreferences({
        'selectedGenres': [28, 35, 18, 53],
        'selectedPlatforms': ['Netflix', 'Disney+', 'HBO Max'],
      });
      expect(user.preferences['onboardingCompleted'], true); // Still true
      expect((user.preferences['selectedGenres'] as List).length, 4);
      expect((user.preferences['selectedPlatforms'] as List).length, 3);
    });

    test('Onboarding data persists across sessions', () {
      // Simulate saving to SharedPreferences
      final user = User(
        id: 'persist_user_1',
        email: 'persist@example.com',
        preferences: {
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );

      // Serialize
      final json = user.toJson();
      final jsonString = jsonEncode(json);

      // Deserialize (simulating loading from storage)
      final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedUser = User.fromJson(loadedJson);

      // Verify all data persisted
      expect(loadedUser.preferences['selectedGenres'], [28, 35]);
      expect(loadedUser.preferences['selectedPlatforms'], ['Netflix']);
      expect(loadedUser.preferences['onboardingCompleted'], true);
    });
  });
}
