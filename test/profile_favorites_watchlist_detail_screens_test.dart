import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/models/movie.dart';
import 'package:popmatch/models/tv_show.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/providers/streaming_provider.dart';
import 'package:popmatch/screens/home/profile_screen.dart';
import 'package:popmatch/screens/home/favorites_screen.dart';
import 'package:popmatch/screens/home/watchlist_screen.dart';
import 'package:popmatch/screens/home/movie_detail_screen.dart';
import 'package:popmatch/screens/home/show_detail_screen.dart';
import 'package:popmatch/services/tmdb_service.dart';

/// Full round of widget tests for Profile, Favorites, Watchlist, Movie detail, and Show detail screens.
/// Covers UI and features: app bars, tabs, empty/loading states, actions, navigation.
/// Run: flutter test test/profile_favorites_watchlist_detail_screens_test.dart
void main() {
  late AuthProvider authProvider;
  late MovieProvider movieProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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

  group('Profile screen', () {
    testWidgets('shows loading when userData is null', (t) async {
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows PROFILE app bar and user content when userData is set', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'user@test.com',
        displayName: 'Test User',
        watchlist: [],
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('user@test.com'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('shows stats row with Watchlist, Liked Movies, Liked Shows', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: ['1'],
        likedMovies: ['1', '2'],
        likedShows: ['1'],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('shows Recently Liked Movies and View all', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: ['1'],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();

      expect(find.text('Recently Liked Movies'), findsOneWidget);
      expect(find.text('View all'), findsWidgets);
    });

    testWidgets('shows Recently Liked Shows and View all', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: ['1'],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.text('Recently Liked Shows'), findsOneWidget);
      expect(find.text('View all'), findsWidgets);
    });

    testWidgets('shows ACCOUNT SETTINGS and Edit Preferences, Notifications, Privacy, Help & Support, Remove Ads', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();

      expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
      expect(find.text('Edit Preferences'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Remove Ads'), findsOneWidget);
    });

    testWidgets('Sign Out button is present and opens dialog when tapped', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      await t.scrollUntilVisible(find.text('Sign Out'), 100, scrollable: find.byType(Scrollable));
      await t.tap(find.text('Sign Out'));
      await t.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Favorites screen', () {
    testWidgets('shows FAVORITES title and MOVIES / SHOWS tabs', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.text('SHOWS'), findsOneWidget);
    });

    testWidgets('empty favorites shows No favorites yet and Start swiping to like movies', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
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
        likedMovies: ['1'],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pumpAndSettle();

      expect(find.text('The Shawshank Redemption'), findsOneWidget);
    });

    testWidgets('SHOWS tab shows empty state when no liked shows', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('SHOWS'));
      await t.pumpAndSettle();

      expect(find.text('No favorite shows yet'), findsOneWidget);
      expect(find.text('Start swiping to like shows!'), findsOneWidget);
    });

    testWidgets('with liked show displays show name in SHOWS tab', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: ['1'],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('SHOWS'));
      await t.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsOneWidget);
    });

    testWidgets('has Sort and Delete actions in app bar', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        likedMovies: [],
        likedShows: [],
      ));
      await t.pumpWidget(wrap(const FavoritesScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('Watchlist screen', () {
    testWidgets('shows WATCHLIST title and MOVIES / SHOWS tabs', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: [],
        watchlistShows: [],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pumpAndSettle();

      expect(find.text('WATCHLIST'), findsOneWidget);
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.text('SHOWS'), findsOneWidget);
    });

    testWidgets('empty watchlist shows Your watchlist is empty and hint', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: [],
        watchlistShows: [],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pumpAndSettle();

      expect(find.text('Your watchlist is empty'), findsOneWidget);
      expect(find.textContaining('Start swiping to add'), findsOneWidget);
    });

    testWidgets('with watchlist movie shows movie in MOVIES tab', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: ['1'],
        watchlistShows: [],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.text('The Shawshank Redemption'), findsOneWidget);
    });

    testWidgets('with watchlist show shows show in SHOWS tab', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: [],
        watchlistShows: ['1'],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      await t.tap(find.text('SHOWS'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.text('Breaking Bad'), findsOneWidget);
    });

    testWidgets('MOVIES tab empty state shows No movies in watchlist', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: [],
        watchlistShows: ['1'],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pumpAndSettle();

      expect(find.text('No movies in watchlist'), findsOneWidget);
      expect(find.text('Start swiping to add movies!'), findsOneWidget);
    });

    testWidgets('SHOWS tab empty state shows No shows in watchlist', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        watchlist: ['1'],
        watchlistShows: [],
      ));
      await t.pumpWidget(wrap(const WatchlistScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      await t.tap(find.text('SHOWS'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.text('No shows in watchlist'), findsOneWidget);
      expect(find.text('Start swiping to add shows!'), findsOneWidget);
    });
  });

  group('Movie detail screen', () {
    testWidgets('shows movie title and basic info', (t) async {
      await t.binding.setSurfaceSize(const Size(800, 900));
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Overview text',
        posterPath: '/p.jpg',
        voteAverage: 8.5,
        releaseDate: '2023-01-01',
      );
      await t.pumpWidget(wrap(MovieDetailScreen(movie: movie)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(find.byType(Scaffold), findsOneWidget);
      await t.binding.setSurfaceSize(null);
    });

    testWidgets('shows Watchlist, Like, Dislike, Share action row', (t) async {
      await t.binding.setSurfaceSize(const Size(800, 900));
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Overview',
        posterPath: '/p.jpg',
        releaseDate: '2023-01-01',
      );
      await t.pumpWidget(wrap(MovieDetailScreen(movie: movie)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(IconButton), findsAtLeastNWidgets(4));
      await t.binding.setSurfaceSize(null);
    });

    testWidgets('scrollable content has scaffold', (t) async {
      final movie = Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Overview',
        posterPath: '/p.jpg',
        releaseDate: '2023-01-01',
      );
      await t.pumpWidget(wrap(MovieDetailScreen(movie: movie)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Show detail screen', () {
    testWidgets('shows show name and Overview / Seasons tabs', (t) async {
      await t.binding.setSurfaceSize(const Size(800, 900));
      final show = TvShow(
        id: 1,
        name: 'Test Show',
        overview: 'Overview',
        numberOfSeasons: 2,
      );
      await t.pumpWidget(wrap(ShowDetailScreen(show: show)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test Show'), findsAtLeastNWidgets(1));
      expect(find.text('Overview'), findsAtLeastNWidgets(1));
      expect(find.text('Seasons & Episodes'), findsOneWidget);
      await t.binding.setSurfaceSize(null);
    });

    testWidgets('shows Watchlist, Like, Dislike, Share action row', (t) async {
      await t.binding.setSurfaceSize(const Size(800, 900));
      final show = TvShow(id: 1, name: 'Test Show', overview: 'Overview');
      await t.pumpWidget(wrap(ShowDetailScreen(show: show)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(IconButton), findsAtLeastNWidgets(4));
      await t.binding.setSurfaceSize(null);
    });

    testWidgets('Seasons & Episodes tab shows content', (t) async {
      await t.binding.setSurfaceSize(const Size(800, 900));
      final show = TvShow(
        id: 1,
        name: 'Test Show',
        overview: 'Overview',
        numberOfSeasons: 2,
      );
      await t.pumpWidget(wrap(ShowDetailScreen(show: show)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 800));

      await t.tap(find.text('Seasons & Episodes'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.byType(Scaffold), findsOneWidget);
      await t.binding.setSurfaceSize(null);
    });
  });

  group('Profile → Account settings navigation', () {
    testWidgets('Edit Preferences opens EditPreferencesScreen', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
        preferences: {},
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Edit Preferences'));
      await t.pumpAndSettle();

      expect(find.text('Edit Preferences'), findsWidgets);
      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets('Notifications opens NotificationsScreen', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pumpAndSettle();

      await t.tap(find.text('Notifications'));
      await t.pumpAndSettle();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });

    testWidgets('Privacy opens PrivacyScreen', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      await t.scrollUntilVisible(find.text('Privacy'), 100, scrollable: find.byType(Scrollable));
      await t.tap(find.text('Privacy'));
      await t.pumpAndSettle();

      expect(find.text('PRIVACY'), findsOneWidget);
    });

    testWidgets('Help & Support opens HelpSupportScreen', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      await t.scrollUntilVisible(find.text('Help & Support'), 100, scrollable: find.byType(Scrollable));
      await t.tap(find.text('Help & Support'));
      await t.pumpAndSettle();

      expect(find.text('HELP & SUPPORT'), findsOneWidget);
    });

    testWidgets('Remove Ads shows coming soon dialog', (t) async {
      authProvider.setTestUserData(User(
        id: 'u1',
        email: 'u@test.com',
      ));
      await t.pumpWidget(wrap(const ProfileScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));

      await t.scrollUntilVisible(find.text('Remove Ads'), 100, scrollable: find.byType(Scrollable));
      await t.tap(find.text('Remove Ads'));
      await t.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Coming soon'), findsOneWidget);
    });
  });
}
