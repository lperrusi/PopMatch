# PopMatch – Test overview

This document summarizes **what is tested** and **what is left to test** across app screens and features.

---

## 1. Screen & feature coverage

| Screen / feature | Widget tests (VM) | Integration (device) | Notes |
|------------------|-------------------|----------------------|--------|
| **Splash** | ✅ PopMatch title, Loading text, loading icon | ✅ Launch + same checks | Full |
| **Tutorial** (intro 3 pages) | ✅ All 3 pages, Next, Get Started → Login | ❌ | Full |
| **Login** | ✅ Title, fields, validation (empty/invalid/short), Forgot → screen, Sign Up & Google | ❌ | Full |
| **Forgot password** | ✅ Title, email field, validation, Send Reset Link, back | ❌ | Full |
| **Register** | ✅ JOIN POPMATCH, 4 fields, validation (email, display name, password, mismatch), Sign In link | ❌ | Full |
| **Email verification** | ✅ UI (email, resend, continue), flows (dev/prod), error handling | ❌ | Unit + widget |
| **Onboarding** (Welcome / Genres / Streaming) | ✅ Step 1–3, genres or “Loading genres”, Back, PageView | ❌ | Full |
| **Profile / Sign out** | ✅ PROFILE bar, loading state, user email, Sign Out, confirmation dialog, Cancel | ❌ | Full |
| **Home** | ⚠️ Basic display (DISCOVER, refresh) in `screen_tests` | ❌ | Shallow |
| **Swipe** (Movies/Shows cards) | ⚠️ `screen_tests` Discover group **skipped** (timers) | ✅ Seeded deck: `integration_test/swipe_deck_test.dart` | VM + device |
| **Movie detail** | ✅ Smoke title/overview (`home_tab_smoke_screens_test.dart`) | ❌ | Smoke |
| **TV show detail** | ✅ Smoke (`home_tab_smoke_screens_test.dart`) | ❌ | Smoke |
| **Search** | ⚠️ Basic display in `screen_tests` | ❌ | Shallow |
| **Watchlist / Enhanced watchlist** | ✅ App bar + empty state (`home_tab_smoke_screens_test.dart`) | ❌ | Smoke |
| **Recommendations** (tab is search-focused) | ✅ App bar + empty state (`home_tab_smoke_screens_test.dart`) | ❌ | Smoke |
| **Social hub** | ✅ Shell + sections (`social_hub_screen_test.dart`) | ❌ | Smoke |
| **Favorites** | ✅ Title, tabs, empty state | ❌ | Widget |
| **Edit preferences** | ✅ Title, step 1/2, genres, Next → platforms, Save | ❌ | Widget |
| **Mood selection** | ✅ Full flow: title, mood grid, select mood, Find X Movies | ❌ | Widget |
| **Notifications** | ✅ Title, description, toggles | ❌ | Widget |
| **Help & support** | ✅ Title, FAQ, Contact us, Email support | ❌ | Widget |
| **Privacy** | ✅ Title, data usage, toggle, Delete my data, dialog | ❌ | Widget |
| **Advanced filter** | ✅ Title, filter UI | ❌ | Widget |
| **Streaming filter** | ✅ Title, loading/content | ❌ | Widget |

**Summary:** Auth, onboarding, profile/sign-out, and email verification are well covered. Discover swipe **deck behavior** is covered by **integration** tests (`integration_test/swipe_deck_test.dart`, optional like-swipe). **Recommendations** tab (search UI), **watchlist**, and **detail** screens have **widget smoke** tests; deeper flows (gestures, full navigation) remain optional.

---

## 2. What is tested (by area)

### Auth & onboarding (widget tests)

- **Splash:** PopMatch title, “Loading...”, loading indicator (movie icon).
- **Tutorial:** Page 1 “SWIPE TO MATCH”, page 2 “AI Powered Picks”, page 3 “Curate Your Watchlist” + Get Started; Get Started → Login.
- **Login:** PopMatch, tagline, email/password fields; validation (empty email, invalid email, short password); Forgot Password → Forgot screen; Sign Up and Continue with Google present.
- **Forgot password:** “FORGOT PASSWORD?”, email field, validation, Send Reset Link, back chevron.
- **Register:** “JOIN POPMATCH”, 4 fields, validation (empty email, short display name, short password, password mismatch), “Already have an account? Sign In”.
- **Onboarding:** Step 1 “WELCOME TO POPMATCH!”, 1 of 3, Next; Step 2 genres or “Loading genres...”, Back to step 1; Step 3 PageView with 3 children.
- **Profile / Sign out:** PROFILE app bar; loading when no user; user email + Sign Out when user set; Sign Out → confirmation dialog; Cancel closes dialog.

Tests use mocked `SharedPreferences` and `TMDBService.setTestMode(true)` so no real TMDB calls run.

