import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/social_hub_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SocialHubScreen shows shell and Find users', (tester) async {
    FirebaseConfig.setTestMode(true);
    final auth = AuthProvider()
      ..setTestUserData(
        User(
          id: 's1',
          email: 's1@test.com',
          displayName: 'Social User',
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.retroCinemaTheme,
          home: const SocialHubScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SOCIAL'), findsOneWidget);
    expect(find.text('Find users'), findsOneWidget);
    expect(find.text('What your friends are watching'), findsOneWidget);

    FirebaseConfig.setTestMode(false);
  });
}
