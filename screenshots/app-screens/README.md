# PopMatch — App Screenshots

All screenshots captured manually on device in the **Retro Cinema dark theme**.

---

## Screenshot index

| # | File | Screen | State |
|---|---|---|---|
| 01 | `01_splash_screen.png` | SplashScreen | Initial load with emoji loading indicator |
| 02 | `02_tutorial_page1.png` | TutorialScreen | Page 1 — "Swipe to Match" |
| 03 | `03_tutorial_page2.png` | TutorialScreen | Page 2 — "AI Powered Picks" |
| 04 | `04_tutorial_page3.png` | TutorialScreen | Page 3 — "Curate Your Watchlist" + GET STARTED |
| 05 | `05_login_screen.png` | LoginScreen | Empty form, unauthenticated |
| 06 | `06_login_screen_exception.png` | LoginScreen | Keyboard-raised layout overflow (logo/title clipped) |
| 07 | `07_register_screen.png` | RegisterScreen | Empty form |
| 08 | `08_register_screen_exception.png` | RegisterScreen | Keyboard-raised layout overflow |
| 09 | `09_forgot_password_screen.png` | ForgotPasswordScreen | Empty form |
| 10 | `10_forgot_password_exception.png` | ForgotPasswordScreen | Keyboard-raised state |
| 11 | `11_onboarding_welcome.png` | OnboardingScreen | Step 1 of 3 — Welcome + feature list |
| 12 | `12_onboarding_genres.png` | OnboardingScreen | Step 2 of 3 — Genre chip grid |
| 13 | `13_onboarding_platforms.png` | OnboardingScreen | Step 3 of 3 — Streaming platforms (radio buttons) |
| 14 | `14_swipe_screen_firsttimeuser.png` | SwipeScreen | First-time user with radial action tutorial overlay |
| 15 | `15_swipe_screen_movie.png` | SwipeScreen | Movie card (The Super Mario Galaxy Movie) |
| 16 | `16_swipe_screen_show.png` | SwipeScreen | Show card (FROM, Paramount+) |
| 17 | `17_itsamatch_screen.png` | MatchSuccessScreen | Light-theme match celebration (Send Help) |
| 18 | `18_moviedetail_screen1.png` | MovieDetailScreen | Above fold — poster, title, action buttons, synopsis |
| 19 | `19_moviedetail_screen2.png` | MovieDetailScreen | Trailers & Videos + Cast & Crew sections |
| 20 | `20_moviedetail_screen3.png` | MovieDetailScreen | Movies Like This section |
| 21 | `21_search_screen.png` | SearchScreen | Empty state — "Find Your Film Crew" |
| 22 | `22_search_screen_searching_friends.png` | SearchScreen | People tab active, no results |
| 23 | `23_search_screen_search_movies.png` | SearchScreen | Movies & Shows tab active, no results |
| 24 | `24_watchlist_screen_empty.png` | WatchlistScreen | Shows tab empty (light cream content area) |
| 25 | `25_watchlist_screen.png` | WatchlistScreen | Movies tab with 2 items (dark content area) |
| 26 | `26_favorites_screen_empty.png` | FavoritesScreen | Shows tab empty, sort/delete icons active |
| 27 | `27_favorites_screen.png` | FavoritesScreen | Movies tab with 4 items in 2×2 grid |
| 28 | `28_profile_screen.png` | ProfileScreen | Top — avatar, stats, recently liked movies |
| 29 | `29_profile_screen2.png` | ProfileScreen | Scrolled — Account Settings list + Sign Out |
| 30 | `30_edit_preferences_screen1.png` | EditPreferencesScreen | Page 1 of 2 — Genre grid |
| 31 | `31_edit_preferences_screen2.png` | EditPreferencesScreen | Page 2 of 2 — Streaming platforms + Save |
| 32 | `32_notification_settings_screen.png` | NotificationsScreen | Toggles for all notification types |
| 33 | `33_privacy_settings_screen.png` | PrivacyScreen | Data + social privacy toggles |
| 34 | `34_help_support.screen.png` | HelpSupportScreen | FAQ accordion + email support + app version |
| 35 | `35_addsfree_screen.png` | RemoveAdsDialog | "Coming Soon" system alert |
| 36 | `36_logout_popup.png` | SignOutDialog | Confirmation dialog |

---

## Known issues captured (for UX review)

- **06, 08, 10** — Keyboard overflow: logo/title clipped when soft keyboard appears on auth screens
- **13, 31** — Radio button affordance on multi-select platform list
- **14** — Radial action overlay competes with swipe gesture mental model
- **17** — Light cream background breaks dark Retro Cinema theme on match screen
- **21** — Empty state copy ("Find Your Film Crew") is friends-only, wrong for Movies tab
- **24 vs 25** — Empty state uses light cream, filled state uses dark — inconsistent per tab
- **26** — Sort/delete header icons remain active on empty state

---

## Theme context

- Font families: **BebasNeue** (titles/headings), **Lato** (body)
- Palette: `cinemaRed #2E1403` · `popcornGold #F6C344` · `filmStripBlack #1A1A1A` · `creamyWhite #F7F3E8` · `sepiaBrown #8B6914` · `vintagePaper #F2E8D9`
- Default mode: `ThemeMode.dark`

---

## How to regenerate with automation

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  -d <device-id>
```
