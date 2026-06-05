import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/l10n_extension.dart';
import '../../services/firebase_config.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Sign-up screen: name, email, password (+strength), confirm → email verification.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.authRed,
          behavior: SnackBarBehavior.floating),
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      await authProvider.signUpWithEmailAndPassword(
        email,
        _passwordController.text,
        _displayNameController.text.trim(),
      );
      if (!mounted) return;
      if (authProvider.userData != null) {
        if (FirebaseConfig.isEnabled) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email)));
        } else {
          _routeAfterAuth(authProvider);
        }
      } else if (authProvider.error != null) {
        _showError(authProvider.error!);
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

  void _backToLogin() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: l10n.joinPopMatchTitle,
        subtitle: l10n.registerSubtitle,
        onBack: _backToLogin,
        children: [
          AuthTextField(
            controller: _displayNameController,
            hint: l10n.displayNameHint,
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return l10n.displayNameErrorEmpty;
              if (t.length < 2) return l10n.displayNameErrorTooShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            hint: l10n.emailHint,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailErrorEmpty;
              if (!RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$')
                  .hasMatch(v.trim())) {
                return l10n.emailErrorInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _passwordController,
            hint: l10n.passwordHint,
            showStrength: true,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.passwordErrorEmpty;
              if (v.length < 6) return l10n.passwordErrorTooShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _confirmPasswordController,
            hint: l10n.confirmPasswordHint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRegister(),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.confirmPasswordErrorEmpty;
              if (v != _passwordController.text) {
                return l10n.confirmPasswordErrorMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: l10n.createAccountButton,
            isLoading: _isLoading,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 20),
          _orDivider(l10n.orSeparator),
          const SizedBox(height: 20),
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
                  Image.network('https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: AppTheme.authBackground)),
                  const SizedBox(width: 12),
                  Text(l10n.continueWithGoogleButton,
                      style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.alreadyHaveAccountPrompt,
                  style: GoogleFonts.lato(
                      color: AppTheme.authCream.withValues(alpha: 0.6))),
              TextButton(
                onPressed: _backToLogin,
                child: Text(l10n.signInLinkText,
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
}
