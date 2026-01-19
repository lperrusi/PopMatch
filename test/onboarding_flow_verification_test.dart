import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Comprehensive test to verify the complete onboarding flow
void main() {
  group('Onboarding Flow Verification', () {
    late SharedPreferences prefs;
    late AuthService authService;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      authService = AuthService();
      authProvider = AuthProvider();
    });

    test('COMPLETE FLOW: Sign up → Complete onboarding → Sign in again → Should skip onboarding', () async {
      // Step 1: User signs up
      final email = 'test@example.com';
      final password = 'password123';
      final displayName = 'Test User';
      
      print('\n=== STEP 1: User Signs Up ===');
      final newUser = await authService.signUpWithEmailAndPassword(email, password, displayName);
      expect(newUser, isNotNull);
      expect(newUser?.email, email);
      expect(newUser?.preferences['onboardingCompleted'], isNull);
      print('✅ User created: ${newUser?.email}');
      
      // Verify user data is saved
      final userDataAfterSignup = prefs.getString('user_data');
      expect(userDataAfterSignup, isNotNull);
      final userAfterSignup = User.fromJson(jsonDecode(userDataAfterSignup!));
      print('✅ User data saved. onboardingCompleted: ${userAfterSignup.preferences['onboardingCompleted']}');
      
      // Step 2: Simulate onboarding completion
      print('\n=== STEP 2: User Completes Onboarding ===');
      authProvider = AuthProvider();
      // Manually set user data to simulate login
      await authProvider.signInWithEmailAndPassword(email, password);
      
      // Complete onboarding
      await authProvider.updatePreferences({
        'selectedGenres': [28, 35],
        'selectedPlatforms': ['Netflix', 'Disney+'],
        'onboardingCompleted': true,
      });
      
      // Verify preferences were saved
      final onboardingCompleted = authProvider.userData?.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, true, reason: 'onboardingCompleted should be true after onboarding');
      print('✅ Onboarding completed. Flag: $onboardingCompleted');
      
      // Verify data is persisted
      final userDataAfterOnboarding = prefs.getString('user_data');
      expect(userDataAfterOnboarding, isNotNull);
      final userAfterOnboarding = User.fromJson(jsonDecode(userDataAfterOnboarding!));
      expect(userAfterOnboarding.preferences['onboardingCompleted'], true);
      print('✅ User data persisted. onboardingCompleted: ${userAfterOnboarding.preferences['onboardingCompleted']}');
      
      // Step 3: Simulate second login
      print('\n=== STEP 3: User Signs In Again (Second Login) ===');
      
      // Clear auth provider to simulate fresh login
      final newAuthProvider = AuthProvider();
      await newAuthProvider.signInWithEmailAndPassword(email, password);
      
      // Verify user data is loaded
      expect(newAuthProvider.userData, isNotNull);
      expect(newAuthProvider.userData?.email, email);
      
      // CRITICAL: Check if onboardingCompleted is preserved
      final onboardingCompletedOnSecondLogin = newAuthProvider.userData?.preferences['onboardingCompleted'] ?? false;
      print('🔍 onboardingCompleted on second login: $onboardingCompletedOnSecondLogin');
      print('📋 All preferences: ${newAuthProvider.userData?.preferences}');
      
      expect(onboardingCompletedOnSecondLogin, true, 
        reason: 'onboardingCompleted should be true on second login - user should skip onboarding');
      
      // Verify preferences are preserved
      expect(newAuthProvider.userData?.preferences['selectedGenres'], [28, 35]);
      expect(newAuthProvider.userData?.preferences['selectedPlatforms'], ['Netflix', 'Disney+']);
      
      print('✅ Second login successful - onboarding should be skipped');
    });

    test('VERIFY: User data loading by email in development mode', () async {
      // Create a user and save it
      final email = 'test2@example.com';
      final user = User(
        id: 'test_id_123',
        email: email,
        displayName: 'Test User 2',
        preferences: {
          'selectedGenres': [28],
          'selectedPlatforms': ['Netflix'],
          'onboardingCompleted': true,
        },
      );
      
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      
      // Also set up registered_users and user_info for sign-in
      final registeredUsers = {email.toLowerCase(): 'hashed_password'};
      await prefs.setString('registered_users', jsonEncode(registeredUsers));
      
      final userInfo = {
        email.toLowerCase(): {
          'email': email.toLowerCase(),
          'displayName': 'Test User 2',
          'id': 'test_id_456', // Different ID to test email matching
        }
      };
      await prefs.setString('user_info', jsonEncode(userInfo));
      
      // Try to sign in - should load existing user data by email
      final authProvider = AuthProvider();
      await authProvider.signInWithEmailAndPassword(email, 'password123');
      
      // Verify user data was loaded
      expect(authProvider.userData, isNotNull);
      expect(authProvider.userData?.email, email);
      
      // CRITICAL: Verify onboardingCompleted is preserved
      final onboardingCompleted = authProvider.userData?.preferences['onboardingCompleted'] ?? false;
      expect(onboardingCompleted, true, 
        reason: 'onboardingCompleted should be preserved when loading by email');
      
      // Verify all preferences are preserved
      expect(authProvider.userData?.preferences['selectedGenres'], [28]);
      expect(authProvider.userData?.preferences['selectedPlatforms'], ['Netflix']);
    });
  });
}
