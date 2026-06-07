import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/auth_validators.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/auth/auth_code_input.dart';
import 'login_screen.dart';

enum _ResetStep { email, code, done }

/// Forgot-password flow using the same 6-digit code UX as sign-up:
/// (1) enter email → emailed a code; (2) enter code + new password →
/// server verifies and updates the password; (3) success → back to sign in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<AuthCodeInputState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  String _code = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  void _backToLogin() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()));

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await context
          .read<AuthProvider>()
          .sendPasswordResetCode(_emailController.text.trim());
      if (!mounted) return;
      // Backend never reveals whether the account exists — always advance.
      setState(() => _step = _ResetStep.code);
      _snack(context.l10n.resetCodeOnItsWay, AppTheme.popcornGold);
    } catch (e) {
      _snack(AuthErrorHandler.getErrorMessage(e), AppTheme.brickRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    _codeKey.currentState?.clear();
    await context
        .read<AuthProvider>()
        .sendPasswordResetCode(_emailController.text.trim());
  }

  Future<void> _confirm() async {
    if (AuthValidators.code(_code) != null) {
      _snack(context.l10n.resetEnterCodeError, AppTheme.brickRed);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().confirmPasswordResetWithCode(
            email: _emailController.text.trim(),
            code: _code,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _step = _ResetStep.done);
    } catch (e) {
      _snack(AuthErrorHandler.getErrorMessage(e), AppTheme.brickRed);
      _codeKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, subtitle) = switch (_step) {
      _ResetStep.email => (l10n.forgotPasswordTitle, l10n.forgotPasswordSubtitle),
      _ResetStep.code => (
          l10n.resetEnterCodeTitle,
          l10n.resetCodeSentTo(_emailController.text.trim())
        ),
      _ResetStep.done => (l10n.resetDoneTitle, l10n.resetDoneSubtitle),
    };
    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: title,
        subtitle: subtitle,
        onBack: _backToLogin,
        children: switch (_step) {
          _ResetStep.email => _emailStep(l10n),
          _ResetStep.code => _codeStep(l10n),
          _ResetStep.done => _doneStep(),
        },
      ),
    );
  }

  List<Widget> _emailStep(dynamic l10n) {
    return [
      AuthTextField(
        controller: _emailController,
        hint: l10n.emailHint,
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendCode(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return l10n.emailErrorEmpty;
          if (!RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim())) {
            return l10n.emailErrorInvalid;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: l10n.sendCodeButton,
        isLoading: _isLoading,
        onPressed: _sendCode,
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: _backToLogin,
          child: Text(l10n.backToLoginButton,
              style: GoogleFonts.lato(color: AppTheme.popcornGold)),
        ),
      ),
    ];
  }

  List<Widget> _codeStep(dynamic l10n) {
    return [
      AuthCodeInput(
        key: _codeKey,
        onChanged: (c) => setState(() => _code = c),
      ),
      const SizedBox(height: 20),
      AuthPasswordField(
        controller: _passwordController,
        hint: l10n.newPasswordHint,
        showStrength: true,
        validator: AuthValidators.password,
      ),
      const SizedBox(height: 16),
      AuthPasswordField(
        controller: _confirmController,
        hint: l10n.confirmNewPasswordHint,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confirm(),
        validator: (v) =>
            AuthValidators.confirmPassword(v, _passwordController.text),
      ),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: l10n.resetPasswordButton,
        isLoading: _isLoading,
        onPressed: _confirm,
      ),
      const SizedBox(height: 8),
      Center(
        child: ResendCooldownButton(onResend: _resend),
      ),
    ];
  }

  List<Widget> _doneStep() {
    return [
      const Icon(Icons.check_circle_rounded,
          color: AppTheme.popcornGold, size: 64),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: context.l10n.backToSignInButton,
        isLoading: false,
        onPressed: _backToLogin,
      ),
    ];
  }
}
