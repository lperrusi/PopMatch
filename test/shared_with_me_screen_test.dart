import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/shared_with_me_screen.dart';
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

  testWidgets('SharedWithMeScreen renders the empty state when nothing shared',
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
          home: const SharedWithMeScreen(),
        ),
      ),
    );

    expect(find.text('SHARED WITH YOU'), findsOneWidget);

    // Let the post-frame load() resolve (Firebase off → getSharedWithMe → []).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nothing shared yet'), findsOneWidget);
  });
}
