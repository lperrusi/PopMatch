# Discover Screen – Analysis

This document describes the **Discover** screen (implemented as **SwipeScreen**), how its UI elements are structured, how data is loaded, and how the backend (data sources and algorithms) supports it.

---

## 1. Screen identity and placement

- **User-facing name:** Discover (first tab in bottom nav; label "Discover", home icon).
- **Implementation:** `lib/screens/home/swipe_screen.dart` — `SwipeScreen` widget.
- **Navigation:** `HomeScreen` uses `IndexedStack`; index `0` is `SwipeScreen()`.

---

## 2. UI elements

### 2.1 App bar

- **Title:** "DISCOVER" (Bebas Neue, 32px, warm cream, letter-spacing 2).
- **Background:** `AppTheme.cinemaRed`.
- **Tabs:** MOVIES | SHOWS (TabBar, popcorn gold indicator, warm cream labels).
- **Actions:**
  - **Filter (tune icon):** Opens filter bottom sheet. Shows a small gold badge when any filter is active (mood, genre, or platform). Movies tab uses `MovieProvider` filters; Shows tab uses `ShowProvider` filters.
  - **Refresh:** Reloads the current tab’s content (movies or shows) with the same logic as initial load (personalized vs curated).

### 2.2 Body (TabBarView)

- **MOVIES tab:** Built by `_buildMoviesTab()`.
- **SHOWS tab:** Built by `_buildShowsTab()`.
- **Physics:** `NeverScrollableScrollPhysics()` so horizontal swipe is only for cards, not tab switching.

### 2.3 Movies tab content

- **Loading state:** Spinner + "Loading movies..." when `MovieProvider.isLoading && filteredMovies.isEmpty`.
- **Empty state:** Icon, "No movies found", "Try refreshing...", Refresh button when `filteredMovies.isEmpty` after load.
- **Main content:** A column with:
  - **Undo:** After each swipe, a floating snackbar **“Swipe recorded”** with **UNDO** (~2s). Undo uses `CardSwiperController.undo()` plus `onUndo` to revert likes/dislikes/skips in `AuthProvider` and to dismiss a pending/open match screen when relevant. Movies and shows use **separate** swiper controllers so undo targets the correct stack.
  - An **expanded** area containing **CardSwiper** (flutter_card_swiper):
    - **Cards count:** `movieProvider.filteredMovies.length`.
    - **Stack:** 3 cards visible (`numberOfCardsDisplayed: 3`), scale 0.92, back offset (0, 8).
    - **Directions:** Left, right, up, down (dislike, like, match, skip); **`onUndo`** wired for snackbar undo.
    - **Card widget:** `RetroCinemaMovieCard` (poster, title, tap → detail; in-card like/dislike optional).
  - **Swipe actions:** Right = like, Left = dislike, Up = match (like + match success screen), Down = skip.

### 2.4 Shows tab content

- Same structure as movies but using `ShowProvider.filteredShows` and `RetroCinemaShowCard`; swipe handlers call `addLikedShow` / `addDislikedShow` and show `MatchSuccessScreen` for match.

### 2.5 Filter flow (Movies; Shows reuse same structure)

- **Entry:** App bar filter icon → `_showFilterMenu(MovieProvider)` (or `_showShowFilterMenu` for shows, which currently delegates to the same menu).
- **Bottom sheet:** "Filters" title, "Clear All" if any filter active, then three rows:
  1. **Mood** → `_showMoodDialog` (multi-select moods).
  2. **Genres** → `_showGenreDialog` (multi-select genres).
  3. **Platform** → `_showPlatformDialog` (multi-select streaming platforms).
- **After selection:** Sheet closes and `_reloadMoviesWithFilters()` (or equivalent for shows) runs, which reloads personalized or curated content with the new filters.

### 2.6 Match success screen

- Shown on **up swipe** (match): like is recorded, then a modal with options: Continue, View details, Add to watchlist.

---

## 3. How elements are loaded

### 3.1 Initial load (movies)

