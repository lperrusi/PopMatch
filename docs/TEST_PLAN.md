# PopMatch — Hybrid Test Plan

> **Format:** You perform the action. I guide each step and validate the result using simulator screenshots and terminal logs.
>
> **Prerequisites:**
> - App running via `./run_app.sh` (or `flutter run --dart-define-from-file=.env`)
> - iPhone 17 Pro simulator booted
> - Test user already logged in and has completed onboarding
>
> **How to read this plan:**
> - **You do:** What you tap/swipe/type
> - **Expected:** What should appear
> - **Validates:** The underlying feature being confirmed

---

## Test Execution Status

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| T01 | Discover — Movies Tab Loads | ⬜ | |
| T02 | Discover — Shows Tab Loads | ⬜ | |
| T03 | Discover — Swipe Right (Like) | ⬜ | |
| T04 | Discover — Swipe Left (Dislike) | ⬜ | |
| T05 | Discover — Swipe Up (Match) | ⬜ | |
| T06 | Discover — Swipe Down (Skip) | ⬜ | |
| T07 | Discover — Undo after swipe | ⬜ | |
| T08 | Discover — Filter sheet opens | ⬜ | |
| T09 | Discover — Genre filter applied | ⬜ | |
| T10 | Discover — Tap card opens detail | ⬜ | |
| T11 | Movie Detail — Full content loads | ⬜ | |
| T12 | Movie Detail — Like button toggles | ⬜ | |
| T13 | Movie Detail — Watchlist button toggles | ⬜ | |
| T14 | Match Success — Animation plays | ⬜ | |
| T15 | Match Success — Continue dismisses | ⬜ | |
| T16 | Match Success — Add to Watchlist | ⬜ | |
| T17 | Search — Returns results | ⬜ | |
| T18 | Search — Tap result opens detail | ⬜ | |
| T19 | Watchlist — Items display | ⬜ | |
| T20 | Watchlist — Remove item | ⬜ | |
| T21 | Favorites — Items display | ⬜ | |
| T22 | Favorites — Sort changes order | ⬜ | |
| T23 | Favorites — Bulk delete | ⬜ | |
| T24 | Profile — Stats are accurate | ⬜ | |
| T25 | Profile — Edit Preferences saves | ⬜ | |
| T26 | Profile — Notifications toggles | ⬜ | |
| T27 | Profile — Logout works | ⬜ | |
| T28 | Shows Detail — Full content loads | ⬜ | |

**Status legend:** ⬜ Not tested | ✅ Pass | ❌ Fail | ⚠️ Pass with issue

---

## Section 1: Discover Screen — Movies

### T01 — Movies tab loads with real data

**You do:** Open the app. You should land on the Discover screen, Movies tab.

**Expected:**
- Header shows "DISCOVER"
- "MOVIES" tab is selected (gold underline)
- A movie card is visible with poster image, title, and year
- Movie is from TMDB (real data, not sample data like "Sample Movie")
- Terminal shows `flutter: OMDb API key configured from build environment`

**Validates:** API keys injected correctly, TMDB fetch working, Discover screen loads.

---

### T02 — Shows tab loads with real data

**You do:** Tap the "SHOWS" tab at the top of the Discover screen.

**Expected:**
- Tab indicator moves to "SHOWS"
- A TV show card appears with poster, title, and year
- Terminal should NOT show any 401 errors for getShowDetails

**Validates:** Shows fetch working, no unauthorized API calls.

---

### T03 — Swipe Right (Like)

**You do:** Swipe the current movie card to the RIGHT.

**Expected:**
- Card slides off to the right with animation
- Green heart / like indicator appears during swipe
- Snackbar appears: "Swipe recorded / **UNDO**" (lasts ~2 seconds)
- Next card slides into view
- Terminal: no errors

**Validates:** Like action saved to `user.likedMovies`, next card ready.

---

### T04 — Swipe Left (Dislike)

**You do:** Swipe the current card to the LEFT.

**Expected:**
- Card slides off to the left
- Red X indicator appears during swipe
- Snackbar: "Swipe recorded / **UNDO**"
- Next card appears

**Validates:** Dislike action saved to `user.dislikedMovies`.

---

### T05 — Swipe Up (Match)

**You do:** Swipe the current card UPWARD.

**Expected:**
- Card slides off upward
- **Match Success overlay** appears with animation:
  - Heart icon bounces in
  - "It's a Match!" headline slides up
  - Movie poster appears
  - Three buttons: "Continue", "View Details", "Add to Watchlist"