### Email verification

- **Widget:** Verification screen (email, resend, continue), loading on resend, errors, dev vs prod behavior.
- **Unit/scenarios:** Send verification, resend, errors (too many requests, network), dev skip, Google/Apple bypass, preferences preserved.

### Onboarding logic & preferences

- **Unit/integration:** Preferences saved during onboarding, `onboardingCompleted` flag, merge/update, serialization, first-time vs returning user, edit from profile, streaming platforms, recommendation use of preferences, edge cases (partial/null/corrupted data).

### Auth error handling (unit)

- **auth_error_handler_test:** Firebase auth errors (user-not-found, wrong-password, email-already-in-use, weak-password, network), SocketException, HttpException, timeout, JSON, cancel, generic; `isNetworkError`, `isCanceledError`.

### Services & models (unit)

- **recommendation_services_test:** Contextual/behavior/embedding/collaborative/deep learning weights, movie view/detail/swipe, similarity, recommendations, feature vector, prediction.
- **video_trailer_test:** Sample videos, YouTube URLs, thumbnails, video types.
- **streaming_availability_test:** Streaming availability (mock data, fallback, free movies).
- **widget_test:** Movie, CastMember, CrewMember, Video models.

### Medium & lower priority screens (widget tests)

- **medium_lower_priority_screens_test.dart:**  
  - **Edit preferences:** Title “Edit Preferences”, step 1 of 2, “What genres do you love?”, genre chips (Action, Adventure, Comedy), Next → step 2 “Where do you watch movies?”, Save.  
  - **Favorites:** Title “FAVORITES”, MOVIES/SHOWS tabs, empty state “No favorites yet” / “Start swiping to like movies!”.  
  - **Mood selection:** “How are you feeling?”, “What’s your mood today?”, mood grid (Happy, Excited, Romantic, etc.), “Select Your Mood” button, selecting a mood → “Find X Movies”.  
  - **Advanced filter:** Title “Advanced Filters”, filter UI with movies list and callback.  
  - **Streaming filter:** Title “Streaming Filters”, loading or content area.  
  - **Notifications:** “NOTIFICATIONS”, “Choose what you want to be notified about.”, SwitchListTile toggles.  
  - **Help & support:** “HELP & SUPPORT”, “Frequently asked questions”, “How does swiping work?”, “Contact us”, “Email support”, “support@popmatch.app”.  
  - **Privacy:** “PRIVACY”, “Control how your data is used…”, “Use data for recommendations”, “Your data”, “Delete my data”, tap Delete → dialog with Cancel.

### Other screen tests (shallow)

- **screen_tests.dart:** Splash, Onboarding, Mood selection, Home (DISCOVER, refresh), Search, Profile, navigation, different screen sizes, empty/loading states, accessibility. These are high-level display/navigation checks, not full flows.

---

## 3. What is left to test

### High value (main app flows)

| Area | Suggested focus |
|------|------------------|
| **Swipe screen** | Cards visible, like/pass (or swipe gestures), Movies/Shows tab switch, “no more cards” state. |
| **Movie detail** | Title, rating, overview, “Where to watch”, trailer button, add/remove from watchlist. |
| **TV show detail** | Same ideas as movie detail for TV. |
| **Search** | Search field, results list, tap opens detail, empty/loading. |
| **Watchlist** | List of titles, remove, tap → detail. |
| **Recommendations** | List/cards, tap → detail. |

### Medium value (settings & secondary screens)

| Area | Status | Suggested next |
|------|--------|----------------|
| **Edit preferences** | ✅ Widget tests | Save/persistence, genre toggle. |
| **Favorites** | ✅ Widget tests | List with items, remove, tap → detail. |
| **Mood selection** | ✅ Widget tests | Navigate to Home after Continue. |
| **Advanced filter** | ✅ Widget tests | Apply/Reset callbacks, filter changes. |
| **Streaming filter** | ✅ Widget tests | Platform selection, filtered results. |

### Lower priority (static/support)

| Area | Status | Suggested next |
|------|--------|----------------|
| **Notifications** | ✅ Widget tests | Toggle persistence. |
| **Help & support** | ✅ Widget tests | FAQ expand, email launch. |
| **Privacy** | ✅ Widget tests | Delete dialog “Learn more”. |

---

## 4. Test files reference

