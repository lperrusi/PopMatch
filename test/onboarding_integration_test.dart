import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/services/user_preference_analyzer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Onboarding Integration Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('Scenario 1: First-time user completes onboarding', () async {
      // Step 1: User signs up (simulated)
      final newUser = User(
        id: 'new_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'newuser@test.com',
        displayName: 'New User',
        preferences: {},
      );

      // Step 2: Check onboarding status
      final onboardingCompleted =
          newUser.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, false,
          reason: 'New user should not have completed onboarding');

      // Step 3: Complete onboarding
      final userAfterOnboarding = newUser.updatePreferences({
        'selectedGenres': [28, 35, 18],
        'selectedPlatforms': ['Netflix', 'Disney+'],
        'onboardingCompleted': true,
      });

      // Step 4: Verify onboarding completed
      expect(userAfterOnboarding.preferences['onboardingCompleted'], true);
      expect(userAfterOnboarding.preferences['selectedGenres'], [28, 35, 18]);
      expect(userAfterOnboarding.preferences['selectedPlatforms'],
          ['Netflix', 'Disney+']);

      // Step 5: Save user data (simulate)
      await prefs.setString(
          'user_data', jsonEncode(userAfterOnboarding.toJson()));

      // Step 6: Verify data was saved
      final savedJson = prefs.getString('user_data');
      expect(savedJson, isNotNull);
      final savedUser = User.fromJson(jsonDecode(savedJson!));
      expect(savedUser.preferences['onboardingCompleted'], true);
    });

    test('Scenario 2: Returning user skips onboarding', () async {
      // Step 1: Create user with completed onboarding
      final existingUser = User(
        id: 'existing_user_1',
        email: 'existing@test.com',
        preferences: {
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );

      // Step 2: Save user data
      await prefs.setString('user_data', jsonEncode(existingUser.toJson()));

      // Step 3: Simulate sign-in - load user data
      final savedJson = prefs.getString('user_data');
      final loadedUser = User.fromJson(jsonDecode(savedJson!));

      // Step 4: Check onboarding status
      final onboardingCompleted =
          loadedUser.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, true,
          reason: 'Returning user should have completed onboarding');

      // Step 5: Verify preferences are loaded
      expect(loadedUser.preferences['selectedGenres'], [28, 35]);
      expect(loadedUser.preferences['selectedPlatforms'], ['Netflix']);
    });

    test('Scenario 3: User edits preferences from profile', () async {
      // Step 1: User with existing preferences
      var user = User(
        id: 'edit_user_1',
        email: 'edit@test.com',
        preferences: {
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );

      // Step 2: User edits preferences (adds more genres and platforms)
      user = user.updatePreferences({
        'selectedGenres': [28, 35, 18, 53], // Added Drama and Thriller
        'selectedPlatforms': [
          'Netflix',
          'Disney+',
          'HBO Max'
        ], // Added platforms
      });

      // Step 3: Verify preferences updated
      expect(user.preferences['onboardingCompleted'], true,
          reason: 'onboardingCompleted should remain true');
      expect((user.preferences['selectedGenres'] as List).length, 4);
      expect((user.preferences['selectedPlatforms'] as List).length, 3);
      expect(user.preferences['selectedGenres'], containsAll([28, 35, 18, 53]));
      expect(user.preferences['selectedPlatforms'],
          containsAll(['Netflix', 'Disney+', 'HBO Max']));

      // Step 4: Save updated preferences
      await prefs.setString('user_data', jsonEncode(user.toJson()));

      // Step 5: Verify saved
      final savedJson = prefs.getString('user_data');
      final savedUser = User.fromJson(jsonDecode(savedJson!));
      expect((savedUser.preferences['selectedGenres'] as List).length, 4);
      expect((savedUser.preferences['selectedPlatforms'] as List).length, 3);
    });

    test('Scenario 4: Streaming platforms auto-applied from preferences', () {
      // Step 1: User with saved platform preferences
      final user = User(
        id: 'platform_user_1',
        email: 'platform@test.com',
        preferences: {
          'selectedPlatforms': ['Netflix', 'Disney+', 'HBO Max'],
        },
      );

      // Step 2: Extract platforms for MovieProvider
      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      expect(selectedPlatforms, isNotNull);

      // Step 3: Convert to string list (as done in SwipeScreen)
      final platformList = selectedPlatforms!.map((p) => p.toString()).toList();
      expect(platformList, ['Netflix', 'Disney+', 'HBO Max']);

      // Step 4: Verify platforms can be used for filtering
      expect(platformList.isNotEmpty, true);
      expect(platformList.length, 3);
    });

    test('Scenario 5: Preferences used in recommendation algorithm', () async {
      // Step 1: New user with onboarding preferences but no liked movies
      final newUser = User(
        id: 'rec_user_1',
        email: 'rec@test.com',
        likedMovies: [], // No liked movies yet
        preferences: {
          'selectedGenres': [28, 35, 18], // From onboarding
        },
      );

      // Step 2: Analyze preferences
      final analyzer = UserPreferenceAnalyzer();
      final preferences = await analyzer.analyzePreferences(newUser);

      // Step 3: Verify onboarding genres are used
      expect(preferences.topGenres, containsAll([28, 35, 18]));
      expect(preferences.topGenres.length, 3);

      // Step 4: User likes some movies
      final userWithLikes = newUser.copyWith(
        likedMovies: ['123', '456', '789'],
      );

      // Step 5: Preferences should still be accessible
      expect(userWithLikes.preferences['selectedGenres'], [28, 35, 18]);
    });

    test('Scenario 6: Multiple sign-ins preserve preferences', () async {
      // Step 1: First sign-in - complete onboarding
      var user = User(
        id: 'multi_user_1',
        email: 'multi@test.com',
        preferences: {},
      );
      user = user.updatePreferences({
        'selectedGenres': [28, 35],
        'selectedPlatforms': ['Netflix'],
        'onboardingCompleted': true,
      });
      await prefs.setString('user_data', jsonEncode(user.toJson()));

      // Step 2: Second sign-in - load user
      var savedJson = prefs.getString('user_data');
      var loadedUser = User.fromJson(jsonDecode(savedJson!));
      expect(loadedUser.preferences['onboardingCompleted'], true);

      // Step 3: Third sign-in - preferences still there
      savedJson = prefs.getString('user_data');
      loadedUser = User.fromJson(jsonDecode(savedJson!));
      expect(loadedUser.preferences['selectedGenres'], [28, 35]);
      expect(loadedUser.preferences['selectedPlatforms'], ['Netflix']);
      expect(loadedUser.preferences['onboardingCompleted'], true);
    });

    test('Scenario 7: Edge case - user with partial preferences', () {
      // User who completed onboarding but only selected genres, not platforms
      final user = User(
        id: 'partial_user_1',
        email: 'partial@test.com',
        preferences: {
          'selectedGenres': [28, 35],
          'onboardingCompleted': true,
          // No selectedPlatforms
        },
      );

      // Should handle missing platforms gracefully
      final platforms = user.preferences['selectedPlatforms'] as List<dynamic>?;
      expect(platforms, isNull);

      // Should still have onboarding completed
      expect(user.preferences['onboardingCompleted'], true);
    });

    test('Scenario 8: Preferences merge correctly on updates', () {
      // Step 1: Initial onboarding
      var user = User(
        id: 'merge_user_1',
        email: 'merge@test.com',
        preferences: {
          'selectedGenres': [28, 35],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );

      // Step 2: Update only genres
      user = user.updatePreferences({
        'selectedGenres': [28, 35, 18],
      });

      // Step 3: Verify merge (platforms and onboardingCompleted preserved)
      expect(user.preferences['selectedGenres'], [28, 35, 18]);
      expect(user.preferences['selectedPlatforms'], ['Netflix']);
      expect(user.preferences['onboardingCompleted'], true);

      // Step 4: Update only platforms
      user = user.updatePreferences({
        'selectedPlatforms': ['Netflix', 'Disney+'],
      });

      // Step 5: Verify merge (genres and onboardingCompleted preserved)
      expect(user.preferences['selectedGenres'], [28, 35, 18]);
      expect(user.preferences['selectedPlatforms'], ['Netflix', 'Disney+']);
      expect(user.preferences['onboardingCompleted'], true);
    });
  });

  group('Error Handling Tests', () {
    test('Handles corrupted user data gracefully', () {
      // Simulate corrupted JSON
      try {
        const corruptedJson = '{"invalid": json}';
        final user =
            User.fromJson(jsonDecode(corruptedJson) as Map<String, dynamic>);
        // Should handle missing fields gracefully
        expect(user.preferences, isA<Map<String, dynamic>>());
      } catch (e) {
        // Expected to fail on invalid JSON
        expect(e, isA<FormatException>());
      }
    });

    test('Handles missing preferences field', () {
      final json = {
        'id': 'test_id',
        'email': 'test@test.com',
        'watchlist': [],
        'likedMovies': [],
        'dislikedMovies': [],
        // No preferences field
      };

      final user = User.fromJson(json);
      expect(user.preferences, isA<Map<String, dynamic>>());
      expect(user.preferences.isEmpty, true);
    });

    test('Handles null values in preferences', () {
      final user = User(
        id: 'null_user_1',
        email: 'null@test.com',
        preferences: {
          'selectedGenres': null,
          'selectedPlatforms': null,
        },
      );

      // Should handle null gracefully
      expect(user.preferences['selectedGenres'], isNull);
      expect(user.preferences['selectedPlatforms'], isNull);
    });
  });
}