- Terminal: no errors

**Validates:** Match flow triggers correctly, MatchSuccessScreen animates.

---

### T06 — Swipe Down (Skip)

**You do:** Swipe the current card DOWNWARD.

**Expected:**
- Card slides off downward
- **No snackbar** appears (skip is silent)
- Next card appears

**Validates:** Skip is silent and does not save to liked/disliked.

---

### T07 — Undo after swipe

**You do:** Swipe a card right (like). When the UNDO snackbar appears, tap **UNDO** immediately.

**Expected (best case):** Card is restored to the deck; liked movie is removed from state.

**Known issue:** Due to CardSwiper remount bug, the card may not visually return even if state is correctly reverted. See `DISCOVER_UNDO_PRODUCT_FIX.md`.

**Validates (regardless of visual):** State reversion — movie should no longer appear in Favorites after undo.

---

### T08 — Filter sheet opens

**You do:** Tap the **tune icon** (top-right of Discover screen).

**Expected:**
- Bottom sheet slides up
- "MOOD", "GENRES", "STREAMING PLATFORMS" sections visible
- Multi-select chips/cards for each section
- Close/Apply button

**Validates:** Filter UI accessible.

---

### T09 — Genre filter applied

**You do:** In the filter sheet, tap one genre (e.g., "Action"). Then tap Apply (or close the sheet).

**Expected:**
- Sheet closes
- Gold badge appears on the filter icon (indicating active filter)
- Movie deck reloads with action movies

**Validates:** Filter state applied to `MovieProvider`, deck reloads.

---

### T10 — Tap card opens Movie Detail

**You do:** Tap on the movie poster/card (not swipe, just a tap).

**Expected:**
- Screen transitions to Movie Detail
- Poster and title visible immediately
- Cast, synopsis, streaming availability load within ~2 seconds

**Validates:** Card tap navigation works, MovieDetailScreen loads.

---

## Section 2: Movie Detail Screen

### T11 — Full content loads

**You do:** After tapping a card, wait 3 seconds on the detail screen.

**Expected:**
- **Header:** Movie title, year, rating
- **Synopsis:** Visible text (not loading spinner)
- **Cast section:** At least a few actor names with photos
- **Streaming availability section:** Platform badges or "Not available"
- **Action buttons:** Heart (like) and bookmark (watchlist) icons

**Validates:** All detail APIs respond successfully (TMDB credits, streaming).

---

### T12 — Like button toggles

**You do:** Tap the heart icon on the Movie Detail screen.

**Expected:**
- Heart icon fills/turns red (liked state)
- Snackbar: "Added to Favorites" (or similar)
- Tap again: heart unfills, snackbar: "Removed from Favorites"

**Validates:** `AuthProvider.toggleLike()` updates state; Profile Favorites count should change.

---

### T13 — Watchlist button toggles

**You do:** Tap the bookmark/watchlist icon.

**Expected:**
- Icon fills/activates (watchlisted state)
- Snackbar: "Added to Watchlist"
- Tap again: icon unfills, snackbar: "Removed from Watchlist"

**Validates:** `AuthProvider.toggleWatchlist()` working; Watchlist tab count should update.

---

## Section 3: Match Success Overlay

### T14 — Animation plays

**You do:** Go back to Discover. Swipe a card UP.

**Expected:**
- Overlay appears with staggered animations over ~2 seconds:
  1. Heart bounces in
  2. "It's a Match!" text slides up
  3. Movie poster appears
  4. Meta info (title, genre, rating) appears
  5. Three action buttons appear

**Validates:** `MatchSuccessScreen` animation controller working.

---

### T15 — Continue dismisses overlay

**You do:** On the Match overlay, tap "Continue".

**Expected:**
- Overlay dismisses with fade/slide animation
- Returns to Discover screen with next card ready

**Validates:** Basic overlay dismiss path.

---

### T16 — Add to Watchlist from Match

**You do:** Swipe up on another card. When Match overlay appears, tap "Add to Watchlist".

**Expected:**
- Overlay dismisses
- Snackbar: "Added to watchlist"
- Movie appears in Watchlist tab (verify later)

**Validates:** Watchlist add from Match overlay works.

---

## Section 4: Search Screen

### T17 — Search returns results

**You do:** Tap the **Search** tab in the bottom nav.

**You do:** Tap the search bar. Type "Inception".

**Expected:**
- Results appear within ~1 second (debounced 350ms)
- Grid shows movie posters for "Inception" and related titles
- Each result shows title and year