- **When:** `initState` → `addPostFrameCallback` → `_loadMovies()` (after first frame).
- **Sequence:**
  1. 200 ms delay, then if auth is still loading, 300 ms more.
  2. If **user is logged in:**
     - Apply streaming platforms from `user.preferences['selectedPlatforms']` to `MovieProvider` if not already set.
     - `UserPreferenceAnalyzer().hasEnoughData(user)`:
       - **Yes** → `movieProvider.loadPersonalizedRecommendations(user, refresh: true)`.
       - **No** → `movieProvider.loadCuratedStarterMovies(refresh: true, user: user)`.
     - After 500 ms, `movieProvider.checkAndPreload(user)` to start buffer refill.
  3. If **no user** → `loadCuratedStarterMovies(refresh: true, user: null)` and then `checkAndPreload(null)`.

### 3.2 Tab switch (MOVIES ↔ SHOWS)

- **TabController listener:** On index change, `_loadMovies()` or `_loadShows()` is called.
- **Shows:** Same pattern as movies: user + `hasEnoughData` → personalized vs curated; then `showProvider.checkAndPreload(user)`.

### 3.3 Refresh button

- **Movies:** `_refreshMovies()` → same branch as initial load (personalized vs curated, `refresh: true`), then key refresh for CardSwiper.
- **Shows:** `_refreshShows()` → same for `ShowProvider`.

### 3.4 Filter change

- **Movies:** `_reloadMoviesWithFilters()` uses the same logic as initial load (personalized vs curated) with current filters already set on `MovieProvider` (mood, genres, platforms). So filters affect the **next** load of personalized/curated data.

### 3.5 Infinite swipe (buffer / preload)

- **Timer:** Every 3 seconds `_startBufferMaintenance()` runs and calls `movieProvider.checkAndPreload(user)` or `showProvider.checkAndPreload(user)` for the active tab.
- **On swipe:** When remaining cards ≤ 25 and `hasMorePages`, a delayed `checkAndPreload` is triggered.
- **Provider side (MovieProvider):**
  - `needsPreload` = `filteredMovies.length < 25 && hasMorePages && !isLoading && !isPreloading`.
  - `checkAndPreload` → `_ensureBufferFilled(user)` which rate-limits (2 s) and then either loads more personalized recommendations (`backgroundLoad: true`) or `loadMoreMovies()`.
  - Background additions use a deferred queue (`_pendingMovies`) and are flushed only when visible stack is low, reducing mid-swipe card pop-in.

---

## 4. Backend: data sources and “database”

There is **no separate app backend database**. All persistent data is either **local** or **external APIs**.

### 4.1 User and preferences (persistence)

- **Firebase Auth (optional):** Used when `FirebaseConfig.isEnabled` for sign-in; user id comes from Firebase.
- **User profile and preferences:** Stored in **SharedPreferences** under the key `user_data` (JSON). Written by `AuthProvider._saveUserData()` (and auth service when syncing). Contains:
  - watchlist, watchlistShows, likedMovies, dislikedMovies, likedShows, dislikedShows  
  - preferences (e.g. onboardingCompleted, selectedGenres, selectedPlatforms, tv_watched_episodes, tv_last_watched_at).
- **No remote DB:** Liked/disliked/watchlist are not sent to a custom server; they live in `user_data` (and in memory in `AuthProvider`).

### 4.2 Behavior and learning (persistence)

- **BehaviorTrackingService:** In-memory maps (e.g. `_skippedMovies` per user, view times, swipe sequences). **Not persisted** to disk; resets on app restart. Used to filter out skipped movies from recommendations and for behavior insights.
- **CollaborativeFilteringService:** Like/dislike matrices; persisted via **SharedPreferences** (`_saveToStorage` / `_loadFromStorage`).
- **MatrixFactorizationService:** Model data; persisted via **SharedPreferences** (`saveToStorage` / `loadFromStorage`).
- **AdaptiveWeightingService:** Strategy weights; uses **SharedPreferences**.
- **OnlineLearningService:** Update history; uses **SharedPreferences**.
- **ABTestingService:** User variant assignment; uses **SharedPreferences**.

So: **“database” for Discover = SharedPreferences (user_data + various service keys) + in-memory behavior.** No SQL, no Firestore, no custom API for storing likes.

### 4.3 Movie and show catalog (external API)

