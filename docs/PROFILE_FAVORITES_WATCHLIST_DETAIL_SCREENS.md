# Profile, Favorites, Watchlist, Movie Detail & Show Detail – Screen Analysis

This document covers the **UI** and **features** of the Profile, Favorites, Watchlist, Movie detail, and Show detail screens, and how they are wired in the app.

---

## 1. Navigation and placement

- **HomeScreen** (`lib/screens/home/home_screen.dart`) uses **IndexedStack** and **RetroCinemaBottomNav** with 5 tabs:
  - **0 – Discover** (SwipeScreen)
  - **1 – For You** (RecommendationsScreen)
  - **2 – Watchlist** (WatchlistScreen)
  - **3 – Favorites** (FavoritesScreen)
  - **4 – Profile** (ProfileScreen)

- **Detail screens** are pushed on top of the current tab via `NavigationUtils.fastSlideRoute` (slide transition). They can call `updateHomeScreenTab(index)` to switch the home tab on pop (e.g. “Open in Watchlist”).

- **Note:** There is also an **EnhancedWatchlistScreen** (lists, tags, export) in the codebase; the **bottom-nav Watchlist** tab uses **WatchlistScreen** (single list: movies + shows).

---

## 2. Profile screen

**File:** `lib/screens/home/profile_screen.dart`

### 2.1 UI

- **App bar:** Title "PROFILE", Bebas Neue, cinema red background, warm cream text.
- **Body:** SingleChildScrollView on vintage paper background.
  - **User card (centered):** Card with CircleAvatar (photo from `user.photoURL` or initial from email), email, optional display name.
  - **Stats row:** Three `_StatCard`s – Watchlist (bookmark icon), Liked Movies (heart), Liked Shows (TV), values from `user.watchlist`, `user.likedMovies`, `user.likedShows`.
  - **Recently Liked Movies:** Section title + "View all" → FavoritesScreen. Up to 5 items from `_RecentLikedMoviesSection` (horizontal tiles; load by ID via MovieCacheService if not in MovieProvider). Tap → MovieDetailScreen.
  - **Recently Liked Shows:** Same pattern; load by ID via TMDBService. Tap → ShowDetailScreen.
  - **ACCOUNT SETTINGS:** Card with list tiles:
    - Edit Preferences (genres, streaming) → EditPreferencesScreen
    - Notifications → NotificationsScreen
    - Privacy → PrivacyScreen
    - Help & Support → HelpSupportScreen
    - Remove Ads → “Coming soon” dialog
  - **Sign Out** button (full width, cinema red).

### 2.2 Features and data

- **Auth:** Consumer&lt;AuthProvider&gt;. If `userData == null`, shows a loading spinner.
- **Data source:** User from AuthProvider (email, photoURL, displayName, watchlist, watchlistShowsOrEmpty, likedMovies, likedShows). Persisted via SharedPreferences (`user_data`).
- **Recently liked:** Movies loaded by ID (MovieCacheService); shows by ID (TMDBService). Fallback from MovieProvider/ShowProvider if already in memory.
- **Dialogs:** Logout confirmation; Remove Ads “coming soon”.

---

## 3. Favorites screen

**File:** `lib/screens/home/favorites_screen.dart`

### 3.1 UI

- **App bar:** "FAVORITES", cinema red. Actions: **Sort** (opens bottom sheet), **Delete** (toggle delete mode).
- **Tabs:** MOVIES | SHOWS (TabBar, Bebas Neue, popcorn gold indicator).
- **Body:** TabBarView.
  - **Movies tab:** List/grid of favorite movie cards; lazy load in batches of 8; scroll near bottom loads more. Empty: icon + “No favorite movies” + “Swipe right on Discover to like movies”.
  - **Shows tab:** Same pattern for shows; empty state for shows. Shows can show **Watching / Finished** badge (from AuthProvider episode progress).
- **Sort sheet:** Options per tab – Movies: Title A–Z/Z–A, Year newest/oldest, Rating high/low. Shows: **Watching first** / **Finished first** (by episode progress), then same title/year/rating options.
- **Delete mode:** Select items (checkboxes), then delete (remove from liked); cancel exits delete mode.

### 3.2 Features and data

