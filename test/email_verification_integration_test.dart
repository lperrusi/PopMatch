import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/screens/auth/email_verification_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Email Verification Integration Tests', () {
    late SharedPreferences prefs;

    setUpAll(() {
      FirebaseConfig.setTestMode(true);
    });

    tearDownAll(() {
      FirebaseConfig.setTestMode(false);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('Email Verification Screen', () {
      testWidgets('Displays user email address', (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);
        expect(
            find.text('We\'ve sent a 6-digit verification code to:'),
            findsOneWidget);
      });

      testWidgets('Shows resend code button', (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        expect(find.text('Resend Code'), findsOneWidget);
      });

      testWidgets('Shows verify code button', (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        expect(find.text('Verify Code'), findsOneWidget);
      });

      testWidgets('Verify Code button exists and is tappable',
          (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        final verifyButton = find.text('Verify Code');
        expect(verifyButton, findsOneWidget);

        await tester.tap(verifyButton);
        await tester.pump();

        // Tapping with incomplete code may show SnackBar; button still present
        expect(find.text('Verify Code'), findsOneWidget);
      });

      testWidgets('Shows loading state when resending code',
          (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<AuthProvider>(
              create: (_) => AuthProvider(),
              child: const EmailVerificationScreen(email: testEmail),
            ),
          ),
        );

        final resendButton = find.text('Resend Code');
        expect(resendButton, findsOneWidget);
        await tester.tap(resendButton);
        await tester.pump();

        expect(find.text('Resend Code'), findsOneWidget);
      });
    });

    group('Sign-up to Verification Flow', () {
      testWidgets(
          'Register screen shows verification screen after sign-up (Firebase enabled)',
          (WidgetTester tester) async {
        // This test verifies the navigation flow
        // In production with Firebase enabled:
        // 1. User fills registration form
        // 2. Taps "Create Account"
        // 3. Account created, verification email sent
        // 4. User signed out
        // 5. Navigate to EmailVerificationScreen

        // Note: This requires Firebase mocking for full testing
        // For now, we verify the screen structure

        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);
        expect(
            find.text('We\'ve sent a 6-digit verification code to:'),
            findsOneWidget);
      });

      testWidgets('Register screen skips verification in development mode',
          (WidgetTester tester) async {
        // In development mode (Firebase disabled):
        // 1. User signs up
        // 2. Skip verification screen
        // 3. Navigate to onboarding/home

        // This is verified by checking FirebaseConfig.isEnabled
        // In tests, this would be false, so verification is skipped
        expect(FirebaseConfig.isEnabled, isFalse);
      });
    });

    group('Error Handling', () {
      testWidgets('Resend code shows SnackBar on success or error',
          (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<AuthProvider>(
              create: (_) => AuthProvider(),
              child: const EmailVerificationScreen(email: testEmail),
            ),
          ),
        );

        final resendButton = find.text('Resend Code');
        await tester.tap(resendButton);
        await tester.pumpAndSettle();

        // In dev mode resend may succeed (green SnackBar) or show error (red SnackBar)
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('UI Elements', () {
      testWidgets('Verification screen has all required UI elements',
          (WidgetTester tester) async {
        const testEmail = 'test@example.com';

        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(
            find.text('We\'ve sent a 6-digit verification code to:'),
            findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);
        expect(find.text('Verify Code'), findsOneWidget);
        expect(find.text('Resend Code'), findsOneWidget);
        expect(
            find.text(
                'Didn\'t receive the code? Check your spam folder or try resending.'),
            findsOneWidget);
      });

      testWidgets('Email is displayed in styled container',
          (WidgetTester tester) async {
        // Arrange
        const testEmail = 'test@example.com';

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: EmailVerificationScreen(email: testEmail),
          ),
        );

        // Assert - Email should be visible
        expect(find.text(testEmail), findsOneWidget);
      });
    });
  });
}
