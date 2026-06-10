import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/enhanced_watchlist_screen.dart';
import 'package:popmatch/screens/home/friend_profile_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/poster_grid_skeleton.dart';
import 'package:popmatch/widgets/poster_list_skeleton.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
  });

  tearDown(() {
    TMDBService.setTestMode(false);
    FirebaseConfig.setTestMode(false);
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocialProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.retroCinemaTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('FriendProfileScreen shows a grid skeleton while loading',
      (tester) async {
    await tester.pumpWidget(wrap(const FriendProfileScreen(uid: 'u1')));
    // First frame: _loading is still true (async _load hasn't resolved).
    expect(find.byType(PosterGridSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('EnhancedWatchlistScreen shows a list skeleton while loading',
      (tester) async {
    await tester.pumpWidget(wrap(const EnhancedWatchlistScreen()));
    // Lists tab is default; while _isLoading it renders the list skeleton.
    expect(find.byType(PosterListSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
