# Known Issues — Verified Audit (2026-05-29)

Living list of confirmed bugs / dead code found during the full app audit. Each was verified
by reading the code (not just docs). Remove an entry when it's fixed; keep this honest so
future sessions don't trust stale assumptions.

---

## Bugs

### 1. Swipe UNDO is unreliable
`lib/screens/home/swipe_screen.dart` remounts `CardSwiper` on every swipe (key bump, ~`:1676`),
which clears the library's internal undo history. The "Swipe recorded / UNDO" SnackBar often
cannot visually restore the previous card even when provider state is reverted. No undo is
available on the last card in a deck. Fix approaches: `docs/DISCOVER_UNDO_PRODUCT_FIX.md`
(recommended: Direction C deferred-removal + Direction A data restoration).

### 2. Adaptive weights never persist — FIXED (2026-05-29)
~~`_saveWeights` wrote `Map.toString()` and `loadWeights` was an empty stub.~~ Now uses
`jsonEncode`/`jsonDecode` with validation; `loadWeights` is wired once-per-user in both
providers. Also found that `recordFeedback` *was* being called from the swipe handler but with
discovery labels (`popular`/`top_rated`/`genre_match`) that never matched the weight keys, so
`_updateWeightsFromFeedback` (which needs ≥10 feedbacks for **every** weight key) could never
fire — now re-attributed to the weight-aligned dominant strategy tracked at scoring time.
Round-trip test: `test/adaptive_weighting_service_test.dart`.

### 3. Behavior tracking is in-memory only
`lib/services/behavior_tracking_service.dart` has no save/load — view times, revisits, swipe
speed, and swipe sequences reset on app restart. The 10% "behavior" recommendation signal is
therefore effectively single-session.

### 4. OMDb external ratings are dead code
`lib/providers/movie_provider.dart:1581 _enhanceMoviesWithExternalRatings()` is marked
`// ignore: unused_element` — never called. OMDb (IMDb/RT/Metacritic) scores never enter the
scoring pipeline. Decide: wire it in (behind the existing OMDb key check) or delete it.

### 5. `RecommendationsScreen` is orphaned dead code — FIXED (2026-05-29)
~~`lib/screens/home/recommendations_screen.dart` was unreferenced (index-1 tab is `SearchScreen`).~~
Deleted, along with its references in `test/home_tab_smoke_screens_test.dart` and
`integration_test/screenshot_test.dart`. CLAUDE.md tab table corrected.

### 6. `DeepLearningService` is a stub
`lib/services/deep_learning_service.dart:19,82` — no TFLite model is loaded; `getPredictionScore`
returns a rule-based fallback. It still contributes a 5% weight, so the blend is honest only if
this is rescoped (rename + redistribute weight) or replaced with a real model.

### 7. `friends_watching_screen.dart` swallows errors / no pagination — FIXED (2026-05-29)
~~Empty catch on TMDB fetch; loaded all friend items at once.~~ Now logs + skips failed
fetches, shows an error state with Retry when the first page fully fails, and resolves in
pages of 20 (next page loads as the deck nears its end).

### 8. Mood filters reset on restart
Discover mood selections are not persisted to SharedPreferences. *(Phase 1.)*

### 9. Email verification code expiry not enforced server-side
`functions/index.js` documents a 15-minute expiry but doesn't validate it on the server. *(Phase 1.)*

### 10. Debug logging left in auth — FIXED (2026-05-29)
~~`login_screen.dart` had emoji `debugPrint` statements.~~ Removed.

### 11. Hardcoded colors in swipe buttons — FIXED (2026-05-29)
~~`swipe_screen.dart` defined `_kNopeColor`/`_kLikeColor` as raw hex.~~ Moved to
`AppTheme.nopeRed`/`AppTheme.likeGreen`.

### 12. Swipe async callbacks — NOT AN ISSUE (verified 2026-05-29)
The audit flagged possible missing `mounted` checks after `Future.delayed`/await in
`swipe_screen.dart`. On inspection every such callback is already guarded — no change needed.

---

## Stubbed / incomplete features

- **Remove Ads** (`lib/screens/home/profile_screen.dart:~306-323`) — "Coming Soon" dialog;
  entry point for a future monetization tier.
- **`enhanced_watchlist_screen.dart`** — custom lists/tags largely stubbed and not wired into
  navigation.
- **Recommendation explanations** — flag exists but is always false; no "because you liked…" UI.
- **Hardcoded streaming-platform lists** — duplicated in onboarding and
  `edit_preferences_screen.dart` instead of one shared source.

---

## Deployment gaps (Firebase partially configured)

- Cloud Functions must be deployed; `getFriendsFeed` needs **Firestore composite indexes**
  (`functions/index.js:503-508` already handles the missing-index error).
- Email secrets (`GMAIL_*` / `SMTP_*`) must be set for `sendVerificationCode` (falls back to
  console logging otherwise). See the `firebase-setup` skill.

---

## Tech debt (not bugs, but noted)

- `home_screen.dart` cross-tab nav uses a static mutable `_homeScreenStateInstance`.
- `swipe_screen.dart` is ~3,445 lines with near-duplicate movie/show handlers.
- `movie_detail_screen.dart` and `show_detail_screen.dart` are near-duplicate implementations.
- Possibly unused deps: `cloud_firestore` (social only), `crypto`, `intl`, `http` vs `dio` overlap.
- Test baseline: **117 pass / 124 pre-existing fail** — failures concentrated in onboarding
  persistence and `ShowDetailScreen` widget lookup.
