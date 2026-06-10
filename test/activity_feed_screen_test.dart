import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/activity_feed_screen.dart';
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

  testWidgets('ActivityFeedScreen renders empty state with no activity',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.retroCinemaTheme,
          home: const ActivityFeedScreen(),
        ),
      ),
    );

    expect(find.text('FRIENDS ACTIVITY'), findsOneWidget);

    // Post-frame load resolves (Firebase off → empty feed).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No activity yet'), findsOneWidget);
  });
}
