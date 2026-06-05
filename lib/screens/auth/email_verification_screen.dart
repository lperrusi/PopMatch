import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/auth/auth_code_input.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

/// Email verification: enters the 6-digit code sent on entry, with resend
/// cooldown and real send-failure handling.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeKey = GlobalKey<AuthCodeInputState>();
  String _code = '';
  bool _isVerifying = false;
  bool _sending = true; // true while the initial code is dispatched

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _sendCode(initial: true));
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _sendCode({bool initial = false}) async {
    if (initial) setState(() => _sending = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendVerificationCodeEmail(widget.email);
      if (!mounted) return;
      final delivery = authProvider.lastVerificationDelivery;
      final l10n = context.l10n;
      final message = switch (delivery) {
        VerificationCodeDelivery.cloudEmailSent =>
          l10n.verificationCodeSentMessage,
        VerificationCodeDelivery.fallbackCodeGenerated =>
          l10n.verificationCodeFallbackMessage,
        VerificationCodeDelivery.devModeCodeGenerated =>
          l10n.verificationCodeDevMessage,
        null => l10n.verificationCodeGeneratedMessage,
      };
      _snack(
        message,
        delivery == VerificationCodeDelivery.cloudEmailSent
            ? Colors.green
            : AppTheme.popcornGold,
      );
    } catch (e) {
      // A real send failure (e.g. backend/IAM) is surfaced — no silent swallow.
      _snack(AuthErrorHandler.getErrorMessage(e), AppTheme.brickRed);
      rethrow; // let ResendCooldownButton know it failed (no cooldown restart)
    } finally {
      if (mounted && initial) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _code;
    if (code.length != 6) {
      _snack(context.l10n.incompleteCodeError, AppTheme.brickRed);
      return;
    }
    setState(() => _isVerifying = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final isValid = await authProvider.verifyCode(widget.email, code);
      if (!mounted) return;
      if (isValid) {
        _snack(context.l10n.emailVerificationSuccess, Colors.green);
        final onboardingCompleted =
            authProvider.userData?.preferences['onboardingCompleted'] == true;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => onboardingCompleted
                ? const HomeScreen()
                : const OnboardingScreen()));
      } else {
        _snack(context.l10n.invalidCodeError, AppTheme.brickRed);
        _codeKey.currentState?.clear();
      }
    } catch (e) {
      _snack(AuthErrorHandler.getErrorMessage(e), AppTheme.brickRed);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.verifyEmailTitle,
      subtitle: l10n.verificationCodeDescription,
      onBack: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen())),
      children: [
        Text(
          widget.email,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
              color: AppTheme.popcornGold, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        AuthCodeInput(
          key: _codeKey,
          onChanged: (c) => setState(() => _code = c),
          onCompleted: (_) => _verifyCode(),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.emailVerificationHelper,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
              color: AppTheme.authCreamMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: l10n.verifyCodeButton,
          isLoading: _isVerifying || _sending,
          onPressed: _code.length == 6 ? _verifyCode : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: ResendCooldownButton(
            startCoolingDown: true,
            onResend: () async {
              _codeKey.currentState?.clear();
              await _sendCode();
            },
          ),
        ),
      ],
    );
  }
}