- **TMDB (The Movie Database):** Single source of truth for movie and show metadata and discovery.
  - **Endpoints used for Discover:**  
    - Movies: `getPopularMovies`, `getTrendingMovies`, `getTopRatedMovies`, `discoverMovies`, `getSimilarMovies`, `getMovieRecommendations`, `getMoviesByGenre`, `getMoviesByYear`, `searchMoviesByActor`, etc.  
    - Shows: analogous (e.g. `getPopularShows`, `discoverShows`, …).
  - **Streaming availability:** Filtering by platform uses `StreamingService.getMoviesOnMultiplePlatforms` (which may use TMDB watch providers or another source).
- **OMDb:** Optional enrichment (e.g. IMDb / Rotten Tomatoes ratings) for scoring; not required for basic loading.

---

## 5. Algorithms (how recommendations are chosen)

### 5.1 Branch: personalized vs curated

- **UserPreferenceAnalyzer.hasEnoughData(user):** Decides if the user has “enough” signal (e.g. enough likes + preferences).
  - **If true** → **personalized** path: `loadPersonalizedRecommendations`.
  - **If false** → **curated** path: `loadCuratedStarterMovies` (movies) or `loadCuratedStarterShows` (shows).

### 5.2 Curated path (movies)

- **Goal:** Diverse, high-quality starter set for cold users (or when not enough data).
- **Steps:**
  1. **TMDB discover:** Top-rated + popular (e.g. `discoverMovies` with `minRating: 7.0`, `sortBy: popularity.desc`), take 25.
  2. **TMDB popular:** `getPopularMovies`, merge without duplicates.
  3. **TMDB top-rated:** `discoverMovies` with `minRating: 7.5`, `sortBy: vote_average.desc`, take 15.
  4. **Genre diversity:** For key genres (Action, Drama, Comedy, etc.), if count < 3, fetch genre movies via `discoverMovies` and fill up to 3 per genre.
  5. **Sort:** Combined score (e.g. 60% rating, 40% normalized popularity), then light shuffle (chunks of 5).
  6. **Cap:** ~50 movies; if user provided, filter out liked, disliked, skipped, watchlist.
  7. **Apply filters** (genre, year, search if any) and set `_movies` / `_filteredMovies`, `_hasMorePages`.

### 5.3 Personalized path (movies)

- **Goal:** Rank candidates by relevance to the user and filters.
- **Steps:**
  1. **UserPreferenceAnalyzer.analyzePreferences(user)** → top genres, actors, directors, rating range, etc.
  2. **A/B variant:** e.g. `ABTestingService.getUserVariant(user.id)` (control / enhanced / embedding_focused); can change weights (e.g. matrix factorization weight).
  3. **Candidate gathering (multiple strategies):**
     - **Trending:** `getTrendingMovies`.
     - **Discover by preferences:** `discoverMovies` with genres (from swipe filters or top 3 preferences), min/max year, min rating from preferences.
     - **Top-rated:** `getTopRatedMovies`.
     - **Similar / recommended:** For up to 8 liked movies, `getSimilarMovies` + `getMovieRecommendations`, merge.
     - **Actors/directors:** If still < 30 candidates, search by preferred actors/directors.
     - **Genre fallback:** If still < 20, discover by 2 genres.
     - **Fallback:** Popular movies.
  4. **Exclusions:** Remove disliked, already liked, skipped (from BehaviorTrackingService), watchlist.
  5. **Quality filter:** e.g. drop very low rating or very low vote count (with exceptions for recent or popular).
  6. **Platform filter:** If swipe platforms selected, `StreamingService.getMoviesOnMultiplePlatforms`; if result too small, keep top 10 by score.
  7. **Scoring:** `_scoreMovies(movies, preferences, user)` (see below).
  8. **Diversity:** `_applyDiversityFilter` to reduce clustering.
  9. **Merge into list:** Replace or append (depending on `refresh` / `insertAtFront` / `backgroundLoad`), then `_applyFilters()` and notify.

### 5.4 Scoring (`_scoreMovies`)

- **Inputs:** Candidate movies, `UserPreferences` (from analyzer), current user, swipe mood/genre/platform filters.
- **Per-movie components (conceptually):**
  - Genre match (e.g. 30%): overlap with user’s top genres (and swipe genre filter).
  - Actor match (e.g. 20%): from TMDB credits, only if actor appears in cast.
  - Director match (e.g. 15%): from TMDB credits.
  - Rating match (e.g. 15%): fit in user’s preferred rating range or general “higher is better”.
  - Recency (e.g. 5%): newer years boosted.
  - Quality / temporal / cross-feature terms.
  - **Collaborative / embedding:** Optional matrix factorization or embedding similarity (weight can depend on A/B variant).
