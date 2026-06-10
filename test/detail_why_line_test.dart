import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/detail/detail_why_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => FirebaseConfig.setTestMode(true));
  tearDownAll(() => FirebaseConfig.setTestMode(false));

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        theme: AppTheme.retroCinemaTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders a strategy reason label', (tester) async {
    await tester.pumpWidget(wrap(const DetailWhyLine(
      strategy: 'trending',
      genreIds: null,
      genreNames: null,
      genres: {},
      castNames: null,
      textColor: AppTheme.warmCream,
    )));
    expect(find.text('Trending now'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('renders nothing when there is no meaningful reason',
      (tester) async {
    await tester.pumpWidget(wrap(const DetailWhyLine(
      strategy: null,
      genreIds: null,
      genreNames: null,
      genres: {},
      castNames: null,
      textColor: AppTheme.warmCream,
    )));
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });
}
