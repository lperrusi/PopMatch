# Recommendation Algorithm Improvements

**Date:** 2026-04-17  
**Status:** Implemented, no outstanding issues (`flutter analyze` passes clean)

---

## Context

Users reported recommendations felt generic and not personalized. Four problem areas were identified by exploring `lib/providers/movie_provider.dart`, `lib/providers/show_provider.dart`, `lib/services/user_preference_analyzer.dart`, and `lib/services/tmdb_service.dart`.

---

## Problems Solved

### 1. Cold-start ignored onboarding preferences
`loadCuratedStarterMovies` and `loadCuratedStarterShows` used a hardcoded genre list and a binary `hasEnoughData` gate at 3 likes. New users with onboarding genre selections (`user.preferences['selectedGenres']`) saw completely generic content.

### 2. TV show algorithm lagged far behind movies
`_scoreShows` was missing actor scoring (0%), director/creator scoring (0%), cross-feature interactions (0%), and used a flat `embeddingWeight = 0.5` stub. Shows also had only 4 discovery strategies vs. movies' 8.

### 3. Movie scoring weights were sub-optimal
Recency (5%) was over-weighted relative to its actual signal value. Cross-feature interactions (8%) were under-weighted. Experienced users (>10 likes) got no extra leverage from their reliable preferred-cast data.

### 4. Diversity filter removed quality outliers
Shows' `_applyDiversityFilter` had no top-tier bypass (unlike movies), used a window of 3 (too small), and could discard well-ranked content for the sake of genre variety. High-quality content outside a user's usual genres was never surfaced.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/services/user_preference_analyzer.dart` | Threshold 3→1; added `blendWeight()` |
| `lib/providers/movie_provider.dart` | Cold-start genre fix; weight tuning; experienced-user cast boost; novelty boost |
| `lib/providers/show_provider.dart` | Cold-start genre fix; full `_scoreShows` rewrite; strategies 5+6; diversity fix; novelty boost |
| `lib/services/tmdb_service.dart` | Added `getSimilarShows`, `getShowRecommendations`, `searchShowsByActor` |

---

## Detailed Changes

### `user_preference_analyzer.dart`
- `hasEnoughData`: threshold changed from `>= 3` to `.isNotEmpty` (1 like triggers personalization)
- `blendWeight(User user)`: new helper returning `(likedCount / 3.0).clamp(0.0, 1.0)` for future progressive blending

### `movie_provider.dart — loadCuratedStarterMovies()`
- Strategy 5 genre list: reads `user.preferences['selectedGenres']` (onboarding) → falls back to hardcoded defaults only if empty
- Sorting: +0.15 score boost for movies whose `genreIds` overlap with onboarding selections

### `movie_provider.dart — _scoreMovies()`
- Recency weight: 5% → 3%
- Cross-feature weight: 8% → 10%
- Experienced-user cast boost: `castBoost = 1.25` applied to actor (×0.18) and director (×0.12) components when `user.likedMovies.length > 10`
- Novelty boost: `+0.08` to final score for movies rated ≥7.8 whose genres don't overlap with user's top-3 genres

### `show_provider.dart — loadCuratedStarterShows()`
- Replaced single `getPopularShows` call with 3 batches:
  1. Popular shows
  2. Top-rated shows (`getTopRatedShows`)
  3. Genre-specific batch using onboarding genres via `discoverShows` (up to 5 genres, 5 shows each)
- Combined sort with +0.15 genre boost; cap at 60 shows before user filtering

### `show_provider.dart — _scoreShows()` (full rewrite)
- Added `_showCreditsSessionCache` (session map, same pattern as movie credits cache)
- Parallel credits fetch for top 20 shows (3s timeout, skip on fail)
- **New weight distribution** (old → new):
  - genre: 30% → 22%
  - actor: 0% → 15% (verified via TMDB show credits)
  - creator: 0% → 10% (matches Creator/Executive Producer/Showrunner in crew)
  - rating: 20% → 14%
  - recency: 10% → 6%
  - quality: 20% → 16%
  - temporal: 10% → 9%
  - cross-feature: 0% → 8% (new)
- Experienced-user cast boost: `castBoost = 1.25` when `user.likedShows.length > 10`
- Embedding: flat `0.5` stub replaced by `_computeShowEmbeddingScore()` — genre alignment (65%) + rating alignment (35%)
- Cross-features: timeless genre bonus, Sci-Fi+recent bonus, high-quality indicator
- Novelty boost: same `+0.08` for shows rated ≥7.8 outside user's top-3 genres

### `show_provider.dart — loadPersonalizedRecommendations()`
- **Strategy 5** (new): similar + recommended shows from top-3 liked shows via `getSimilarShows` + `getShowRecommendations` (parallel, 4s timeout); only on non-background loads
- **Strategy 6** (new): actor-based discovery via `searchShowsByActor` for top-3 `preferences.preferredActors`; only runs if `allRecommendations.length < 30`

### `show_provider.dart — _applyDiversityFilter()`
- Added top-20% tier bypass (same as movie provider's logic at lines 2048-2051)
- Window size: 3 → 5
- Overlap threshold kept at ≥3 consecutive overlaps

### `tmdb_service.dart` (new methods)
- `getSimilarShows(int showId)` → `/tv/{id}/similar`
- `getShowRecommendations(int showId)` → `/tv/{id}/recommendations`
- `searchShowsByActor(String actorName)` → person search → `/person/{id}/tv_credits`
- All three respect `_testMode` and `_hasConfiguredApiKey` guards

---

## Key Invariants to Preserve

- **`showItemId(id)` wrapping**: show IDs must always be wrapped with `showItemId()` when passed to `BehaviorTrackingService`, `CollaborativeFilteringService`, and `MatrixFactorizationService` — these share a single ID space with movies and the wrapper prevents collisions.
- **`_showCreditsSessionCache`** is in-memory only (not persisted). It resets on app restart, which is intentional.
- **`preferences.preferredActors`** in ShowProvider comes from the user's liked *movies* (via `UserPreferenceAnalyzer.analyzePreferences`), which analyzes `user.likedMovies`. This cross-media signal is intentional — if a user likes an actor in films they'll likely enjoy them in TV too. If show-specific actor preferences are needed in the future, `analyzePreferences` should be extended to also analyze `user.likedShows`.
- **`hasEnoughData` threshold at 1**: the curated path is now only used for users with zero likes. Any user who has liked at least one item gets the personalized path. If this proves too aggressive for new users (not enough signal), raise the threshold back toward 2–3 in `user_preference_analyzer.dart:hasEnoughData`.

---

## Testing Checklist

1. `flutter test test/` — all unit/widget tests pass
2. **Cold-start**: fresh user with Horror + Animation onboarding genres → first deck should show Horror/Animation prominently
3. **Show actor signal**: like 5 movies featuring a specific actor → Shows tab should surface shows with that actor
4. **Diversity**: like 10 Action movies → next batch should include 2+ non-Action titles
5. **Novelty**: high-rated (≥7.8) titles outside user's dominant genres should occasionally appear
