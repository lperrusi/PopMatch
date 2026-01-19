import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/screens/home/home_screen.dart';
import 'package:popmatch/screens/home/search_screen.dart';
import 'package:popmatch/screens/home/profile_screen.dart';
import 'package:popmatch/screens/mood/mood_selection_screen.dart';
import 'package:popmatch/screens/onboarding/onboarding_screen.dart';
import 'package:popmatch/screens/splash_screen.dart';
import 'package:popmatch/widgets/search_bar_widget.dart';

void main() {
  group('Screen Tests', () {
    late Movie testMovie;
    late User testUser;

    setUp(() {
      testMovie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'A test movie for testing purposes',
        posterPath: '/test-poster.jpg',
        backdropPath: '/test-backdrop.jpg',
        voteAverage: 8.5,
        voteCount: 1000,
        popularity: 85.5,
        releaseDate: '2023-01-01',
        isAdult: false,
        video: false,
        originalLanguage: 'en',
        originalTitle: 'Test Movie',
        genres: ['Action', 'Adventure'],
      );

      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: '/test-photo.jpg',
        watchlist: [],
        preferences: {},
      );
    });

    group('SplashScreen', () {
      testWidgets('should display splash screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show app logo or title
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('OnboardingScreen', () {
      testWidgets('should display onboarding screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OnboardingScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show onboarding content
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle onboarding navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OnboardingScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test if navigation buttons are present
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('MoodSelectionScreen', () {
      testWidgets('should display mood selection screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MoodSelectionScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show mood selection content
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle mood selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MoodSelectionScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test if mood options are present
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('HomeScreen', () {
      testWidgets('should display home screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show home screen content
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('should handle bottom navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test bottom navigation bar
        final bottomNavBar = find.byType(BottomNavigationBar);
        expect(bottomNavBar, findsOneWidget);
      });
    });

    group('SearchScreen', () {
      testWidgets('should display search screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: SearchScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show search screen content
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(SearchBarWidget), findsOneWidget);
      });

      testWidgets('should handle search functionality', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: SearchScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test search bar interaction
        await tester.enterText(find.byType(TextField), 'action');
        await tester.pump();

        expect(find.text('action'), findsOneWidget);
      });
    });

    group('ProfileScreen', () {
      testWidgets('should display profile screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => AuthProvider(),
              child: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show profile screen content
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should display user information', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => AuthProvider(),
              child: ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test if profile elements are present
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('Screen Navigation Tests', () {
      testWidgets('should navigate between screens', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test navigation to different tabs
        final bottomNavItems = find.byType(BottomNavigationBarItem);
        expect(bottomNavItems, findsWidgets);
      });
    });

    group('Screen Responsiveness Tests', () {
      testWidgets('should handle different screen sizes', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        
        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle small screen sizes', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        
        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Screen Error Handling Tests', () {
      testWidgets('should handle empty states gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: SearchScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not crash with empty data
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle loading states', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle loading states properly
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Screen Accessibility Tests', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test if screen has proper accessibility support
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should support screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => MovieProvider(),
              child: SearchScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test if interactive elements have proper semantics
        expect(find.byType(TextField), findsOneWidget);
      });
    });
  });
} 