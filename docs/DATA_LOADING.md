# Data loading: MovieProvider vs MovieCacheService

This doc explains how movie (and show) data is loaded in the app and why the Profile “Recently liked” lists can be incomplete.

---

## MovieProvider

**Role:** In-memory list of movies used for **recommendations and swipe feed**.

- **What it holds:** A single list `movies` (and `filteredMovies`) that is filled by:
  - Discovery/trending/top-rated API calls
  - User preferences (genres, platforms, mood)
  - Filtering (liked/disliked/skipped/watchlist removed)
- **When it’s filled:** When the user opens the swipe screen, “For You”, or when recommendations are refreshed. It keeps a **buffer** (e.g. 30+ movies) and preloads more as the user swipes.
- **Scope:** Only movies that have been **loaded into this feed in the current (or recent) session**. It is **not** a full copy of “all movies the user has ever liked.”

So **MovieProvider.movies** = “movies currently in the recommendation pipeline,” not “all liked movies.”

---

## MovieCacheService

**Role:** **Cache of full movie details by ID** (for detail screen and anywhere you need one movie by ID).

- **What it holds:** A map of `movieId → Movie` (and timestamps). Each entry is the **full** movie (from `getMovieDetailsWithCredits`).
- **How it’s used:**
  - **Preload:** Before navigating to a detail screen, call `preloadMovieDetails(movieId)` so the detail screen opens quickly.
  - **Get by ID:** `getMovieDetails(movieId)` returns from cache or loads from TMDB and caches.
  - **Sync check:** `getCachedMovie(movieId)` returns the movie only if it’s already cached (no network).
- **Scope:** Any movie you’ve ever requested by ID (up to cache size/expiry). **Not** tied to the recommendation feed.

So **MovieCacheService** = “get or load **any** movie by ID and reuse it.”

---

## Why “Recently liked” (movies or shows) can be incomplete

- **Profile “Recently liked”** uses:
  - **Movies:** `MovieProvider.movies` filtered by `user.likedMovies` (IDs).
  - **Shows:** `ShowProvider.shows` filtered by `user.likedShows` (IDs).

So it only shows liked items that **are currently in the provider’s list**. If the user liked a movie or show that never appeared in this session’s feed (or was loaded long ago and evicted), it **won’t** appear in “Recently liked,” even though it’s in `user.likedMovies` / `user.likedShows`.

---

## Making “Recently liked” complete (implemented)

The Profile screen now shows **all** recently liked movies and shows (first 5 in list order):

- **Movies:** `_RecentLikedMoviesSection` uses `MovieProvider.movies` when the movie is already there; otherwise it calls **`MovieCacheService.instance.getMovieDetails(movieId)`** to load by ID and caches the result. Tiles appear in the order of `user.likedMovies`; a loading placeholder is shown until the fetch completes.
- **Shows:** `_RecentLikedShowsSection` uses `ShowProvider.shows` when the show is already there; otherwise it calls **`TMDBService.getShowDetails(showId)`** to load by ID. Same ordering and loading placeholder behavior.

So the “Recently liked” list is complete (up to 5 items) and no longer depends on the current recommendation buffer.
