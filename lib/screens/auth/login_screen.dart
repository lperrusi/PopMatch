import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Login screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Wait a moment to ensure user data is fully loaded
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        if (authProvider.userData != null) {
          // CRITICAL: Double-check user data is loaded correctly
          // Sometimes the data might not be immediately available
          final userData = authProvider.userData;
          final email = _emailController.text.trim().toLowerCase();

          debugPrint('🔍 Login check - User: ${userData?.email}');
          debugPrint(
              '🔍 Login check - Email match: ${userData?.email.toLowerCase() == email}');
          debugPrint('🔍 Login check - Preferences: ${userData?.preferences}');

          // Check if onboarding is completed
          final onboardingCompleted =
              userData?.preferences['onboardingCompleted'] ?? false;
          debugPrint(
              '🔍 Login check - onboardingCompleted: $onboardingCompleted');

          // Verify the preference is actually a boolean true, not just truthy
          final isOnboardingCompleted = onboardingCompleted == true;
          debugPrint(
              '🔍 Login check - isOnboardingCompleted (strict): $isOnboardingCompleted');

          if (isOnboardingCompleted) {
            debugPrint('✅ Onboarding completed, navigating to HomeScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            debugPrint(
                '⚠️ Onboarding not completed, navigating to OnboardingScreen');
            debugPrint(
                '⚠️ Reason: onboardingCompleted = $onboardingCompleted (type: ${onboardingCompleted.runtimeType})');
            // Show onboarding for first-time login
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        } else if (authProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error!,
                style: const TextStyle(color: AppTheme.popcornGold),
              ),
              backgroundColor: AppTheme.filmStripBlack,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AuthErrorHandler.getErrorMessage(e),
              style: const TextStyle(color: AppTheme.popcornGold),
            ),
            backgroundColor: AppTheme.filmStripBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles Google sign in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (mounted && authProvider.userData != null) {
        // Check if onboarding is completed
        final onboardingCompleted =
            authProvider.userData?.preferences['onboardingCompleted'] ?? false;

        if (onboardingCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Show onboarding for first-time login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error!,
              style: const TextStyle(color: AppTheme.popcornGold),
            ),
            backgroundColor: AppTheme.filmStripBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AuthErrorHandler.getErrorMessage(e),
              style: const TextStyle(color: AppTheme.popcornGold),
            ),
            backgroundColor: AppTheme.filmStripBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to register screen
  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: AppTheme.authInputBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.authBorder, width: 1),
    );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PopMatch',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 48,
                        color: AppTheme.authCream,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/screens/figma/popcorn.png',
                      width: 128,
                      height: 128,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.movie_rounded,
                          size: 80,
                          color: AppTheme.authCream),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sign in to continue discovering movies',
                      style: GoogleFonts.lato(color: AppTheme.authCreamMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Email
                    Container(
                      decoration: _inputDecoration(),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.lato(color: AppTheme.authCream),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: GoogleFonts.lato(
                              color: AppTheme.authCream.withValues(alpha: 0.4)),
                          prefixIcon: Icon(Icons.mail_outline,
                              color: AppTheme.authCream.withValues(alpha: 0.6),
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
                    const SizedBox(height: 16),
                    // Password
                    Container(
                      decoration: _inputDecoration(),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.lato(color: AppTheme.authCream),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: GoogleFonts.lato(
                              color: AppTheme.authCream.withValues(alpha: 0.4)),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.authCream.withValues(alpha: 0.6),
                              size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.authCream.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
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
                    const SizedBox(height: 24),
                    // Sign In button (gradient)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.authRed, AppTheme.authRedDark],
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
                          onTap: _isLoading ? null : _handleLogin,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppTheme.authCream)),
                                  )
                                : Text(
                                    'Sign In',
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
                    Row(children: [
                      const Expanded(
                          child: Divider(color: AppTheme.authBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR',
                            style: GoogleFonts.lato(
                                color:
                                    AppTheme.authCream.withValues(alpha: 0.4),
                                fontSize: 14)),
                      ),
                      const Expanded(
                          child: Divider(color: AppTheme.authBorder)),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                            _googleIcon(),
                            const SizedBox(width: 12),
                            Text('Continue with Google',
                                style: GoogleFonts.lato(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen())),
                      child: Text('Forgot Password?',
                          style: GoogleFonts.lato(color: AppTheme.authRed)),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.lato(
                                color:
                                    AppTheme.authCream.withValues(alpha: 0.6))),
                        TextButton(
                          onPressed: _navigateToRegister,
                          child: Text('Sign Up',
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
