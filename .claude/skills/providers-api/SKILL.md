---
name: providers-api
description: Use when writing or modifying screens and you need to know what methods and state each provider exposes. Trigger phrases: "what does AuthProvider expose", "how do I add to watchlist", "provider methods", "provider API", "what can I call on MovieProvider".
allowed-tools: [Read]
---

All 6 providers live in `lib/providers/`. Access them via `context.read<Provider>()` (one-shot action) or `context.watch<Provider>()` (rebuild on change).

---

## AuthProvider

**State:**
- `userData: User?` — full user object (watchlist, liked/disliked, preferences)
- `isAuthenticated: bool`
- `isLoading: bool`, `error: String?`

**Auth methods:**
```dart
await authProvider.initialize()
await authProvider.signInWithEmailAndPassword(email, password)
await authProvider.signUpWithEmailAndPassword(email, password, displayName)
await authProvider.signInWithGoogle()
await authProvider.signInWithApple()
await authProvider.sendPasswordResetEmail(email)
await authProvider.signOut()
await authProvider.updatePreferences(Map<String, dynamic> prefs)
```

**Watchlist / likes (movies):**
```dart
await authProvider.addToWatchlist(String movieId)
await authProvider.removeFromWatchlist(String movieId)
await authProvider.addLikedMovie(String movieId)
await authProvider.removeLikedMovie(String movieId)
await authProvider.addDislikedMovie(String movieId)
await authProvider.removeDislikedMovie(String movieId)
```

**Watchlist / likes (shows):**
```dart
await authProvider.addShowToWatchlist(String showId)
await authProvider.removeFromWatchlistShow(String showId)
await authProvider.addLikedShow(String showId)
await authProvider.removeLikedShow(String showId)
await authProvider.addDislikedShow(String showId)
await authProvider.removeDislikedShow(String showId)
```

**Episode tracking:**
```dart
await authProvider.setEpisodeWatched(showId, season, episode, bool watched)
```

**User model key fields:**
```dart
user.watchlist              // List<String> movie IDs
user.watchlistShowsOrEmpty  // List<String> show IDs (null-safe)
user.likedMovies            // List<String>
user.dislikedMovies         // List<String>
user.likedShows             // List<String>
user.dislikedShows          // List<String>
user.preferences            // Map<String, dynamic>
  // Keys: onboardingCompleted, selectedGenres, selectedPlatforms,
  //       tv_watched_episodes, tv_last_watched_at
```

---

## MovieProvider

**State:**
- `movies: List<Movie>` — full loaded set (recommendation pipeline)
- `filteredMovies: List<Movie>` — after swipe filters applied
- `genres: Map<int, String>` — TMDB genre map
- `isLoading: bool`, `isPreloading: bool`, `hasMorePages: bool`
- `swipeMoods`, `swipeSelectedGenres`, `swipeSelectedPlatforms`

**Load methods:**
```dart
await movieProvider.loadCuratedStarterMovies({bool refresh = false, User? user})
await movieProvider.loadPersonalizedRecommendations(User user, {bool refresh, bool insertAtFront, bool backgroundLoad})
await movieProvider.loadMoreMovies({User? user})           // pagination
await movieProvider.loadMoviesByMood(Mood mood)
await movieProvider.checkAndPreload(User? user)            // buffer management
```

**Filter methods:**
```dart
movieProvider.setSwipeFilters(List<Mood> moods, List<int> genres, List<String> platforms)
movieProvider.setSwipePlatforms(List<String> platformIds)
movieProvider.setSwipeGenres(List<int> genreIds)
```

**Swipe actions:**
```dart
movieProvider.removeMovie(int movieId)   // called after each swipe
```

**Test helpers:**
```dart
movieProvider.setTestGenres(Map<int, String> genres)
```

> `MovieProvider.movies` ≠ "all movies the user ever liked". It's only movies currently in the recommendation pipeline for this session. Use `MovieCacheService.getMovieDetails(id)` to fetch any movie by ID.

---

## ShowProvider

Mirrors `MovieProvider` exactly for TV shows. Key differences:

```dart
// Load
await showProvider.loadCuratedStarterShows({bool refresh, User? user})
await showProvider.loadPersonalizedRecommendations(User user, {...})
await showProvider.checkAndPreload(User? user)

// Swipe
showProvider.removeShow(int showId)

// Filters — same API as MovieProvider
showProvider.setSwipeFilters(moods, genres, platforms)
```

State: `shows`, `filteredShows`, `isLoading`, `isPreloading`, `hasMorePages`.

---

## RecommendationsProvider

**State:**
- `recommendations: List<Movie>`
- `trendingRecommendations: List<Movie>`
- `moodRecommendations: List<Movie>`
- `becauseYouLikedRecommendations: List<Movie>`
- `friendsRecommendations: List<Movie>`

**Methods:**
```dart
await recommendationsProvider.initialize()
recommendationsProvider.clearRecentlySkippedCache()
recommendationsProvider.clearRecentlyLikedCache()
```

Filters out movies the user interacted with in the last 24 hours.

---

## StreamingProvider

**State:**
- `availablePlatforms: List<StreamingPlatform>`
- `selectedPlatformIds: List<String>`

**Methods:**
```dart
await streamingProvider.initialize()
streamingProvider.selectPlatform(String platformId)
streamingProvider.deselectPlatform(String platformId)
List<Movie> filtered = streamingProvider.filterMoviesByPlatforms(movies)
```

Platform IDs match those in `StreamingPlatform.getById(id)`. The 11 platforms (Netflix, Disney+, Hulu, etc.) are defined as static constants in `lib/models/streaming_platform.dart`.

---

## SocialProvider

**State:**
- `incomingRequests: List<...>`
- `searchResults: List<...>`
- `friendsFeed: List<SocialActivity>`
- `privacy: SocialPrivacySettings?`

**Methods:**
```dart
await socialProvider.initialize()
await socialProvider.loadIncomingRequests()
await socialProvider.searchUsers(String query)
await socialProvider.loadPrivacy()
await socialProvider.loadFriendsFeed()
await socialProvider.ensureUserProfile(uid, email, displayName, photoURL)
```

Social features are gated by `FeatureFlags.socialUiEnabled`. Check the flag before rendering any social UI.

---

## Quick access patterns

```dart
// Read in a callback / event handler
final auth = context.read<AuthProvider>();
await auth.addToWatchlist(movie.id.toString());

// Watch in build (rebuilds widget on change)
final movies = context.watch<MovieProvider>().filteredMovies;

// Get user data safely
final user = context.read<AuthProvider>().userData;
if (user == null) return;
```
