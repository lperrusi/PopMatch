# Discover undo: product fix sketch

This document sketches how to make **UNDO** from the “Swipe recorded” SnackBar reliably restore the previous card **and** keep `MovieProvider` / `ShowProvider` / auth state aligned. Widget-level behavior of the SnackBar itself lives in [`lib/widgets/discover_undo_snackbar.dart`](../lib/widgets/discover_undo_snackbar.dart).

## Problem

1. **List mutation before undo** — On swipe completion, `removeMovie` / `removeShow` runs immediately, so `filteredMovies` / `filteredShows` no longer contain the swiped item.
2. **`CardSwiper` remount** — The swiper uses `key: ValueKey(filtered*.first.id)` so that, after removal, indices line up with the shorter list. That **recreates** the `CardSwiper` state, so internal `_directionHistory` is cleared and `CardSwiperController.undo()` often has **nothing to undo**.
3. **`onUndo` vs data** — `_onMoviesUndo` / `_onShowsUndo` read `filteredMovies[restoredFrontIndex]` after the removal; the indices refer to the **new** front item, not the swiped one, unless the row is restored first.

So the SnackBar can appear (gating logic is correct), but **UNDO does not reliably rewind the deck** in production.

## Direction A — Restore row, then undo (minimal data fix)

Keep the current swiper + key strategy, but **before** `CardSwiper` processes undo:

1. Track the last swiped **movie/show** (and direction) when calling `removeMovie` / `removeShow`.
2. In `_onMoviesUndo` / `_onShowsUndo`, **if** the swiped id is not already in the list, **insert it back** at `restoredFrontIndex` (usually `0`) via new provider APIs, e.g. `insertMovieAtIndexForUndo(Movie m, int index, {User? user})`, then run existing auth rollback (remove like/dislike, etc.) using the correct `Movie` / `TvShow`.

**Pros:** Localized to providers + undo handlers; no change to `flutter_card_swiper` usage beyond ordering.  
**Cons:** Still need a **non-remounted** swiper **or** a controller that can undo after remount — so this pairs with Direction B or C.

## Direction B — Stable swiper identity (keep undo stack)

Stop remounting `CardSwiper` on every front-id change, **or** remount only when the deck is refilled from the network, not on every swipe.

Options:

- Use a **stable `Key`** on `CardSwiper` (e.g. tab-scoped `ObjectKey` or `_moviesSwiperKey` that only changes on refill), **and** ensure `cardsCount` + `cardBuilder` indices stay consistent with `removeMovie` (may require aligning swiper index with “logical” deck — same problem the current `ValueKey(first.id)` was solving).
- Or **defer** `removeMovie` until the SnackBar is dismissed or UNDO is impossible (timer), so the list length does not change until after undo window — larger behavioral change.

**Pros:** `CardSwiper` internal undo history can survive.  
**Cons:** Requires careful index/sync design; regression risk on “wrong card” bugs the current key fixed.

## Direction C — Defer removal until SnackBar expires or UNDO

Do **not** remove from `filteredMovies` in `onSwipe`; only update auth/telemetry. Remove the row when:

- User taps away / SnackBar times out (2s), or  
- User swipes the next card (commit previous), or  
- User navigates away.

Undo then removes the SnackBar and calls `controller.undo()` **while** the list still contains the item — swiper and list stay aligned.

**Pros:** Matches mental model “undo = same session.”  
**Cons:** Touches swipe pipeline, analytics timing, and edge cases (app backgrounded, rapid swipes).

## Recommended phased approach

1. **Phase 1 (data):** Add `Movie` / `Show` restore helpers + last-swiped tracking; make `_onMoviesUndo` / `_onShowsUndo` restore the row **before** reading `filteredMovies[restoredFrontIndex]` for auth rollback.
2. **Phase 2 (swiper):** Either stabilize `CardSwiper` `key` + verify index invariants **or** adopt deferred removal (Direction C) for the undo window only.
3. **Phase 3 (tests):** Integration test: non-last swipe → SnackBar → UNDO → previous title visible; last card → no SnackBar (already covered in integration tests).

## References

- SnackBar UI + action: [`showDiscoverUndoSnackBar`](../lib/widgets/discover_undo_snackbar.dart)
- Widget tests (isolated SnackBar + UNDO action): [`test/discover_undo_snackbar_test.dart`](../test/discover_undo_snackbar_test.dart)
- Swipe completion + gating: [`swipe_screen.dart`](../lib/screens/home/swipe_screen.dart) (`_onSwipe`, `_onShowSwipe`, `CardSwiper` `key`)
