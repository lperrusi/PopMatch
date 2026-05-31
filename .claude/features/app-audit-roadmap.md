# App Audit Roadmap — Path to a Premium Recommendation + Social App

**Date:** 2026-05-29
**Status:** Roadmap approved; execution not yet started. Update phase checkboxes as items land.

---

## Context

A full audit of all 26 screens, 18 widgets, the services/providers layer, Cloud Functions,
docs, and the test suite. The app is functionally complete for core flows (auth, swipe,
detail, watchlist, favorites, profile, search) but carries real bugs, dead code, ephemeral
data, and stubbed "AI"/monetization features. This roadmap is **balanced and phased**:
P0 fixes → P1 finish → P2 premium. "Premium" spans four axes the product owner cares about:
**polished UX/quality, smarter recommendations, deeper social, monetization.**

Verified bug/dead-code details live in `.claude/features/known-issues.md`. The original
analysis lives at `~/.claude/plans/run-a-full-analyzes-functional-candy.md`.

---

## Phase 0 — Fix (stabilize; no new surface area)

Status: **all landed** (Phase 0 fixes 2026-05-29; UNDO fix 2026-05-30). Host test baseline
moved **117/124 → 129/120 pass/fail** (`flutter analyze` clean of new issues).

- [x] Swipe **UNDO** reliability (2026-05-30) — switched to immediate removal + re-insert on
      undo (Direction A); rapid consecutive swipes now advance correctly. Tests:
      `test/discover_undo_flow_test.dart`.
- [x] Move swipe button colors into `AppTheme.nopeRed`/`AppTheme.likeGreen`; dropped hardcoded hex.
- [x] `mounted` checks in swipe async callbacks — **verified already guarded**; the audit
      concern was a false positive, no change needed.
- [x] **Adaptive-weights persistence** — real `jsonEncode`/`jsonDecode` save/load in
      `adaptive_weighting_service.dart`; `loadWeights` wired once-per-user in both providers;
      `recordFeedback` re-attributed to the weight-aligned **dominant strategy** (the prior
      `recommendationStrategy` labels like `popular`/`genre_match` never matched the weight
      keys, so the learning loop could never fire). New round-trip test added.
- [x] Strip emoji debug logging from `login_screen.dart` (was `debugPrint`, not `print`).
- [x] Delete orphaned `recommendations_screen.dart` + its two test references (CLAUDE.md tab
      table corrected).
- [x] `friends_watching_screen.dart` — log + skip failed TMDB fetches, error state with Retry
      when all fail, paginated resolution (`_pageSize = 20`, next page as deck nears end).
- [x] Test-suite triage: fixed the `MovieDetailScreen`/`ShowDetailScreen` smoke cluster (missing
      l10n delegates + `SocialProvider` in the test harness). Onboarding "failures" turned out
      to be **cross-file test pollution** (they pass in isolation) — a separate test-infra task,
      not a code bug.

## Phase 1 — Finish (complete half-built features)

Status: code items landed 2026-05-30 on `phase1-finish`. Host baseline 129 → **140 pass / 120 fail**.

- [x] **Behavior-tracking persistence** — persists learning signals (sequences, interest,
      revisits, detail counts) + a **skip resurface counter** (`kSkipResurfaceLaunches = 3`):
      a skipped title is hidden for 3 launches then resurfaces. `initialize()` runs in
      `main.dart`. Tests: `test/behavior_tracking_service_test.dart`.
- [ ] **Firebase deployment completion** — *deferred (operational/user-side):* deploy functions,
      create `getFriendsFeed` Firestore indexes, set email secrets. Steps in the `firebase-setup`
      skill. (Verification-code expiry is already enforced **client-side**; true server-side
      enforcement is an architecture change — also deferred.)
- [x] OMDb external ratings — **wired into the feed** (bounded top-25, session-cached,
      key-guarded `enrichTopDeckWithExternalRatings`) + a small external-quality fold-in to the
      scoring quality term. Tests: `test/streaming_and_external_ratings_test.dart`.
- [x] Mood/genre/platform filter persistence on Discover (restored before first deck load).
      Tests: `test/discover_filter_persistence_test.dart`.
- [~] Social fallbacks — friends-feed + user-search already show names; `friends_watching` retry +
      pagination done in Phase 0. *Follow-request display name deferred* (`FollowEdge` has only
      `followerUid`; needs a profile fetch / CF + live backend).
- [x] Single shared streaming-platform source — both onboarding & edit-prefs use
      `StreamingPlatform.availablePlatforms` (+ `idFromNameOrId` normalizer); fixes the
      `YouTube Premium`→no-id bug and edit-prefs passing names to `setSwipePlatforms`.
- [x] Tests for filter persistence, behavior persistence, streaming source, OMDb fold-in (swipe
      outcomes covered by `test/discover_undo_flow_test.dart` from the UNDO fix).

## Phase 2 — Improve / premium (the four axes)

Status: started 2026-05-30 on `phase2-ux-detail` with the Polished-UX axis (detail screens).

- **Polished UX/quality:** refactor the 3.4k-line swipe screen and duplicated detail screens
  into shared components; consistent shimmer loading; jank pass.
  - [x] **Detail-screen de-dup (batch 1):** extracted `DetailVideosSection`/`RetroVideoCard`,
    `DetailCastCrewSection`/`DetailCastCrewCard`, and `DetailInlineStreamingAvailability` into
    `lib/widgets/detail/`. movie_detail 1964→1504, show_detail 1543→1097 (~430 net lines removed);
    behavior-preserving, smoke tests green, suite 140/120.
  - [ ] *Follow-up:* shared poster color-extraction mixin + action-button row (touch each screen's
    `State`/`Consumer` — left for a focused pass), then the swipe-screen decomposition, then a
    consistent-shimmer/jank pass.
- **Smarter recommendations:** recommendation **explanations** (flip the existing flag on with
  real "because you liked…" reasons); persisted collaborative filtering; honest rescoping or
  real TFLite for `DeepLearningService`; clean **"For You"** surface reusing `RecommendationsWidget`.
- **Deeper social:** shared/custom watchlists (finish `enhanced_watchlist_screen.dart`),
  match-with-friends, richer activity feed, social notifications via `flutter_local_notifications`.
- **Monetization:** turn "Remove Ads" into a real premium tier entry point; gate premium
  features (custom lists, explanations, ad-free) behind a `FeatureFlags`/entitlement check;
  add subscription plumbing as a dedicated sub-project.

---

## Verification (per change)

`flutter pub get` → `flutter analyze` (0 new issues) → `flutter test` (no regressions vs
baseline). Run `integration_test/` separately on a simulator (needs a device + seeded data,
no network). Round-trip test for adaptive weights; swipe/undo restorability test extending
`integration_test/swipe_deck_test.dart`. Manual smoke per `docs/TEST_PLAN.md`.
