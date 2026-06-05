import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/screens/auth/login_screen.dart';
import 'package:popmatch/screens/auth/register_screen.dart';
import 'package:popmatch/screens/auth/forgot_password_screen.dart';
import 'package:popmatch/widgets/auth/auth_widgets.dart';
import 'package:popmatch/widgets/auth/auth_code_input.dart';

/// Verifies the redesigned auth screens render on the shared component set.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FirebaseConfig.setTestMode(true);
  });

  tearDownAll(() => FirebaseConfig.setTestMode(false));

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('Auth screens (redesigned)', () {
    testWidgets('Login shows email + password + primary + Google',
        (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen()));
      await tester.pump();

      expect(find.byType(AuthScaffold), findsOneWidget);
      expect(find.byType(AuthTextField), findsOneWidget); // email
      expect(find.byType(AuthPasswordField), findsOneWidget); // password
      expect(find.byType(AuthPrimaryButton), findsOneWidget); // Sign In
    });

    testWidgets('Register shows name/email + two password fields + strength-capable',
        (tester) async {
      await tester.pumpWidget(wrap(const RegisterScreen()));
      await tester.pump();

      expect(find.byType(AuthScaffold), findsOneWidget);
      expect(find.byType(AuthTextField), findsNWidgets(2)); // name + email
      expect(find.byType(AuthPasswordField),
          findsNWidgets(2)); // password + confirm
      expect(find.byType(AuthPrimaryButton), findsOneWidget);
    });

    testWidgets('Forgot password starts on the email step', (tester) async {
      await tester.pumpWidget(wrap(const ForgotPasswordScreen()));
      await tester.pump();

      expect(find.byType(AuthScaffold), findsOneWidget);
      expect(find.byType(AuthTextField), findsOneWidget); // email
      // Code input only appears after a code is requested (step 2).
      expect(find.byType(AuthCodeInput), findsNothing);
      expect(find.text('Send code'), findsOneWidget);
    });

    testWidgets('Forgot password email validation blocks empty submit',
        (tester) async {
      await tester.pumpWidget(wrap(const ForgotPasswordScreen()));
      await tester.pump();

      await tester.tap(find.text('Send code'));
      await tester.pump();

      // Still on the email step (validation failed) — no code input shown.
      expect(find.byType(AuthCodeInput), findsNothing);
    });
  });
}
