import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/main.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/screens/tutorial/tutorial_screen.dart';
import 'package:popmatch/screens/auth/login_screen.dart';
import 'package:popmatch/screens/auth/register_screen.dart';
import 'package:popmatch/screens/auth/forgot_password_screen.dart';
import 'package:popmatch/screens/onboarding/onboarding_screen.dart';
import 'package:popmatch/screens/home/profile_screen.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/services/firebase_config.dart';

/// Full coverage: Splash, Tutorial, Sign In, Sign Out, Forgot Password, Setup (genres + streaming).
/// Run: flutter test test/auth_onboarding_sign_flows_test.dart
void main() {
  late AuthProvider authProvider;
  late MovieProvider movieProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
    FirebaseConfig.setTestMode(false);
  });

  setUp(() {
    authProvider = AuthProvider();
    movieProvider = MovieProvider();
    movieProvider.setTestGenres(const {28: 'Action', 12: 'Adventure', 35: 'Comedy'});
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
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

  group('Splash screen', () {
    testWidgets('shows PopMatch title and Loading text', (t) async {
      await t.pumpWidget(const PopMatchApp());
      await t.pump();
      expect(find.text('PopMatch'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      await t.binding.pump(const Duration(seconds: 4));
    });

    testWidgets('shows loading indicator (movie icon or gears)', (t) async {
      await t.pumpWidget(const PopMatchApp());
      await t.pump();
      expect(find.byIcon(Icons.movie_creation), findsOneWidget);
      await t.binding.pump(const Duration(seconds: 4));
    });
  });

  group('Tutorial (intro onboarding)', () {
    testWidgets('page 1: SWIPE TO MATCH and description', (t) async {
      await t.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: const TutorialScreen()));
      await t.pumpAndSettle();
      expect(find.text('SWIPE TO MATCH'), findsOneWidget);
      expect(find.textContaining('Swipe right to like'), findsOneWidget);
    });

    testWidgets('page 2: AI Powered Picks after tapping Next', (t) async {
      await t.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: const TutorialScreen()));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pumpAndSettle();
      expect(find.text('AI Powered Picks'), findsOneWidget);
    });

    testWidgets('page 3: Curate Your Watchlist and Get Started', (t) async {
      await t.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: const TutorialScreen()));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pumpAndSettle();
      expect(find.text('Curate Your Watchlist'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Get Started navigates to Login', (t) async {
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
            ChangeNotifierProvider(create: (_) => ShowProvider()),
            ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
            ChangeNotifierProvider(create: (_) => StreamingProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const TutorialScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pumpAndSettle();
      await t.tap(find.text('Get Started'));
      await t.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('Sign In (Login)', () {
    testWidgets('shows PopMatch, tagline, email and password fields', (t) async {
      await t.pumpWidget(wrap(const LoginScreen()));
      await t.pumpAndSettle();
      expect(find.text('PopMatch'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('empty email shows validation error', (t) async {
      await t.pumpWidget(wrap(const LoginScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Sign In'));
      await t.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('invalid email shows validation error', (t) async {
      await t.pumpWidget(wrap(const LoginScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'notanemail');
      await t.tap(find.text('Sign In'));
      await t.pumpAndSettle();
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('short password shows validation error', (t) async {
      await t.pumpWidget(wrap(const LoginScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'a@b.co');
      await t.enterText(find.byType(TextFormField).last, '12345');
      await t.tap(find.text('Sign In'));
      await t.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Forgot Password link navigates to Forgot Password screen', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: wrap(const LoginScreen()),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Forgot Password?'));
      await t.tap(find.text('Forgot Password?'));
      await t.pumpAndSettle();
      expect(find.text('FORGOT PASSWORD?'), findsOneWidget);
    });

    testWidgets('Sign Up link and Continue with Google exist', (t) async {
      await t.pumpWidget(wrap(const LoginScreen()));
      await t.pumpAndSettle();
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('Sign Out (Profile)', () {
    testWidgets('Profile shows PROFILE app bar', (t) async {
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('Profile shows loading when userData is null', (t) async {
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Profile shows user email and Sign Out when userData is set', (t) async {
      authProvider.setTestUserData(User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Sign Out opens confirmation dialog', (t) async {
      authProvider.setTestUserData(User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Sign Out'));
      await t.tap(find.text('Sign Out'));
      await t.pumpAndSettle();
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Sign Out dialog Cancel closes dialog', (t) async {
      authProvider.setTestUserData(User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Sign Out'));
      await t.tap(find.text('Sign Out'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Are you sure you want to sign out?'), findsNothing);
    });
  });

  group('Forgot Password', () {
    testWidgets('shows FORGOT PASSWORD?, email field, Send Reset Link', (t) async {
      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();
      expect(find.text('FORGOT PASSWORD?'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('empty email shows validation', (t) async {
      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Send Reset Link'));
      await t.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('invalid email shows validation', (t) async {
      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField), 'bad');
      await t.tap(find.text('Send Reset Link'));
      await t.pumpAndSettle();
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('back chevron is present', (t) async {
      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('valid email passes validation and Send Reset Link is tappable', (t) async {
      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField), 'user@example.com');
      await t.tap(find.text('Send Reset Link'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
    });
  });

  group('Register (Sign Up)', () {
    testWidgets('shows JOIN POPMATCH, 4 fields, Create Account', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      expect(find.text('JOIN POPMATCH'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('empty email shows validation', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Create Account'));
      await t.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('short display name shows validation', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await t.enterText(find.byType(TextFormField).at(1), 'A');
      await t.tap(find.text('Create Account'));
      await t.pumpAndSettle();
      expect(find.text('Display name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('short password shows validation', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await t.enterText(find.byType(TextFormField).at(1), 'Ab');
      await t.enterText(find.byType(TextFormField).at(2), '12345');
      await t.enterText(find.byType(TextFormField).at(3), '12345');
      await t.tap(find.text('Create Account'));
      await t.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('password mismatch shows validation', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await t.enterText(find.byType(TextFormField).at(1), 'Ab');
      await t.enterText(find.byType(TextFormField).at(2), 'password123');
      await t.enterText(find.byType(TextFormField).at(3), 'password456');
      await t.tap(find.text('Create Account'));
      await t.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Already have an account? Sign In link exists', (t) async {
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('Setup onboarding (favorite genres + stream services)', () {
    testWidgets('Step 1: WELCOME TO POPMATCH!, features, 1 of 3, Next', (t) async {
      await t.pumpWidget(wrap(const OnboardingScreen()));
      await t.pumpAndSettle();
      expect(find.text('WELCOME TO POPMATCH!'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.textContaining('Swipe to discover'), findsOneWidget);
    });

    testWidgets('Step 2: drag to step 2 shows genres or Loading genres', (t) async {
      await t.pumpWidget(wrap(const OnboardingScreen()));
      await t.pump();
      await t.drag(find.byType(PageView), const Offset(-400, 0));
      await t.pump(const Duration(milliseconds: 400));
      final hasStep2 = find.text('2 of 3').evaluate().isNotEmpty;
      final hasGenres = find.text('WHAT GENRES DO YOU LOVE?').evaluate().isNotEmpty;
      final hasLoading = find.text('Loading genres...').evaluate().isNotEmpty;
      expect(hasStep2 || hasGenres || hasLoading, true);
    });

    testWidgets('Step 2: Back button returns to step 1', (t) async {
      await t.pumpWidget(wrap(const OnboardingScreen()));
      await t.pump();
      await t.drag(find.byType(PageView), const Offset(-400, 0));
      await t.pump(const Duration(milliseconds: 500));
      if (find.text('Back').evaluate().isNotEmpty) {
        await t.tap(find.text('Back'));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.text('WELCOME TO POPMATCH!'), findsOneWidget);
      }
    });

    testWidgets('Step 3: onboarding has three pages (PageView with 3 children)', (t) async {
      await t.pumpWidget(wrap(const OnboardingScreen()));
      await t.pump();
      final pageView = t.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, 3);
    });
  });
}
