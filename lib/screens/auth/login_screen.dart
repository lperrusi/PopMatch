import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/auth/auth_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Login screen for user authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(color: AppTheme.popcornGold)),
        backgroundColor: AppTheme.filmStripBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _routeAfterAuth(AuthProvider authProvider) {
    final onboardingCompleted =
        authProvider.userData?.preferences['onboardingCompleted'] == true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (authProvider.userData != null) {
        _routeAfterAuth(authProvider);
      } else {
        _showError(authProvider.error ?? context.l10n.signInFailedError);
      }
    } catch (e) {
      _showError(AuthErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithGoogle();
      if (!mounted) return;
      if (authProvider.userData != null) {
        _routeAfterAuth(authProvider);
      } else if (authProvider.error != null) {
        _showError(authProvider.error!);
      }
    } catch (e) {
      _showError(AuthErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: l10n.appTitle,
        subtitle: l10n.signInSubtitle,
        children: [
          AuthTextField(
            controller: _emailController,
            hint: l10n.emailHint,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailErrorEmpty;
              if (!RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim())) {
                return l10n.emailErrorInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _passwordController,
            hint: l10n.passwordHint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.passwordErrorEmpty : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen())),
              child: Text(l10n.forgotPasswordButton,
                  style: GoogleFonts.lato(color: AppTheme.popcornGold)),
            ),
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            label: l10n.signInButton,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 24),
          _orDivider(l10n.orSeparator),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.authCream,
                foregroundColor: AppTheme.authBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _googleIcon(),
                  const SizedBox(width: 12),
                  Text(l10n.continueWithGoogleButton,
                      style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.noAccountPrompt,
                  style: GoogleFonts.lato(
                      color: AppTheme.authCream.withValues(alpha: 0.6))),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text(l10n.signUpLinkText,
                    style: GoogleFonts.lato(
                        color: AppTheme.popcornGold,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.authBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label,
              style: GoogleFonts.lato(
                  color: AppTheme.authCream.withValues(alpha: 0.4),
                  fontSize: 14)),
        ),
        const Expanded(child: Divider(color: AppTheme.authBorder)),
      ],
    );
  }

  Widget _googleIcon() {
    return Image.network(
      'https://www.google.com/favicon.ico',
      width: 20,
      height: 20,
      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata,
          size: 24, color: AppTheme.authBackground),
    );
  }
}
