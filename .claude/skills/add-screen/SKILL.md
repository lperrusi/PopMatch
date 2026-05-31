---
name: add-screen
description: Use when adding a new screen to the app. Trigger phrases: "add a new screen", "create a screen", "new page", "add a tab", "create a new feature screen".
argument-hint: "<ScreenName> [tab-index if adding to HomeScreen]"
allowed-tools: [Read, Edit, Write, Bash]
---

## Step 1 — Create the screen file

Place the file under the appropriate directory:
- `lib/screens/home/` — for tabs or screens reachable from HomeScreen
- `lib/screens/auth/` — for auth flow screens
- `lib/screens/onboarding/` — for onboarding flow screens

Use this boilerplate (adjust providers as needed):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';

class MyNewScreen extends StatefulWidget {
  const MyNewScreen({super.key});

  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    // Always load data post-frame — never call setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // fetch data here
      setState(() { _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState(_error!);
    if (_items.isEmpty) return _buildEmptyState();
    return _buildContent();
  }

  Widget _buildLoadingState() => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  Widget _buildErrorState(String message) => Scaffold(
    body: Center(child: Text(message)),
  );

  Widget _buildEmptyState() => Scaffold(
    body: Center(child: Text('No items found')),
  );

  Widget _buildContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCREEN TITLE',
          style: TextStyle(fontFamily: 'BebasNeue', letterSpacing: 2)),
        backgroundColor: AppTheme.cinemaRed,
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) => ListTile(title: Text('$index')),
      ),
    );
  }
}
```

## Step 2 — Wire navigation

**For screens pushed from an existing screen** (detail, settings, etc.):
```dart
Navigator.push(
  context,
  NavigationUtils.fastSlideRoute(const MyNewScreen()),
);
```
Import: `import '../../utils/navigation_utils.dart';`

**For a new HomeScreen tab** (rare — requires IndexedStack change):
1. Open `lib/screens/home/home_screen.dart`
2. Add the screen to the `IndexedStack` children list
3. Add a `BottomNavigationBarItem` to `RetroCinemaBottomNav`
4. Update the tab index constants accordingly

## Step 3 — Add providers to the widget tree (if needed)

All 6 providers are already in the root `MultiProvider` in `lib/main.dart`. New screens can access them directly via `context.watch` / `context.read` — no additional wiring needed.

If the screen needs a provider *not* currently in the root tree (unusual), add it to `lib/main.dart`.

## Step 4 — Write the test

Create `test/my_new_screen_test.dart` using the standard boilerplate from the `testing-conventions` rule. Minimum tests:
- Screen renders without errors
- App bar title is correct
- Loading state shows indicator
- Empty state shows expected message
- Main content renders when data is present

```bash
flutter test test/my_new_screen_test.dart
flutter analyze
```

## Step 5 — Verify

```bash
flutter analyze          # zero new warnings
flutter test test/       # all existing tests still pass
```

## Common mistakes

- **Never call `setState` during `build`** — use `addPostFrameCallback` in `initState`.
- **Always check `mounted`** before calling `setState` after any `await`.
- **Don't call services directly** from `build` — read from providers or cache state in `_loadData`.
- **Don't hardcode colors** — use `AppTheme.cinemaRed`, `AppTheme.popcornGold`, etc.
- **Always use `CachedNetworkImage`** for TMDB images, not `Image.network`.
