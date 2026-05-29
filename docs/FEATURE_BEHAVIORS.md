# PopMatch — Feature Behaviors Reference

> This document is the canonical reference for how every user-facing feature in PopMatch is **supposed to behave**. It is intended to inform future implementation work, bug triage, and test planning. Update it whenever a feature changes significantly.

---

## Table of Contents

1. [Authentication Flows](#1-authentication-flows)
2. [Discover / Swipe Screen](#2-discover--swipe-screen)
3. [Search / Recommendations Screen](#3-search--recommendations-screen)
4. [Watchlist Screen](#4-watchlist-screen)
5. [Favorites Screen](#5-favorites-screen)
6. [Profile Screen & Sub-Screens](#6-profile-screen--sub-screens)
7. [Movie & Show Detail Screens](#7-movie--show-detail-screens)
8. [Match Success Overlay](#8-match-success-overlay)
9. [Social Features](#9-social-features)
10. [Onboarding & Mood Selection](#10-onboarding--mood-selection)
11. [Data Persistence Reference](#11-data-persistence-reference)
12. [Known Issues & Limitations](#12-known-issues--limitations)

---

## 1. Authentication Flows

### 1.1 Login

**Screen:** `lib/screens/auth/login_screen.dart`

| Field | Validation |
|-------|-----------|
| Email | Required, valid email format |
| Password | Required, non-empty |

**Success path:**
- `onboardingCompleted == true` → `HomeScreen`
- `onboardingCompleted == false` → `OnboardingScreen`

**Failure path:** Snackbar with red background + gold text describing the error.

**State managed by:** `AuthProvider` → `_signIn()` → calls `AuthService.signIn()`.

---

### 1.2 Register

**Screen:** `lib/screens/auth/register_screen.dart`

| Field | Validation |
|-------|-----------|
| Email | Required, valid format |
| Display Name | Required, non-empty |
| Password | Required |
| Confirm Password | Must match Password |

**Success path (Firebase enabled):** → `EmailVerificationScreen`
**Success path (Firebase disabled):** → `OnboardingScreen` or `HomeScreen`

---

### 1.3 Email Verification

**Screen:** `lib/screens/auth/email_verification_screen.dart`

- Polls Firebase for `emailVerified` status
- "Resend email" triggers new verification email via Cloud Function `sendVerificationCode`
- "Continue" enabled once verified
- Cloud Function is optional; if not deployed, code is logged to Flutter console only

---

### 1.4 Forgot Password

**Screen:** `lib/screens/auth/forgot_password_screen.dart`

- Sends password reset email via `AuthProvider.sendPasswordResetEmail()`
- Shows success confirmation inline (no navigation)

---

## 2. Discover / Swipe Screen

**Screen:** `lib/screens/home/swipe_screen.dart`

### 2.1 Content Loading Strategy

```
hasEnoughData (≥3 liked movies)?
  YES → loadPersonalizedRecommendations()
  NO  → loadCuratedStarterMovies()
```

`hasEnoughData` is evaluated by `UserPreferenceAnalyzer.hasEnoughData(user)`.

**Personalized path** runs in `MovieProvider.loadPersonalizedRecommendations()`:
1. `strategy.trending` — trending from TMDB
2. `strategy.topRatedMovies` — top-rated catalog
3. `strategy.discoverMovies` — TMDB discover endpoint with user genre/platform prefs
4. `strategy.contentSimilarityDiscovery` — titles similar to liked items
5. `strategy.embeddingBasedFromLikedMovies` — embedding similarity
6. Scoring loop: base 50% + contextual 15% + embedding 15% + behavior 10% + collaborative 5% + deep learning 5%
7. Deduplication and diversity application

**Buffer maintenance:**
- Timer fires every 3 seconds → `checkAndPreload(user)`
- Preload also triggered when visible cards ≤ 25 AND `hasMorePages == true`
- New titles staged in `_pendingMovies`, flushed only when visible stack is low

---

### 2.2 Swipe Gestures & Outcomes

| Gesture | Action | State Change |
|---------|--------|-------------|
| Swipe Right | Like | Added to `user.likedMovies` |
| Swipe Left | Dislike | Added to `user.dislikedMovies` |
| Swipe Up | Match | Added to `user.likedMovies` + `user.watchlist` → triggers `MatchSuccessScreen` |
| Swipe Down | Skip | Added to `BehaviorTrackingService.skippedMovies` (session only, not persisted) |

All right/left/up swipes trigger the "Swipe recorded / UNDO" snackbar (2-second window). Down swipes do NOT show the snackbar (skip is silent).

---

### 2.3 Undo Behavior

**Expected:** Tapping UNDO within 2 seconds restores the card and reverts the state change.

**Actual (known bug):** `CardSwiper` is remounted on each swipe (key changes with list mutation), which clears its internal undo history. The undo may fail to restore the card visually even when state is correctly reverted.

**Status:** Documented issue. Three fix approaches in `docs/DISCOVER_UNDO_PRODUCT_FIX.md`.

No undo snackbar is shown when swiping the **last card** in the deck.

---

### 2.4 Filters

**Filter sheet** opens via the tune icon (top-right of screen). A gold badge appears on the icon when any filter is active.

| Filter Type | Multi-select? | Persistence |
|-------------|--------------|-------------|
| Mood | Yes (8 moods) | Session only (reset on restart) |
| Genre | Yes | Session only |
| Streaming Platform | Yes | Session only |

Applying filters closes the sheet and reloads content with the new filter set.

Platform filter edge case: if selected platforms yield fewer than the minimum card count, the filter relaxes to keep a usable deck.

---

### 2.5 Movies vs Shows Tabs

- Separate `CardSwiperController` instances for movies and shows
- Separate data load and state tracking
- Switching tabs preserves state of each deck independently

---

## 3. Search / Recommendations Screen

**Screen:** `lib/screens/home/recommendations_screen.dart`  
**Nav tab label:** "Search"

> Note: Despite the nav label, this screen is a hybrid search + recommendations screen.

### 3.1 Search

- Debounced 350ms after last keystroke
- Searches movies AND shows simultaneously via `TMDBService`
- Results rendered in a grid with poster + title + rating
- Recent searches saved to `SharedPreferences` (max ~5 items)
- Tap recent search item → re-runs that search

### 3.2 Recommendations

- "For You" section shows personalized recommendations from `RecommendationsProvider`
- Filter pills allow toggling recommendation types
- Horizontal scroll carousels per category

### 3.3 Lazy Loading

- Scrolling near the bottom (within ~200px) triggers the next page load
- Loading indicator appears at bottom during fetch

---

## 4. Watchlist Screen

**Screen:** `lib/screens/home/watchlist_screen.dart` (or `enhanced_watchlist_screen.dart`)

### 4.1 Data Source

`AuthProvider.userData.watchlist` (movie IDs) and `userData.watchlistShows` (show IDs).

Lazy-loaded in batches of 25. Full movie/show details fetched from `MovieCacheService` (if cached) or `TMDBService`.

### 4.2 Item Actions

| Action | How to trigger | Result |
|--------|---------------|--------|
| Open detail | Tap card | Opens `MovieDetailScreen` / `ShowDetailScreen` |
| Remove | Swipe card right OR action menu | Removes from watchlist; confirmation snackbar |
| Mark as Liked | Action menu | Moves to Favorites; removes from watchlist |
| Mark as Disliked | Action menu | Removes from watchlist; records dislike |

### 4.3 Tabs

Movies and Shows are separate tabs, sorted newest-added first.

---

## 5. Favorites Screen

**Screen:** `lib/screens/home/favorites_screen.dart`

### 5.1 Data Source

`AuthProvider.userData.likedMovies` and `userData.likedShows`.

Lazy-loaded in batches of 25.

### 5.2 Sort Options

| Option | Description |
|--------|-------------|
| Title A-Z / Z-A | Alphabetical |
| Year Newest / Oldest | By release year |
| Rating High / Low | By TMDB vote average |
| (Shows only) Watching Status | Groups by watching status |

Sort is applied client-side after loading.

### 5.3 Bulk Delete Mode

- Tap the delete icon (header right) to toggle delete mode
- Checkboxes appear on each card
- Tap cards to select/deselect
- Tap confirm button to remove all selected; shows count in confirmation snackbar
- No undo for bulk delete

### 5.4 Long-Press Actions

| Action | Result |
|--------|--------|
| Dislike | Moves to disliked; removes from Favorites |
| Remove from Favorites | Removes only (no dislike recorded) |
| View Details | Opens detail screen |

---

## 6. Profile Screen & Sub-Screens

**Screen:** `lib/screens/home/profile_screen.dart`

### 6.1 Profile Stats

Stats are computed live from `AuthProvider.userData`:

| Stat | Source |
|------|--------|
| Watchlist count | `watchlist.length + watchlistShows.length` |
| Liked Movies | `likedMovies.length` |
| Liked Shows | `likedShows.length` |

Avatar: Cached network photo from Google/Apple auth, or first letter of email as fallback.

### 6.2 Edit Preferences

**Screen:** `lib/screens/home/edit_preferences_screen.dart`

Two-page flow:
1. **Genres** — multi-select grid; TMDB genre IDs stored
2. **Platforms** — multi-select toggles; platform name strings stored

Saved to `SharedPreferences` AND `AuthProvider.userData.preferences`:
- `selectedGenres`: List of int genre IDs
- `selectedPlatforms`: List of String platform names

Changes update `MovieProvider` and `ShowProvider` filter defaults immediately.

### 6.3 Notifications Settings

**Screen:** `lib/screens/home/notifications_screen.dart`

All toggles saved immediately to `SharedPreferences`. Keys: `notificationsEnabled`, `matchReminders`, `newRecommendations`, `friendRequests`, `followAccepted`.

### 6.4 Privacy Settings

**Screen:** `lib/screens/home/privacy_screen.dart`

| Setting | Backend |
|---------|---------|
| Usage data collection | `SharedPreferences["usageDataEnabled"]` |
| Allow followers | `SocialService.updateSocialPrivacy()` |
| Share Likes | `SocialService.updateSocialPrivacy()` |
| Share Watchlist | `SocialService.updateSocialPrivacy()` |
| Share Activity | `SocialService.updateSocialPrivacy()` |
| Delete account | `AuthProvider.deleteAccount()` — requires confirmation dialog |

### 6.5 Help & Support

**Screen:** `lib/screens/home/help_support_screen.dart`

Static FAQ (expand/collapse). Email button uses `url_launcher` to open default mail client.

### 6.6 Logout

Calls `AuthProvider.signOut()`. Clears SharedPreferences auth state. Navigates to `LoginScreen` via `Navigator.pushReplacement`.

---

## 7. Movie & Show Detail Screens

**Screens:** `lib/screens/movie_detail_screen.dart`, `lib/screens/show_detail_screen.dart`

### 7.1 Loading Pattern

```
Frame 1: Render basic data passed from previous screen (title, poster, rating)
+300ms: Extract poster color for dynamic text color
+600ms: Load full cast & crew
+1500ms: Load streaming availability
```

Full details are fetched from `TMDBService.getMovieDetailsWithCredits()` (or shows equivalent). `MovieCacheService` provides instant load if the item was previously viewed.

### 7.2 Content Sections

| Section | Source | Fallback |
|---------|--------|---------|
| Poster / Backdrop | TMDB image CDN (CachedNetworkImage) | Placeholder icon |
| Title, year, runtime | TMDB metadata | — |
| Synopsis | TMDB overview | "No description available" |
| Cast & Crew | `TMDBService.getMovieCredits()` | Empty section, no error |
| Genres | TMDB genre list | Empty |
| Streaming availability | `StreamingProvider` | "Not available" |
| Trailers/Videos | `TMDBService.getMovieVideos()` | Section hidden |
| Ratings | TMDB vote average + `OMDbService` (RT/Metacritic) | TMDB rating only |

### 7.3 User Actions

| Action | Button | Result |
|--------|--------|--------|
| Like / Unlike | Heart icon | Toggles `user.likedMovies`; updates AuthProvider |
| Watchlist toggle | Bookmark icon | Adds/removes from `user.watchlist` |
| Share | Share icon | Opens OS share sheet |
| Play trailer | Play button on video thumbnail | Opens in-app video player |

### 7.4 Shows — Additional Fields

- Network (e.g., "HBO")
- Number of seasons / episodes
- Status: Returning Series / Ended / In Production / Cancelled
- Next episode air date (if available)

---

## 8. Match Success Overlay

**Widget:** `lib/widgets/match_success_screen.dart`

Triggered by swipe-up (Match) on the Discover screen.

### 8.1 Animation Timeline (single `AnimationController`, 2.1s total)

| Interval | Element |
|----------|---------|
| 0.0–0.3 | Background fade in |
| 0.1–0.4 | Heart icon bounces in |
| 0.2–0.5 | "It's a Match!" headline slides up |
| 0.3–0.7 | Poster card slides up |
| 0.5–0.8 | Movie meta info slides up |
| 0.7–1.0 | Action buttons slide up |

### 8.2 Actions

| Button | Action |
|--------|--------|
| Continue | `Navigator.pop()` — closes overlay |
| View Details | Navigates to `MovieDetailScreen`; overlay stays in back-stack |
| Add to Watchlist | Calls `AuthProvider.addToWatchlist()`; pops overlay with snackbar |

Auto-dismiss: Timer configured per call site (optional).

---

## 9. Social Features

**Provider:** `lib/providers/social_provider.dart`  
**Service:** `lib/services/social_service.dart`  
**Feature flag:** `SOCIAL_UI_ENABLED` (dart-define from `.env`)

### 9.1 Social Hub

**Screen:** `lib/screens/home/social_hub_screen.dart`

| Feature | API method |
|---------|-----------|
| Search users | `SocialProvider.searchUsers(query)` |
| Send follow request | `SocialProvider.sendFollowRequest(userId)` |
| Accept follow request | `SocialProvider.respondToFollowRequest(id, accept: true)` |
| Decline follow request | `SocialProvider.respondToFollowRequest(id, accept: false)` |

Incoming requests polled from `SocialProvider.incomingRequests`.

### 9.2 Friends Watching Feed

**Screen:** `lib/screens/home/friends_watching_screen.dart`  
**Feature flag:** `FRIENDS_FEED_ENABLED`

- Loads friend activity via `SocialProvider.loadFriendsFeed()`
- Resolves each item to full movie/show details via TMDBService
- Deduplicates by `(type, tmdbId)`
- Failed resolutions are silently skipped (no error shown per item)
- Empty state shown if no friend activity

---

## 10. Onboarding & Mood Selection

### 10.1 Onboarding (3 pages)

**Screen:** `lib/screens/onboarding/onboarding_screen.dart`

| Page | Content | Action |
|------|---------|--------|
| 1 | Welcome + app description | Tap Next |
| 2 | Genre multi-select grid | Tap Continue |
| 3 | Streaming platform toggles | Tap Finish |

On Finish:
```dart
SharedPreferences.setString('selectedGenres', jsonEncode(selectedGenreIds))
SharedPreferences.setString('selectedPlatforms', jsonEncode(selectedPlatforms))
AuthProvider.userData.preferences['onboardingCompleted'] = true
```
Navigates to `HomeScreen`.

### 10.2 Mood Selection

**Screen:** `lib/screens/home/mood_selection_screen.dart`

8 moods: Happy, Sad, Excited, Romantic, Relaxed, Mysterious, Nostalgic, Inspired.

Selected mood populates `MovieProvider.swipeMoods` (list). Affects genre weighting in recommendation scoring.

**Not persisted** — resets on app restart.

---

## 11. Data Persistence Reference

| Data | Storage | Key / Location |
|------|---------|---------------|
| User profile, likes, watchlist | `SharedPreferences` | `user_data` (JSON) |
| Genre preferences | `SharedPreferences` | inside `user_data.preferences.selectedGenres` |
| Platform preferences | `SharedPreferences` | inside `user_data.preferences.selectedPlatforms` |
| Onboarding status | `SharedPreferences` | inside `user_data.preferences.onboardingCompleted` |
| Tutorial completion | `SharedPreferences` | `tutorial_completed` |
| Notification toggles | `SharedPreferences` | individual keys per toggle |
| ML/recommendation state | `SharedPreferences` | various keys (CollaborativeFiltering, AdaptiveWeighting, etc.) |
| A/B test assignments | `SharedPreferences` | `ab_testing_service` |
| Movie detail cache | `MovieCacheService` (in-memory + SharedPreferences) | keyed by TMDB movie ID |
| Skipped movies (session) | `BehaviorTrackingService` (in-memory) | lost on app restart |
| Swipe filters (mood, genre, platform) | In-memory (`MovieProvider` / `ShowProvider`) | lost on app restart |
| Auth session | Firebase Auth (if enabled) | n/a |

**Canonical ID:** TMDB numeric ID is the key throughout all user data stores. Never key by OMDb/Trakt/other external IDs.

---

## 12. Known Issues & Limitations

| # | Area | Issue | Docs |
|---|------|-------|------|
| 1 | Discover | Undo snackbar may fail to restore card (CardSwiper remount) | `DISCOVER_UNDO_PRODUCT_FIX.md` |
| 2 | Discover | No undo on last card in deck | — |
| 3 | Discover | Mood filters reset on app restart | — |
| 4 | Discover | Platform filter relaxes minimum count when too restrictive | — |
| 5 | Search | Nav tab labeled "Search" but opens RecommendationsScreen | — |
| 6 | Detail | Color extraction has 2s timeout; may fall back to dark theme | — |
| 7 | Detail | TMDB IDs 1–10 (very old entries) return 404 in some endpoints | — |
| 8 | Social | Friend feed and social interactions may be incomplete | — |
| 9 | Auth | Email verification only active with Firebase enabled | `firebase-setup` skill |
| 10 | DeepLearning | `DeepLearningService` uses fallback scoring (no real ML model) | `RECOMMENDATION_ALGORITHM.md` |
