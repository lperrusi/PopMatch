import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import 'login_screen.dart';

/// Forgot password screen (Figma): back, popcorn, title, email input, Send Reset Link / success state
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _emailSent = false;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? AuthErrorHandler.getErrorMessage(e),
              style: const TextStyle(color: AppTheme.authCream),
            ),
            backgroundColor: AppTheme.authBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _navigateToLogin,
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: AppTheme.authCream,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
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
                            _emailSent
                                ? 'CHECK YOUR EMAIL'
                                : 'FORGOT PASSWORD?',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 36,
                              color: AppTheme.authCream,
                              letterSpacing: 0.05,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _emailSent
                                ? "We've sent a password reset link to ${_emailController.text.trim()}"
                                : "No worries! Enter your email and we'll send you reset instructions.",
                            style: GoogleFonts.lato(
                                color: AppTheme.authCreamMuted, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (!_emailSent) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.authInputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.authBorder),
                              ),
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
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(v)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleSendResetEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.authRed,
                                  foregroundColor: AppTheme.authCream,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  disabledBackgroundColor:
                                      AppTheme.authRed.withValues(alpha: 0.5),
                                ),
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
                                    : Text('Send Reset Link',
                                        style: GoogleFonts.bebasNeue(
                                            fontSize: 18, letterSpacing: 0.05)),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.authInputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.authRed
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                "Didn't receive the email? Check your spam folder or try again in a few minutes.",
                                style: GoogleFonts.lato(
                                    color: AppTheme.authCream, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _emailSent = false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppTheme.authRed, width: 2),
                                  foregroundColor: AppTheme.authCream,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Resend Email',
                                    style: GoogleFonts.bebasNeue(
                                        fontSize: 18, letterSpacing: 0.05)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: _navigateToLogin,
                              child: Text('Back to Login',
                                  style: GoogleFonts.lato(
                                      color: AppTheme.authRed)),
                            ),
                          ],
                          if (!_emailSent) ...[
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed: _navigateToLogin,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Remember your password? ',
                                      style: GoogleFonts.lato(
                                          color: AppTheme.authCream
                                              .withValues(alpha: 0.6),
                                          fontSize: 14)),
                                  Text('Sign In',
                                      style: GoogleFonts.lato(
                                          color: AppTheme.authRed,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
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
