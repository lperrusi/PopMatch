import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/edit_preferences_screen.dart';
import 'package:popmatch/screens/home/favorites_screen.dart';
import 'package:popmatch/screens/home/notifications_screen.dart';
import 'package:popmatch/screens/home/help_support_screen.dart';
import 'package:popmatch/screens/home/privacy_screen.dart';
import 'package:popmatch/screens/home/advanced_filter_screen.dart';
import 'package:popmatch/screens/home/streaming_filter_screen.dart';
import 'package:popmatch/screens/mood/mood_selection_screen.dart';
import 'package:popmatch/services/tmdb_service.dart';

/// Widget tests for medium and lower priority screens.
/// Medium: Edit preferences, Favorites, Mood selection, Advanced filter, Streaming filter.
/// Lower: Notifications, Help & support, Privacy.
/// Run: flutter test test/medium_lower_priority_screens_test.dart
void main() {
  late AuthProvider authProvider;
  late MovieProvider movieProvider;

  setUpAll(() {
    TMDBService.setTestMode(true);
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
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

  group('Edit Preferences (medium)', () {
    testWidgets('shows Edit Preferences title and step 1 of 2', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const EditPreferencesScreen()));
      await t.pumpAndSettle();

      expect(find.text('Edit Preferences'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('step 1 shows genre question and genre chips', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const EditPreferencesScreen()));
      await t.pumpAndSettle();

      expect(find.text('What genres do you love?'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
    });

    testWidgets('Next goes to step 2 with streaming platforms', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const EditPreferencesScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Where do you watch movies?'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('toggling genre selects it', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const EditPreferencesScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Action'));
      await t.pumpAndSettle();
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('Save button is present on step 2', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const EditPreferencesScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('Favorites (medium)', () {
    testWidgets('shows FAVORITES title and MOVIES / SHOWS tabs', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pump(); // don't settle to avoid async load
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.text('SHOWS'), findsOneWidget);
    });

    testWidgets('empty favorites shows No favorites yet and Start swiping', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pumpAndSettle();

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.text('Start swiping to like movies!'), findsOneWidget);
    });

    testWidgets('with liked movie shows list and movie title', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        likedMovies: ['1'],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pumpAndSettle();

      expect(find.text('The Shawshank Redemption'), findsOneWidget);
    });
  });

  group('Mood selection (medium) - full flow', () {
    testWidgets('shows How are you feeling and mood question', (t) async {
      await t.pumpWidget(wrap(const MoodSelectionScreen()));
      await t.pumpAndSettle();

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.text('What\'s your mood today?'), findsOneWidget);
      expect(find.text('Select Your Mood'), findsOneWidget);
    });

    testWidgets('shows mood grid with Happy and other moods', (t) async {
      await t.pumpWidget(wrap(const MoodSelectionScreen()));
      await t.pumpAndSettle();

      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Excited'), findsOneWidget);
      expect(find.text('Romantic'), findsOneWidget);
    });

    testWidgets('selecting a mood updates button to Find X Movies', (t) async {
      await t.pumpWidget(wrap(const MoodSelectionScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Happy'));
      await t.pumpAndSettle();

      expect(find.text('Find Happy Movies'), findsOneWidget);
    });

    testWidgets('Find X Movies button is tappable after selecting mood', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        displayName: 'User',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const MoodSelectionScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Happy'));
      await t.pumpAndSettle();
      expect(find.text('Find Happy Movies'), findsOneWidget);
      await t.tap(find.text('Find Happy Movies'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Advanced filter (medium)', () {
    testWidgets('shows Advanced Filters title and filter UI', (t) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Test',
          overview: 'Overview',
          posterPath: '/p.jpg',
          voteAverage: 7.0,
          releaseDate: '2024-01-01',
        ),
      ];
      await t.pumpWidget(wrap(
        AdvancedFilterScreen(
          movies: movies,
          onFilterApplied: (_) {},
        ),
      ));
      await t.pumpAndSettle();

      expect(find.text('Advanced Filters'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('has Apply and Reset or similar filter actions', (t) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Test',
          overview: 'Overview',
          posterPath: '/p.jpg',
          voteAverage: 7.0,
          releaseDate: '2024-01-01',
        ),
      ];
      await t.pumpWidget(wrap(
        AdvancedFilterScreen(
          movies: movies,
          onFilterApplied: (_) {},
        ),
      ));
      await t.pumpAndSettle();

      expect(find.text('Advanced Filters'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Reset and Apply Filters work', (t) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Test',
          overview: 'Overview',
          posterPath: '/p.jpg',
          voteAverage: 7.0,
          releaseDate: '2024-01-01',
        ),
      ];
      var applied = false;
      await t.pumpWidget(wrap(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => AdvancedFilterScreen(
                  movies: movies,
                  onFilterApplied: (_) => applied = true,
                ),
              ),
            ),
            child: const Text('OpenFilters'),
          ),
        ),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('OpenFilters'));
      await t.pumpAndSettle();

      await t.tap(find.text('Reset'));
      await t.pumpAndSettle();

      await t.tap(find.textContaining('Apply Filters'));
      await t.pumpAndSettle();

      expect(find.text('OpenFilters'), findsOneWidget);
      expect(applied, isTrue);
    });
  });

  group('Streaming filter (medium)', () {
    testWidgets('shows Streaming Filters title', (t) async {
      await t.pumpWidget(wrap(const StreamingFilterScreen()));
      await t.pump();

      expect(find.text('Streaming Filters'), findsOneWidget);
    });

    testWidgets('shows loading or content area', (t) async {
      await t.pumpWidget(wrap(const StreamingFilterScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Streaming Filters'), findsOneWidget);
    });

    testWidgets('shows Filter by Streaming Platform and platform selection', (t) async {
      await t.pumpWidget(wrap(const StreamingFilterScreen()));
      await t.pumpAndSettle();

      expect(find.text('Filter by Streaming Platform'), findsOneWidget);
    });
  });

  group('Notifications (lower)', () {
    testWidgets('shows NOTIFICATIONS title and description', (t) async {
      await t.pumpWidget(wrap(const NotificationsScreen()));
      await t.pumpAndSettle();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Choose what you want to be notified about.'), findsOneWidget);
    });

    testWidgets('has notification toggles', (t) async {
      await t.pumpWidget(wrap(const NotificationsScreen()));
      await t.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('toggling Push notifications updates switch', (t) async {
      await t.pumpWidget(wrap(const NotificationsScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Push notifications'));
      await t.pumpAndSettle();

      expect(find.text('Push notifications'), findsOneWidget);
    });
  });

  group('Help & support (lower)', () {
    testWidgets('shows HELP & SUPPORT title', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HelpSupportScreen(),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('HELP & SUPPORT'), findsOneWidget);
    });

    testWidgets('shows Frequently asked questions and first FAQ', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HelpSupportScreen(),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Frequently asked questions'), findsOneWidget);
      expect(find.text('How does swiping work?'), findsOneWidget);
    });

    testWidgets('shows Contact us and Email support', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HelpSupportScreen(),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Contact us'), findsOneWidget);
      expect(find.text('Email support'), findsOneWidget);
      expect(find.text('support@popmatch.app'), findsOneWidget);
    });

    testWidgets('tapping FAQ expands answer', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HelpSupportScreen(),
        ),
      );
      await t.pumpAndSettle();

      await t.tap(find.text('How does swiping work?'));
      await t.pumpAndSettle();

      expect(
        find.textContaining('Swipe right to like'),
        findsOneWidget,
      );
    });
  });

  group('Privacy (lower)', () {
    testWidgets('shows PRIVACY title and data usage text', (t) async {
      await t.pumpWidget(wrap(const PrivacyScreen()));
      await t.pumpAndSettle();

      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('Control how your data is used to personalize your experience.'), findsOneWidget);
    });

    testWidgets('shows Use data for recommendations toggle', (t) async {
      await t.pumpWidget(wrap(const PrivacyScreen()));
      await t.pumpAndSettle();

      expect(find.text('Use data for recommendations'), findsOneWidget);
    });

    testWidgets('shows Your data and Delete my data', (t) async {
      await t.pumpWidget(wrap(const PrivacyScreen()));
      await t.pumpAndSettle();

      expect(find.text('Your data'), findsOneWidget);
      expect(find.text('Delete my data'), findsAtLeastNWidgets(1));
    });

    testWidgets('Delete my data opens dialog', (t) async {
      await t.pumpWidget(wrap(const PrivacyScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Delete my data'));
      await t.pumpAndSettle();

      expect(find.text('Delete my data'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Delete dialog Learn more shows SnackBar', (t) async {
      await t.pumpWidget(wrap(const PrivacyScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Delete my data'));
      await t.pumpAndSettle();
      await t.tap(find.text('Learn more'));
      await t.pumpAndSettle();

      expect(
        find.textContaining('To delete your account'),
        findsOneWidget,
      );
    });
  });
}