- **Data source:** AuthProvider – `likedMovies`, `likedShows`. Movies loaded by ID via MovieCacheService (cache-first); shows via TMDBService.getShowDetails. Batches of 8; scroll triggers more load.
- **Sort:** `FavoriteSortOrder` (watchingFirst, finishedFirst, titleAsc, titleDesc, yearNewest, yearOldest, ratingHigh, ratingLow). `_getSortedShows(authProvider)` partitions by watching/finished and uses `getWatchedEpisodes` / `getShowLastWatchedAt`.
- **Remove from favorites:** Calls AuthProvider removeLikedMovie / removeLikedShow; state and SharedPreferences updated.
- **Tap item:** Movie → MovieDetailScreen; Show → ShowDetailScreen (fastSlideRoute).
- **Refresh:** Pull-to-refresh or explicit reload; re-syncs with AuthProvider liked IDs and reloads batches.

---

## 4. Watchlist screen

**File:** `lib/screens/home/watchlist_screen.dart`

### 4.1 UI

- **App bar:** "WATCHLIST", cinema red, Bebas Neue.
- **Tabs:** MOVIES | SHOWS (DefaultTabController length 2).
- **Body:** Consumer3&lt;AuthProvider, MovieProvider, ShowProvider&gt;.
  - If no watchlist IDs: empty state – “Your watchlist is empty” + “Start swiping to add…”.
  - Else: **WatchlistContent** – TabBarView with movies and shows.
- **Movies tab:** ListView of **WatchlistMovieCard** (poster, title, year, remove/minus). Minus opens **action sheet**: Remove from watchlist, Add to Favorites and remove from watchlist, Cancel.
- **Shows tab:** ListView of **WatchlistShowCard**; same minus → action sheet (Remove, Add to Favorites and remove, Cancel).
- **Empty per tab:** “No movies/shows in watchlist” with short hint.

### 4.2 Features and data

- **Data source:** AuthProvider – `watchlist`, `watchlistShowsOrEmpty`. Items come from MovieProvider/ShowProvider if the ID is in their current lists; otherwise loaded by ID in **WatchlistContent** (`_loadMissing` via TMDBService getMovieDetails / getShowDetails), stored in `_extraMovies` / `_extraShows`.
- **Remove:** `_removeFromWatchlist` / `_removeFromWatchlistShow` → AuthProvider.removeFromWatchlist / removeFromWatchlistShow.
- **Add to Favorites and remove:** Add to liked, remove from watchlist, SnackBar “moved to Favorites”.
- **Tap:** Movie → MovieDetailScreen; Show → ShowDetailScreen (with preload where used).
- **No custom lists here:** Single watchlist; for multiple lists and tags see EnhancedWatchlistScreen (not in bottom nav).

---

## 5. Movie detail screen

**File:** `lib/screens/home/movie_detail_screen.dart`

### 5.1 UI

- **Scaffold:** CustomScrollView, vintage paper background.
- **SliverAppBar:** Expanded height ~450, pinned, stretch; backdrop (or poster) as background; gradient overlay for text. Back button.
- **Content (below app bar):**
  - Title, year, rating, genres.
  - **Action row:** Watchlist (bookmark), Like (thumb up), Dislike (thumb down), Share. State from AuthProvider (isInWatchlist, isLikedMovie, isDislikedMovie).
  - Synopsis (expandable).
  - **Where to watch:** Streaming platforms (StreamingProvider / TMDB watch providers) when available.
  - **Trailers:** Horizontal list of trailers (TMDB videos); tap opens VideoPlayerWidget.
  - **Cast & crew:** Horizontal list (from loaded movie with cast/crew).
  - **Similar / Recommended:** Section “You might also like” – similar + recommendations loaded in background (TMDB similar + recommendations, optionally re-ranked with MovieEmbeddingService). Tap → MovieDetailScreen for another movie.
- **Theme:** Text and overlay colors adapt to backdrop (palette extraction: light vs dark) for readability.

### 5.2 Features and data

- **Input:** Receives `Movie` (at least basic info). Full details (cast, crew) loaded in background via MovieCacheService.getMovieDetails after a short delay (600 ms) so transition is smooth.
- **Watchlist:** Add/remove via AuthProvider.addToWatchlist / removeFromWatchlist.
- **Like/Dislike:** AuthProvider.addLikedMovie, removeLikedMovie, addDislikedMovie, removeDislikedMovie (mutually exclusive with like).
- **Share:** Share_plus with title, year, overview, optional link.
- **Similar movies:** TMDB getSimilarMovies + getMovieRecommendations; optionally re-ordered by embedding similarity; tap navigates to MovieDetailScreen.
- **Dispose:** PopScope; timers (details load, color extraction) cancelled on pop to avoid setState after dispose.

---

## 6. Show detail screen

**File:** `lib/screens/home/show_detail_screen.dart`

### 6.1 UI

