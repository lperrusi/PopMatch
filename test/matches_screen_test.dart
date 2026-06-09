import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/matches_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() {
    TMDBService.setTestMode(false);
    FirebaseConfig.setTestMode(false);
  });

  testWidgets('MatchesScreen renders the empty state when there are no matches',
      (tester) async {
    final auth = AuthProvider()
      ..setTestUserData(
        User(id: 'm1', email: 'm1@test.com', displayName: 'Me'),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.retroCinemaTheme,
          home: const MatchesScreen(),
        ),
      ),
    );

    // Title in the app bar is present immediately.
    expect(find.text('YOUR MATCHES'), findsOneWidget);

    // Let the post-frame load() resolve (no friends feed in test mode → empty).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No matches yet'), findsOneWidget);
  });
}
