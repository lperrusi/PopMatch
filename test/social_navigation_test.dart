import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/models/user.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/screens/home/profile_screen.dart';
import 'package:popmatch/services/firebase_config.dart';

void main() {
  testWidgets('Profile shows Social entry tile', (tester) async {
    FirebaseConfig.setTestMode(true);
    final authProvider = AuthProvider();
    authProvider.setTestUserData(
      User(
        id: 'u1',
        email: 'u1@example.com',
        displayName: 'User One',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Friends and what they are watching'), findsOneWidget);

    FirebaseConfig.setTestMode(false);
  });
}