- **Scaffold:** NestedScrollView, DefaultTabController length 2.
- **SliverAppBar:** Same idea as movie – expanded ~450, backdrop/poster, gradient. **Tabs in app bar:** Overview | Seasons & Episodes.
- **Overview tab:**
  - Title, first air date, rating, genres.
  - **Action row:** Watchlist, Like, Dislike, Share (AuthProvider: isInWatchlistShow, isLikedShow, isDislikedShow).
  - Synopsis (expandable).
  - Where to watch (streaming).
  - Trailers (if any).
  - Cast & crew.
- **Seasons & Episodes tab:**
  - Expandable sections per season; episodes loaded on expand via TMDB getSeasonDetails.
  - Episode list: watched state from AuthProvider.getWatchedEpisodes(showId); toggle watched via AuthProvider (setEpisodesWatched / preferences tv_watched_episodes, tv_last_watched_at).
  - Tap episode → episode detail dialog (_EpisodeDetailDialog).

### 6.2 Features and data

- **Input:** Receives `TvShow`. Full details + credits loaded in background (TMDBService getShowDetails + getShowCredits) after 600 ms.
- **Watchlist:** AuthProvider addShowToWatchlist / removeFromWatchlistShow.
- **Like/Dislike:** addLikedShow, removeLikedShow, addDislikedShow, removeDislikedShow.
- **Share:** Share_plus with show name and optional link.
- **Seasons/Episodes:** Lazy load per season; episode keys (e.g. S1E1) stored in user preferences; last watched timestamp for “Watching first” sort on Favorites.
- **Palette:** Same pattern as movie for light/dark overlay and text color.
- **Dispose:** PopScope; timers cancelled on pop.

---

## 7. Cross-screen consistency

| Feature            | Profile     | Favorites   | Watchlist   | Movie detail | Show detail |
|--------------------|------------|-------------|-------------|--------------|-------------|
| Theme              | Vintage paper, cinema red app bar | Same | Same | Same + dynamic overlay | Same + dynamic overlay |
| Watchlist add/remove | —        | —           | Remove only | Add/remove    | Add/remove   |
| Like/Dislike       | —          | Remove only (delete mode) | Move to Favorites | Add/remove like/dislike | Add/remove like/dislike |
| Navigate to detail | Recent → detail | Card tap → detail | Card tap → detail | Similar → detail | — |
| Data source        | AuthProvider | AuthProvider (liked IDs) + cache/TMDB | AuthProvider (watchlist IDs) + providers/TMDB | MovieCacheService, AuthProvider, TMDB | TMDB, AuthProvider |

---

## 8. File reference

| Screen / area      | File |
|--------------------|------|
| Profile            | `lib/screens/home/profile_screen.dart` |
| Favorites          | `lib/screens/home/favorites_screen.dart` |
| Watchlist (tab)    | `lib/screens/home/watchlist_screen.dart` |
| Movie detail       | `lib/screens/home/movie_detail_screen.dart` |
| Show detail        | `lib/screens/home/show_detail_screen.dart` |
| Home & tabs        | `lib/screens/home/home_screen.dart`, `lib/widgets/retro_cinema_bottom_nav.dart` |
| Edit preferences   | `lib/screens/home/edit_preferences_screen.dart` |
| Notifications      | `lib/screens/home/notifications_screen.dart` |
| Privacy            | `lib/screens/home/privacy_screen.dart` |
| Help & Support     | `lib/screens/home/help_support_screen.dart` |
| Enhanced watchlist | `lib/screens/home/enhanced_watchlist_screen.dart` (not in bottom nav) |

---

## 9. Summary

- **Profile:** User card, stats (watchlist + liked counts), recently liked movies/shows (load by ID), account settings (preferences, notifications, privacy, help, remove ads), sign out. All data from AuthProvider.
- **Favorites:** Two tabs (Movies, Shows), sort (including Watching/Finished for shows), delete mode, lazy-loaded lists from liked IDs; tap → detail.
- **Watchlist:** Two tabs (Movies, Shows), single list per type; items from providers or loaded by ID; remove or “Add to Favorites and remove”; tap → detail.
- **Movie detail:** Backdrop/poster, actions (watchlist, like, dislike, share), synopsis, where to watch, trailers, cast, similar/recommended movies; detail load and palette deferred for smooth transition.
- **Show detail:** Same actions; Overview + Seasons & Episodes tabs; episode progress (watched state) and last-watched used in Favorites “Watching first” sort.

All five screens use the same app theme (Retro Cinema / vintage paper, cinema red, warm cream, Bebas Neue/Lato) and are integrated with AuthProvider and, where needed, TMDB and MovieCacheService.
