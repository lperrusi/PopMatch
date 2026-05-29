---
description: Flutter and app-level conventions for PopMatch
---

## Architecture
- App is portrait-only (enforced in `lib/main.dart`); do not add landscape layouts.
- Always use `AppTheme` constants from `lib/utils/theme.dart` — never hardcode hex colors or text styles inline.
- Services follow the singleton pattern (`.instance`); obtain them via `ServiceName.instance`, not `ServiceName()`.
- Feature flags live in `lib/services/feature_flags.dart`; check there before adding new conditional behavior.
- State is managed via the 6 `ChangeNotifierProvider`s in `lib/main.dart`; widgets read state through `context.watch` / `context.read`, not by calling services directly.
- TMDB numeric IDs are canonical throughout the app (swipe deck, watchlist keys, `MovieCacheService`, social activity `itemId`). Never key user-facing lists by external IDs (OMDb, Trakt, etc.). If a second catalog is added in the future, items must be resolved to a TMDB ID before entering any provider or user data store.

## Dart / Flutter code style
- Always check `mounted` before calling `setState` after any `await` or timer callback — async gaps can outlive the widget.
- Use `withValues(alpha: x)` (Flutter 3.10+) instead of the deprecated `.withOpacity(x)`. The `ColorUtils` helper in `lib/utils/` wraps this.
- Use `copyWith()` for all model updates (`User`, `SocialPrivacySettings`, `WatchlistList`); never mutate model fields directly.
- For conditional widget lists inside `children: []`, use the spread + `if` pattern: `if (condition) ...[Widget(), SizedBox()]`. Do not use ternary returning `SizedBox()`.
- Use `NavigationUtils.fastSlideRoute()` or `fastFadeRoute()` from `lib/utils/navigation_utils.dart` for custom screen transitions. Do not build raw `PageRouteBuilder` inline.

## Screen structure
- Screens with async data must implement three private builder methods: `_buildLoadingState()`, `_buildErrorState(String message)`, `_buildEmptyState()`. The `build` method dispatches to these with early `if` chains before rendering the main content.
- Use `addPostFrameCallback` to trigger data loads in `initState` (avoids calling `setState` during build).
