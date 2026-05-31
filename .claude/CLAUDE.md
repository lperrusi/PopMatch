# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

### App Bootstrap (`lib/main.dart`)
Initializes Firebase → NotificationService → OMDbService, then runs `PopMatchApp`. Each service failure is caught individually so the app always launches. Root widget wraps everything in `MultiProvider` with 6 providers, then delegates auth-gated routing to `SplashScreen`.

### Navigation Flow
**Routing decision tree (driven by SplashScreen):**
1. Check `SharedPreferences["tutorial_completed"]` → show `TutorialScreen` if false
2. Check `AuthProvider.isAuthenticated` → go to `LoginScreen` if false
3. Check `userData.preferences['onboardingCompleted']` → show `OnboardingScreen` if false
4. Otherwise → `HomeScreen`

`HomeScreen` uses an **`IndexedStack`** — all 5 tabs are kept alive in memory simultaneously (no rebuild on tab switch). Tabs (see `lib/screens/home/home_screen.dart`): `SwipeScreen` (0), `SearchScreen` (1), `WatchlistScreen` (2), `FavoritesScreen` (3), `ProfileScreen` (4). Note: `RecommendationsScreen` is **not** a tab and is currently unreachable/orphaned — recommendations are surfaced through the swipe deck. See `.claude/features/known-issues.md`.

**Global tab navigation:** any screen can call `updateHomeScreenTab(index)` (top-level function that accesses `_homeScreenStateInstance`) to switch the active tab from anywhere in the app.

Navigation is imperative (`Navigator.pushReplacement` / `pushNamed`); custom transitions use `NavigationUtils.fastSlideRoute()` or `fastFadeRoute()` from `lib/utils/navigation_utils.dart`. No Router/Navigator 2.0.

### State Management (Provider)
Six `ChangeNotifierProvider`s, each with a matching service layer:

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Firebase Auth state, sign-in/up/out, email verification |
| `MovieProvider` | Movie data, caching, filtering |
| `ShowProvider` | TV show data |
| `RecommendationsProvider` | Hybrid recommendation orchestration |
| `StreamingProvider` | Streaming platform availability |
| `SocialProvider` | Friends, activity feed, social interactions |

### Services Layer (`lib/services/`)
Services are singletons (`.instance`) or stateless classes. Key groups:

- **Data APIs:** `tmdb_service.dart` (primary/canonical source), `omdb_service.dart` (supplemental IMDb/RT/Metacritic ratings only — not used to build title lists). YouTube trailer URLs are derived from TMDB video keys (`lib/models/video.dart`). Content strategy is TMDB-only; a hybrid second catalog (e.g. Trakt) is deferred — see `docs/CONTENT_SOURCES.md`.
- **Recommendations engine** — the real orchestrator is `MovieProvider.loadPersonalizedRecommendations()` (not `recommendations_service.dart`). Hybrid scoring: base score 50% (genre 40%, actor 25%, director 20%, rating 10%, recency 5%) + contextual 15% + embedding 15% + behavior 10% + collaborative 5% + deep learning 5%. `DeepLearningService` currently uses fallback scoring (no real ML model). Full algorithm detail: `docs/RECOMMENDATION_ALGORITHM.md`.
  - `adaptive_weighting_service.dart`, `collaborative_filtering_service.dart`, `contextual_recommendation_service.dart`, `movie_embedding_service.dart`, `deep_learning_service.dart`, `behavior_tracking_service.dart`, `recommendation_metrics_service.dart`
- **Firebase:** `firebase_config.dart` handles initialization with test-mode support (`FirebaseConfig.setTestMode(true)` disables Firebase in tests). Firebase Auth is optional — controlled by `FirebaseConfig.isEnabled`. Cloud Functions (`functions/index.js`) provide a `sendVerificationCode` function for email verification; the email service (Gmail/SMTP) must be configured and the function deployed separately.
- **Local persistence:** `shared_preferences` for all user data. `movie_cache_service.dart` caches full movie detail by ID (used by the "Recently liked" section to fetch movies not in the current swipe feed). See `docs/DATA_LOADING.md`.
- **A/B testing:** `ab_testing_service.dart` alongside `feature_flags.dart`.

