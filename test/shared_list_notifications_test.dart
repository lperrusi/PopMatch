import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/notifications_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/services/notification_service.dart';
import 'package:popmatch/services/social_service.dart';
import 'package:popmatch/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() {
    FirebaseConfig.setTestMode(false);
  });

  test('sharedWithMeStream is null when Firebase is disabled', () {
    expect(SocialService.instance.sharedWithMeStream(), isNull);
  });

  test('showSharedWatchlistNotification is a no-op before init (no throw)',
      () async {
    // Not initialized in tests → showNotification returns early.
    await NotificationService.instance.showSharedWatchlistNotification(
      fromName: 'Alice',
      listName: 'Date Night',
    );
  });

  testWidgets('Notifications settings shows the Shared lists toggle',
      (tester) async {
    final auth = AuthProvider()
      ..setTestUserData(
        User(id: 'n1', email: 'n1@test.com', displayName: 'Notif User'),
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
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared lists'), findsOneWidget);
    expect(find.text('Notify when a friend shares a list with you'),
        findsOneWidget);
  });
}