**Validates:** `TMDBService.searchMovies()` returning results.

---

### T18 — Tap search result opens detail

**You do:** Tap one of the search result cards.

**Expected:**
- Navigates to Movie Detail screen
- Content loads as per T11

**Validates:** Search result navigation working.

---

## Section 5: Watchlist Screen

### T19 — Items display

**You do:** Tap the **Watchlist** tab. (If you added items via T13/T16, they should appear.)

**Expected:**
- "WATCHLIST" header
- MOVIES and SHOWS tabs
- At least one movie card visible (the one you watchlisted)
- Cards show poster + title

**Validates:** Watchlist persisted across screens.

---

### T20 — Remove item from Watchlist

**You do:** On a watchlist item, use the action menu (swipe right on card or long-press) to remove it.

**Expected:**
- Item removed from list with animation
- Snackbar: "Removed from watchlist"
- Profile stats update (Watchlist count decreases)

**Validates:** Remove action updates `AuthProvider` and UI.

---

## Section 6: Favorites Screen

### T21 — Items display

**You do:** Tap the **Favorites** tab. (Items you liked via T03/T12 should appear.)

**Expected:**
- "FAVORITES" header
- MOVIES and SHOWS tabs
- Liked items visible with posters
- Sort dropdown visible

**Validates:** Liked movies persisted correctly.

---

### T22 — Sort changes order

**You do:** Tap the sort dropdown. Select "Year (Newest)".

**Expected:**
- List re-orders so newest movies appear first
- Animation/transition as list shuffles

**Validates:** Client-side sorting working.

---

### T23 — Bulk delete

**You do:** Tap the delete/checkbox icon in the header to enter delete mode.
Tap 2 movie checkboxes to select them.
Tap the confirm delete button.

**Expected:**
- Delete mode: checkboxes appear on each card
- After confirm: selected items disappear
- Snackbar: "2 items removed" (or similar count)
- No undo offered

**Validates:** Bulk delete removes items from `AuthProvider.userData.likedMovies`.

---

## Section 7: Profile Screen

### T24 — Stats are accurate

**You do:** Tap the **Profile** tab.

**Expected:**
- Your email displayed
- Three stat cards visible:
  - "Watchlist" count matches items in Watchlist tab
  - "Liked Movies" count matches items in Favorites (Movies)
  - "Liked Shows" count matches items in Favorites (Shows)

**Validates:** Stats computed live from `AuthProvider.userData`.

---

### T25 — Edit Preferences saves

**You do:** Tap "Edit Preferences". On Page 1 (Genres), toggle a genre that isn't selected. Tap Continue. On Page 2 (Platforms), toggle a platform. Tap Save.

**Expected:**
- Confirmation snackbar: "Preferences saved"
- Returning to Discover should reflect the new genre in content load
- Terminal: no errors

**Validates:** Preferences write to SharedPreferences and reload `MovieProvider` filters.

---

### T26 — Notifications toggles

**You do:** Tap "Notifications". Toggle the "Push notifications" switch.

**Expected:**
- Toggle changes state immediately
- No crash or error
- Toggle state persists if you leave and return to the screen

**Validates:** Toggle persisted to SharedPreferences.

---

### T27 — Logout works

**You do:** Tap "Logout" at the bottom of the Profile screen.

**Expected:**
- Confirmation dialog (if shown) or immediate logout
- Navigates to Login screen
- App state cleared (e.g., navigating back is not possible)
- Terminal: no errors

**Validates:** `AuthProvider.signOut()` clears state and navigates correctly.

---

## Section 8: Shows — Detail Screen

### T28 — Show detail loads

**You do:** Go to Discover. Tap the "SHOWS" tab. Tap a show card.

**Expected:**
- Show detail screen loads
- Fields visible: title, year, number of seasons, status (Returning / Ended)
- Cast section loads
- Streaming availability loads
- **No 401 or 404 errors** in terminal for getShowDetails, getShowCredits, getShowVideos

**Validates:** Show-specific TMDB endpoints working with API key guards.

---

## Post-Test Checks

After completing all test cases, verify the following in the terminal log:

```
grep -E "401|403|Unauthorized|Invalid API" /tmp/flutter_run.log
```

Expected: **zero** matches (no unauthorized API errors).

```
grep "OMDb API key configured" /tmp/flutter_run.log
```

Expected: at least one line confirming API keys are injected.

---

## Regression Notes

When any test fails, document here:

| Test | Failure | Root Cause | Fix Applied |
|------|---------|-----------|------------|
| | | | |
