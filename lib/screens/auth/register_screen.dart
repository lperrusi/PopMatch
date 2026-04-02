import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../services/firebase_config.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Sign-up screen (Figma): back, popcorn, JOIN POPMATCH, Email, Display Name, Password, Confirm, Create Account, Google
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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: AppTheme.authInputBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.authBorder),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final email = _emailController.text.trim();
      await authProvider.signUpWithEmailAndPassword(
        email,
        _passwordController.text,
        _displayNameController.text.trim(),
      );
      if (mounted && authProvider.userData != null) {
        if (FirebaseConfig.isEnabled) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => EmailVerificationScreen(email: email)),
          );
        } else {
          final onboardingCompleted =
              authProvider.userData?.preferences['onboardingCompleted'] ??
                  false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => onboardingCompleted
                  ? const HomeScreen()
                  : const OnboardingScreen(),
            ),
          );
        }
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: AppTheme.authRed,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: AppTheme.authRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      if (mounted && authProvider.userData != null) {
        final onboardingCompleted =
            authProvider.userData?.preferences['onboardingCompleted'] ?? false;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => onboardingCompleted
                ? const HomeScreen()
                : const OnboardingScreen(),
          ),
        );
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: AppTheme.authRed,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: AppTheme.authRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/screens/figma/background_auth.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.authBackground),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: AppTheme.authCream,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/screens/figma/popcorn.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_rounded,
                                size: 64,
                                color: AppTheme.authCream),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'JOIN POPMATCH',
                            style: GoogleFonts.bebasNeue(
                                fontSize: 36,
                                color: AppTheme.authCream,
                                letterSpacing: 0.05),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create an account to start discovering movies',
                            style: GoogleFonts.lato(
                                color: AppTheme.authCreamMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: _inputDecoration(),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style:
                                  GoogleFonts.lato(color: AppTheme.authCream),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: GoogleFonts.lato(
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.mail_outline,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: _inputDecoration(),
                            child: TextFormField(
                              controller: _displayNameController,
                              style:
                                  GoogleFonts.lato(color: AppTheme.authCream),
                              decoration: InputDecoration(
                                hintText: 'Display Name',
                                hintStyle: GoogleFonts.lato(
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your display name';
                                }
                                if (v.length < 2) {
                                  return 'Display name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: _inputDecoration(),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style:
                                  GoogleFonts.lato(color: AppTheme.authCream),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: GoogleFonts.lato(
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: _inputDecoration(),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              style:
                                  GoogleFonts.lato(color: AppTheme.authCream),
                              decoration: InputDecoration(
                                hintText: 'Confirm Password',
                                hintStyle: GoogleFonts.lato(
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.authCream
                                        .withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.authRed,
                                  AppTheme.authRedDark
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isLoading ? null : _handleRegister,
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppTheme.authCream),
                                          ),
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.bebasNeue(
                                              fontSize: 18,
                                              letterSpacing: 0.05,
                                              color: AppTheme.authCream),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: AppTheme.authBorder)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR',
                                    style: GoogleFonts.lato(
                                        color: AppTheme.authCream
                                            .withValues(alpha: 0.4),
                                        fontSize: 14)),
                              ),
                              const Expanded(
                                  child: Divider(color: AppTheme.authBorder)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.authCream,
                                foregroundColor: AppTheme.authBackground,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.google.com/favicon.ico',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.g_mobiledata,
                                        size: 24,
                                        color: AppTheme.authBackground),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Continue with Google',
                                      style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ',
                                  style: GoogleFonts.lato(
                                      color: AppTheme.authCream
                                          .withValues(alpha: 0.6))),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushReplacement(MaterialPageRoute(
                                        builder: (_) => const LoginScreen())),
                                child: Text('Sign In',
                                    style: GoogleFonts.lato(
                                        color: AppTheme.authRed,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
