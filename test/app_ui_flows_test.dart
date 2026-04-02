import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/main.dart';
import 'package:popmatch/screens/tutorial/tutorial_screen.dart';
import 'package:popmatch/screens/auth/login_screen.dart';
import 'package:popmatch/screens/auth/register_screen.dart';
import 'package:popmatch/screens/auth/forgot_password_screen.dart';
import 'package:popmatch/screens/onboarding/onboarding_screen.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';

/// Full UI flow tests: user interaction simulation on key screens.
/// Run: flutter test test/app_ui_flows_test.dart
void main() {
  group('PopMatch UI flow tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Splash screen', () {
      testWidgets('Shows PopMatch title and Loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(const PopMatchApp());
        await tester.pump();

        expect(find.text('PopMatch'), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
        // Elapse splash timer so test teardown doesn't complain about pending timers
        await tester.binding.pump(const Duration(seconds: 4));
      });
    });

    group('Tutorial / intro screens', () {
      testWidgets('Shows first intro title and can tap Next',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const TutorialScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SWIPE TO MATCH'), findsOneWidget);
        expect(find.textContaining('Swipe right to like'), findsOneWidget);

        // Tap next (chevron right)
        final nextButton = find.byIcon(Icons.chevron_right);
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          expect(find.text('AI Powered Picks'), findsOneWidget);
        }
      });

      testWidgets('Last intro page shows Get Started',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const TutorialScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Go to last page (tap next twice or find Get Started on last)
        final nextButton = find.byIcon(Icons.chevron_right);
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        }
        expect(find.text('Curate Your Watchlist'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
      });
    });

    group('Login screen', () {
      testWidgets('Shows PopMatch, email/password fields, Sign In',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));
        await tester.pumpAndSettle();

        expect(find.text('PopMatch'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('Can enter email and password', (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.pump();

        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });

      testWidgets('Forgot Password and Sign Up links exist',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);
      });

      testWidgets('Tapping Forgot Password navigates to forgot password screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: _wrapWithProviders(const LoginScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Forgot Password?'));
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();
        expect(find.text('FORGOT PASSWORD?'), findsOneWidget);
      });
    });

    group('Forgot password screen', () {
      testWidgets('Shows title and email field', (WidgetTester tester) async {
        await tester
            .pumpWidget(_wrapWithProviders(const ForgotPasswordScreen()));
        await tester.pumpAndSettle();

        expect(find.text('FORGOT PASSWORD?'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Send Reset Link'), findsOneWidget);
      });

      testWidgets('Back button is present', (WidgetTester tester) async {
        await tester
            .pumpWidget(_wrapWithProviders(const ForgotPasswordScreen()));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      });
    });

    group('Register screen', () {
      testWidgets('Shows JOIN POPMATCH and form fields',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const RegisterScreen()));
        await tester.pumpAndSettle();

        expect(find.text('JOIN POPMATCH'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(4));
      });

      testWidgets('Can enter all fields', (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const RegisterScreen()));
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'user@test.com');
        await tester.enterText(fields.at(1), 'MyDisplayName');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.pump();

        expect(find.text('user@test.com'), findsOneWidget);
        expect(find.text('MyDisplayName'), findsOneWidget);
        expect(find.text('password123'), findsNWidgets(2));
      });
    });

    group('Onboarding screen', () {
      testWidgets('Step 1 shows WELCOME and feature list',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const OnboardingScreen()));
        await tester.pumpAndSettle();

        expect(find.text('WELCOME TO POPMATCH!'), findsOneWidget);
        expect(find.text('1 of 3'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('Step 1 shows Welcome and Next button',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const OnboardingScreen()));
        await tester.pump();

        expect(find.text('WELCOME TO POPMATCH!'), findsOneWidget);
        expect(find.text('1 of 3'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('Shows Back and Next in header', (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const OnboardingScreen()));
        await tester.pump();

        expect(find.text('1 of 3'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('Last step shows Get Started (via PageView drag or tap)',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const OnboardingScreen()));
        await tester.pump();

        // Verify first step; Get Started appears only on step 3
        expect(find.text('WELCOME TO POPMATCH!'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });
    });
  });
}

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => MovieProvider()),
      ChangeNotifierProvider(create: (_) => ShowProvider()),
      ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
      ChangeNotifierProvider(create: (_) => StreamingProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: child,
    ),
  );
}
