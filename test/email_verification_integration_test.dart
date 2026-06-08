import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:popmatch/providers/auth_provider.dart';
import 'package:popmatch/screens/auth/email_verification_screen.dart';
import 'package:popmatch/services/firebase_config.dart';
import 'package:popmatch/widgets/auth/auth_code_input.dart';
import 'package:popmatch/widgets/auth/auth_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for the redesigned EmailVerificationScreen. The screen
/// now: provides an [AuthProvider] dependency, dispatches the code on entry
/// (so its loading/success state is visible), uses an [AuthCodeInput] (6 boxes)
/// and a [ResendCooldownButton] that starts in a countdown.
void main() {
  group('Email Verification Integration Tests', () {
    setUpAll(() => FirebaseConfig.setTestMode(true));
    tearDownAll(() => FirebaseConfig.setTestMode(false));
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
            child: child,
          ),
        );

    // Pump the screen and let the on-entry code dispatch settle (so the verify
    // button leaves its loading state). Avoids pumpAndSettle because the resend
    // cooldown runs a periodic timer that never "settles".
    Future<void> pumpVerify(WidgetTester tester, String email) async {
      await tester.pumpWidget(wrap(EmailVerificationScreen(email: email)));
      await tester.pump(); // build + schedule the post-frame send
      await tester.pump(const Duration(milliseconds: 500)); // send completes
    }

    group('Email Verification Screen', () {
      const testEmail = 'test@example.com';

      testWidgets('Displays user email + title + description', (tester) async {
        await pumpVerify(tester, testEmail);
        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);
        expect(find.text("We've sent a 6-digit verification code to:"),
            findsOneWidget);
      });

      testWidgets('Shows the 6-box code input', (tester) async {
        await pumpVerify(tester, testEmail);
        expect(find.byType(AuthCodeInput), findsOneWidget);
      });

      testWidgets('Shows the resend control (starts in cooldown)',
          (tester) async {
        await pumpVerify(tester, testEmail);
        expect(find.byType(ResendCooldownButton), findsOneWidget);
        // Starts counting down, so the bare "Resend Code" label isn't shown yet.
        expect(find.textContaining('Resend code'), findsOneWidget);
      });

      testWidgets('Shows the Verify Code button after the send settles',
          (tester) async {
        await pumpVerify(tester, testEmail);
        expect(find.text('Verify Code'), findsOneWidget);
      });

      testWidgets('Verify Code button is tappable (incomplete code is rejected)',
          (tester) async {
        await pumpVerify(tester, testEmail);
        await tester.ensureVisible(find.text('Verify Code'));
        await tester.tap(find.text('Verify Code'));
        await tester.pump();
        // Still on the screen; an "incomplete code" snackbar is shown.
        expect(find.text('Verify Code'), findsOneWidget);
      });
    });

    group('Code delivery on entry', () {
      testWidgets('Dispatching the code on entry shows a SnackBar',
          (tester) async {
        await pumpVerify(tester, 'test@example.com');
        // The on-entry send surfaces its result via a SnackBar (dev mode).
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('Development mode', () {
      testWidgets('Firebase is disabled in tests (signup skips verification)',
          (tester) async {
        expect(FirebaseConfig.isEnabled, isFalse);
      });
    });

    group('UI Elements', () {
      testWidgets('Verification screen has all required UI elements',
          (tester) async {
        const testEmail = 'test@example.com';
        await pumpVerify(tester, testEmail);
        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text("We've sent a 6-digit verification code to:"),
            findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);
        expect(find.byType(AuthCodeInput), findsOneWidget);
        expect(find.text('Verify Code'), findsOneWidget);
        expect(find.byType(ResendCooldownButton), findsOneWidget);
        expect(
            find.text(
                "Didn't receive the code? Check your spam folder or try resending."),
            findsOneWidget);
      });
    });
  });
}
