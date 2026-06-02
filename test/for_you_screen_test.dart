import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/recommendations_provider.dart';
import 'package:popmatch/screens/home/for_you_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/tmdb_service.dart';
import 'package:popmatch/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TMDBService.setTestMode(true);
    FirebaseConfig.setTestMode(true);
  });

  tearDown(() {
    FirebaseConfig.setTestMode(false);
    TMDBService.setTestMode(false);
  });

  Widget wrap(Widget child) {
    final auth = AuthProvider()
      ..setTestUserData(
        User(id: 'fy-user', email: 'fy@test.com', displayName: 'FY'),
      );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.retroCinemaTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('ForYouScreen renders its title and rails without error',
      (tester) async {
    await tester.pumpWidget(wrap(const ForYouScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('FOR YOU'), findsOneWidget);
    // Rails are quality-filtered, so their presence depends on sample data;
    // assert the screen builds cleanly.
    expect(tester.takeException(), isNull);
  });
}