### Data Models (`lib/models/`)
`Movie` and `TvShow` carry full metadata (cast, crew, videos, streaming platforms, ratings). `User` holds profile, preferences, watchlist, and likes. All models serialize to/from JSON for Firestore and API responses.

### Data Persistence
There is no custom backend database. All persistent state lives in:
- **`SharedPreferences["user_data"]`** (JSON) — watchlist, liked/disliked movies & shows, preferences (selectedGenres, selectedPlatforms, onboardingCompleted). Written by `AuthProvider._saveUserData()`. TMDB numeric IDs are the canonical key throughout; never key user data by external IDs.
- **`SharedPreferences` (various keys)** — ML/recommendation state: `CollaborativeFilteringService`, `AdaptiveWeightingService`, `MatrixFactorizationService`, `OnlineLearningService`, `ABTestingService`.
- **`BehaviorTrackingService`** — in-memory only (skipped movies, view times, swipe sequences). Resets on app restart.
- **Firebase Auth** — optional; only active when `FirebaseConfig.isEnabled` is true.

### Discover Screen (`lib/screens/home/swipe_screen.dart`)
`SwipeScreen` implements the Discover tab. Key non-obvious behaviours:
- **Curated vs personalized:** `UserPreferenceAnalyzer.hasEnoughData(user)` decides which path loads — requires **3+ liked movies**. Below that threshold, `loadCuratedStarterMovies()` runs; at or above, `loadPersonalizedRecommendations()` runs.
- **Buffer maintenance:** A timer fires every 3 seconds calling `checkAndPreload(user)`. Preload also triggers on swipe when remaining cards ≤ 25 (`hasMorePages` must be true). New movies are staged in `_pendingMovies` and flushed only when the visible stack is low, reducing mid-swipe pop-in.
- **UNDO (fixed 2026-05-30):** a swipe removes the card from the deck **immediately** (`removeMovie`/`removeShow`), so the keyed `CardSwiper` remounts onto the correct next card even on rapid consecutive swipes. The custom `DiscoverSwipeFeedback` banner offers a 4s one-tap UNDO that rolls back the auth like/dislike and re-inserts the card at the front via `MovieProvider.reinsertSwipedMovieAtFront` / `ShowProvider.reinsertSwipedShowAtFront` (not the unreliable `controller.undo()`). Covered by `test/discover_undo_flow_test.dart`. Background: `docs/DISCOVER_UNDO_PRODUCT_FIX.md`.
- Movies and shows use **separate** `CardSwiperController`s so undo targets the correct deck.

### Theme
Single custom "Retro Cinema" theme (dark by default). Defined in `lib/utils/theme.dart`.

Key named color constants on `AppTheme`:
- `cinemaRed` (`0xFF2E1403`) — primary red, app bar backgrounds
- `popcornGold` (`0xFFF6C344`) — accent, tab indicators, badges
- `filmStripBlack` (`0xFF1A1A1A`) — primary dark background
- `creamyWhite` (`0xFFF7F3E8`) — primary text on dark backgrounds
- `sepiaBrown` (`0xFF8B6914`) — secondary accent
- `vintagePaper` (`0xFFF2E8D9`) — light theme background

Font families: **BebasNeue** (headers/titles), **Lato** (body text). Always use `Theme.of(context)` or `AppTheme` constants — never hardcode hex values.

## Verification Workflow (ALWAYS Follow)
1. Generate changes → Run `flutter analyze`, `flutter test`, `flutter pub get`.
2. Simulate key flows: auth gate, swipe buffer (preload 25+), tab switch via `updateHomeScreenTab`.
3. Screenshot diffs; fix errors autonomously. Ask for approval only on non-trivial refactors.
4. Propose commit message: "feat: [description] (#issue)".

## Prompting Rules
- Reference TMDB IDs only; prioritize `MovieProvider.loadPersonalizedRecommendations()`.
- For recs: Output scoring breakdown (base/contextual/etc.).
- Errors: Use SnackBar with `cinemaRed`/`popcornGold`; log to console.

## Testing Commands
- Unit: `flutter test`
- Widget: `flutter test --coverage`
- E2E: `flutter drive` (if integration_test/ setup)