import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/services/movie_cache_service.dart';
import 'package:popmatch/services/user_preferences_session_cache.dart';

/// Flutter auto-runs this around the entire test suite. We reset the
/// process-wide singleton caches before each test so state can't leak across
/// test files (e.g. a cached movie/preferences from one suite affecting another).
/// Deliberately conservative: it does NOT touch test-mode flags or
/// SharedPreferences (each file manages those), to avoid breaking suites that
/// rely on their own setup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    MovieCacheService.instance.clearCache();
    UserPreferencesSessionCache().clear();
  });

  await testMain();
}
