import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/movie_provider.dart';
import 'package:popmatch/providers/show_provider.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/detail/detail_action_buttons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() => FirebaseConfig.setTestMode(false));

  Widget wrap({required bool isShow}) {
    final auth = AuthProvider()
      ..setTestUserData(
        User(id: 'u1', email: 'u1@test.com', displayName: 'U'),
      );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => ShowProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.retroCinemaTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DetailActionButtons(
            itemId: '603',
            title: 'The Matrix',
            isShow: isShow,
            textColor: AppTheme.warmCream,
            onShare: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('movie variant includes the add-to-list button', (tester) async {
    await tester.pumpWidget(wrap(isShow: false));
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    // Watchlist + like + dislike + add-to-list + share = 5 IconButtons.
    expect(find.byType(IconButton), findsNWidgets(5));
  });

  testWidgets('show variant omits the add-to-list button', (tester) async {
    await tester.pumpWidget(wrap(isShow: true));
    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
    // Watchlist + like + dislike + share = 4 IconButtons.
    expect(find.byType(IconButton), findsNWidgets(4));
  });

  testWidgets('tapping Like flips the icon and shows a snackbar',
      (tester) async {
    await tester.pumpWidget(wrap(isShow: false));
    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pump(); // run the async like + setState
    await tester.pump();

    expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
    expect(find.textContaining('The Matrix'), findsOneWidget); // snackbar
  });
}