- **Output:** List of movies sorted by total score; top N (after diversity and platform filter) become the Discover list.

### 5.5 Shows

- **ShowProvider** mirrors the movie flow: curated (`loadCuratedStarterShows`) vs personalized (`loadPersonalizedRecommendations`), same filters (mood, genre, platform), scoring with `_scoreShows`, diversity and platform filtering, and the same buffer/preload logic (`checkAndPreload`, `_minBufferSize` 30, `_preloadThreshold` 25).
- Both Movies and Shows now use the same provider-driven hybrid strategy shape for Discover. The previous movie-only production orchestration path was retired.

### 5.6 Filters (mood, genre, platform)

- **Mood / Genre:** Stored in provider state (`_swipeMoods`, `_swipeSelectedGenres`). They affect:
  - **Personalized:** Which genres are sent to `discoverMovies` / `discoverShows` and how preferences are combined with mood genres.
  - **Scoring:** Mood can influence temporal/contextual scoring.
- **Platform:** `_swipeSelectedPlatforms`; after scoring, only movies/shows available on selected platforms are kept (with a minimum guaranteed count so the list is not empty).
- **Profile defaults:** Filters are **not** stored in the database; they live in the provider. On load, if the user has profile preferences (onboarding / edit preferences), they are applied when the filter state is empty: `user.preferences['selectedGenres']` → `setSwipeGenres`, and `user.preferences['selectedPlatforms']` → `setSwipePlatforms`, so the filter UI shows the user’s preferred genres and platforms as selected by default and they are used for suggestions.

---

## 6. End-to-end flow summary

| Step | What happens |
|------|-------------------------------|
| User opens Discover | SwipeScreen mounts → post-frame `_loadMovies()` (and buffer timer). |
| Auth + preferences | User data from AuthProvider (backed by SharedPreferences `user_data`). |
| Enough data? | UserPreferenceAnalyzer → personalized vs curated. |
| Curated | TMDB: popular + top-rated + discover by genre → merge, sort, filter, ~50 items. |
| Personalized | TMDB: trending + discover + top-rated + similar/recommendations + actors/directors → exclude disliked/liked/skipped/watchlist → score → diversity → platform filter. |
| Display | MovieProvider.filteredMovies / ShowProvider.filteredShows → CardSwiper. |
| Swipe | Like/dislike/skip/match → AuthProvider + BehaviorTrackingService + CollaborativeFilteringService + AdaptiveWeightingService + OnlineLearningService; optional background refresh. |
| Low buffer | checkAndPreload → load more (personalized or curated) in background, append to list. |
| Filter change | New mood/genre/platform on provider → _reloadMoviesWithFilters → same load logic with new filters. |

---

## 7. Files reference

| Area | File(s) |
|------|--------|
| Discover UI | `lib/screens/home/swipe_screen.dart` |
| Home & tabs | `lib/screens/home/home_screen.dart`, `lib/widgets/retro_cinema_bottom_nav.dart` |
| Movie data & algorithms | `lib/providers/movie_provider.dart` |
| Show data & algorithms | `lib/providers/show_provider.dart` |
| TMDB API | `lib/services/tmdb_service.dart` |
| User & preferences | `lib/providers/auth_provider.dart`, `lib/models/user.dart`, `lib/services/auth_service.dart` |
| Behavior | `lib/services/behavior_tracking_service.dart` |
| Preferences analysis | `lib/services/user_preference_analyzer.dart` |
| Collaborative / MF / learning | `lib/services/collaborative_filtering_service.dart`, `lib/services/matrix_factorization_service.dart`, `lib/services/adaptive_weighting_service.dart`, `lib/services/online_learning_service.dart` |
| A/B tests | `lib/services/ab_testing_service.dart` |
| Streaming filter | `lib/services/streaming_service.dart` |
| Cards | `lib/widgets/retro_cinema_movie_card.dart`, `lib/widgets/retro_cinema_show_card.dart`, `lib/widgets/match_success_screen.dart` |

---

*Document generated from codebase analysis. Last updated to reflect SwipeScreen as the Discover screen, unified Movie/Show recommendation strategy, deferred background buffering, and the use of TMDB + SharedPreferences (no separate backend database).*
