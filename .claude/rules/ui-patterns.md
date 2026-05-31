---
description: UI widget and animation patterns for PopMatch — apply when building or modifying widgets and screens
---

## Card widgets

The swipe deck uses two card variants — always use the Retro Cinema versions, not the plain `MovieCard`:
- `RetroCinemaMovieCard` (`lib/widgets/retro_cinema_movie_card.dart`) — movie swipe cards
- `RetroCinemaShowCard` (`lib/widgets/retro_cinema_show_card.dart`) — show swipe cards

Both perform **async poster color extraction** to derive dynamic text color. This must be done after the first frame (inside `addPostFrameCallback`) with a 300 ms delay, and must check `mounted` before calling `setState`. Disable it in tests via the `disableAsyncColorExtraction` flag.

## Async color extraction pattern (required for any card using CachedNetworkImage)

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _extractColors();
    });
  });
}

Future<void> _extractColors() async {
  // ... palette extraction ...
  if (mounted) setState(() { /* update color state */ });
}
```

## Match success animation

`MatchSuccessScreen` (`lib/widgets/match_success_screen.dart`) uses a staggered 2.1-second timeline on a **single `AnimationController`** with 8 composed animations via `Interval` curves. When building new celebration/success screens, follow the same single-controller + staggered-interval pattern rather than multiple controllers.

Auto-dismiss is done via a `Timer` that calls `Navigator.of(context).pop()` — always cancel the timer in `dispose()`.

## Loading / error / empty states

Every screen with async data must implement all three as private methods and dispatch from `build`:

```dart
Widget build(BuildContext context) {
  if (_isLoading) return _buildLoadingState();
  if (_error != null) return _buildErrorState(_error!);
  if (_items.isEmpty) return _buildEmptyState();
  return _buildContent();
}
```

The `Shimmer` package is available for skeleton loading placeholders — use it for list/grid screens instead of a plain `CircularProgressIndicator`.

## Conditional widget lists

Inside `children: []`, use spread + `if` for optional widgets:

```dart
children: [
  const AlwaysShownWidget(),
  if (condition) ...[
    const OptionalWidget(),
    const SizedBox(height: 8),
  ],
],
```

Do not use `condition ? Widget() : const SizedBox.shrink()` — it produces unnecessary layout nodes.

## Navigation transitions

Always use `NavigationUtils` from `lib/utils/navigation_utils.dart`:

```dart
// Slide transition (default 400ms)
Navigator.push(context, NavigationUtils.fastSlideRoute(const MyScreen()));

// Fade transition (200ms)
Navigator.push(context, NavigationUtils.fastFadeRoute(const MyScreen()));
```

Do not build `PageRouteBuilder` inline in screens.

## RecommendationsWidget pattern

`RecommendationsWidget` (`lib/widgets/`) takes a `title`, `subtitle`, `movies` list, `isLoading`, `error`, and callbacks. Use it for any horizontal movie/show list section. It handles loading shimmer, error display, and empty state internally.

## Streaming availability display

Use `StreamingAvailabilityWidget` (`lib/widgets/`) to show "Where to watch" sections. It renders platform logos with pricing badges (green = Free, blue = Rent, orange = Buy). Do not build inline streaming displays.

## Image loading

Always use `CachedNetworkImage` (not `Image.network`) for TMDB poster and profile images. Construct URLs via `Movie.posterUrl`, `CastMember.profileUrl`, or `TMDBService.getImageUrl(path, size)`.