| File | Type | What it covers |
|------|------|----------------|
| **auth_onboarding_sign_flows_test.dart** | Widget | Splash, Tutorial, Login, Forgot password, Register, Profile/Sign out, Onboarding (32 tests). Primary auth/onboarding coverage. |
| **app_ui_flows_test.dart** | Widget | Splash, Tutorial, Login, Forgot password, Register, Onboarding (overlap with above, different structure). |
| **screen_tests.dart** | Widget | Splash, Onboarding, Mood, Home, Search, Profile, navigation, sizes, empty/loading, accessibility. |
| **email_verification_test.dart** | Unit | AuthService verification, dev/prod, send on sign-up, errors. |
| **email_verification_scenarios_test.dart** | Unit | Verification flows, resend, errors, dev skip, Google/Apple. |
| **email_verification_integration_test.dart** | Widget | Verification screen UI, buttons, loading, errors. |
| **onboarding_preferences_test.dart** | Unit | Preferences save/load/merge, onboarding flag, UserPreferenceAnalyzer. |
| **onboarding_integration_test.dart** | Unit | First-time/returning user, edit from profile, streaming, recommendations, edge cases. |
| **onboarding_flow_verification_test.dart** | Unit | Sign up → onboarding → sign in again → skip onboarding; user data loading. |
| **auth_error_handler_test.dart** | Unit | Auth error messages and helpers. |
| **recommendation_services_test.dart** | Unit | Contextual, behavior, embedding, collaborative, deep learning, recommendations. |
| **video_trailer_test.dart** | Unit | Video service (sample, URLs, types). |
| **streaming_availability_test.dart** | Unit | Streaming availability service. |
| **widget_test.dart** | Unit | Movie, Video, cast/crew models. |
| **medium_lower_priority_screens_test.dart** | Widget | Edit preferences, Favorites, Mood selection, Advanced filter, Streaming filter, Notifications, Help & support, Privacy (21 tests). |
| **integration_test/app_test.dart** | Integration | Full app launch on device; Splash (PopMatch, Loading). |
| **integration_test/swipe_deck_test.dart** | Integration | Seeded `MovieProvider`, skip swipe + `removeMovie` (no TMDB). |
| **integration_test/swipe_like_integration_test.dart** | Integration | Optional: right-swipe like with test user + Firebase test mode. |
| **home_tab_smoke_screens_test.dart** | Widget | Recommendations (Search), Watchlist, Movie/Show detail smoke. |
| **social_hub_screen_test.dart** | Widget | Social hub shell (Firebase test mode). |

---

## 5. Quick run commands

**Flutter limitation:** `flutter test` **cannot** run **integration tests** (`integration_test/`) and **unit/widget** tests in a **single** invocation. Run them separately, or use `scripts/ci_test.sh` (see below).

**Full auth/onboarding/sign-out (recommended):**

```bash
flutter test test/auth_onboarding_sign_flows_test.dart
```

**All UI flow tests (splash, tutorial, login, register, forgot password, onboarding):**

```bash
flutter test test/app_ui_flows_test.dart
```

**Screen tests (home, search, profile, mood, etc.):**

```bash
flutter test test/screen_tests.dart
```

**Email verification:**

```bash
flutter test test/email_verification_test.dart test/email_verification_scenarios_test.dart test/email_verification_integration_test.dart
```

**Onboarding logic & preferences:**

```bash
flutter test test/onboarding_preferences_test.dart test/onboarding_integration_test.dart test/onboarding_flow_verification_test.dart
```

**Medium & lower priority screens (Edit preferences, Favorites, Mood, Filters, Notifications, Help, Privacy):**

```bash
flutter test test/medium_lower_priority_screens_test.dart
```

**All unit + widget tests:**

```bash
flutter test
```

**Home tab smoke (Recommendations / Watchlist / detail):**

```bash
flutter test test/home_tab_smoke_screens_test.dart test/social_hub_screen_test.dart
```

**CI-style (unit/widget + integration on one simulator):**

```bash
./scripts/ci_test.sh
```

(Requires `INTEGRATION_DEVICE` env or default `ios` first simulator in script.)

---

## 6. Integration test (on device)

Runs the **real app** on a connected **iOS or Android** device and checks that the splash shows “PopMatch” and “Loading...”.

1. Connect a device or start an emulator.
2. `flutter devices`
3. Run:

```bash
flutter test integration_test/app_test.dart -d <deviceId>
```

Example:

```bash
flutter test integration_test/app_test.dart -d 00008150-000968E02684401C
```

**Discover swipe deck (no TMDB; seed deck):**

```bash
flutter test integration_test/swipe_deck_test.dart -d <deviceId>
```

If multiple devices are connected, **always** pass `-d <deviceId>`.

**Optional like-swipe integration:**

```bash
flutter test integration_test/swipe_like_integration_test.dart -d <deviceId>
```

---

## 7. Test setup notes

- **Auth/onboarding widget tests** use `SharedPreferences.setMockInitialValues({})` and `TMDBService.setTestMode(true)` so no real network or TMDB calls are made. `MovieProvider.setTestGenres()` is used where a preloaded provider is provided.
- For **email verification** and **onboarding** unit tests, behavior may depend on dev vs prod (e.g. Firebase) flags; see individual test files for mocks and assumptions.
