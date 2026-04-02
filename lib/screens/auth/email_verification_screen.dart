import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/auth_error_handler.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';

/// Email verification screen shown after sign-up
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Handles code input and auto-advances to next field
  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (index == 5 && value.length == 1) {
      final code = _codeControllers.map((c) => c.text).join();
      if (code.length == 6) {
        _verifyCode(code);
      }
    }
  }

  /// Verifies the entered code
  Future<void> _verifyCode(String code) async {
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a 6-digit code'),
          backgroundColor: AppTheme.brickRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isValid = await authProvider.verifyCode(widget.email, code);

      if (mounted) {
        if (isValid) {
          // Code is valid - mark email as verified and navigate to onboarding
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // User is already signed in (we kept them signed in during verification)
          // Navigate directly to onboarding
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Check if onboarding is already completed
          final onboardingCompleted =
              authProvider.userData?.preferences['onboardingCompleted'] ??
                  false;

          if (onboardingCompleted) {
            // If already completed, go to home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            // Navigate to onboarding
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        } else {
          // Invalid code
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Invalid verification code. Please try again.'),
              backgroundColor: AppTheme.brickRed,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Clear all fields
          for (var controller in _codeControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: AppTheme.brickRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  /// Handles resending verification code
  Future<void> _resendVerificationCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendVerificationCodeEmail(widget.email);

      if (mounted) {
        final delivery = authProvider.lastVerificationDelivery;
        final message = switch (delivery) {
          VerificationCodeDelivery.cloudEmailSent =>
            'Verification code sent! Please check your email.',
          VerificationCodeDelivery.fallbackCodeGenerated =>
            'Email service is currently unavailable. Your code was generated in-app for verification.',
          VerificationCodeDelivery.devModeCodeGenerated =>
            'Code generated in development mode. Check debug logs for the code.',
          null => 'Verification code generated. Please try again if needed.',
        };
        final bgColor = delivery == VerificationCodeDelivery.cloudEmailSent
            ? Colors.green
            : AppTheme.popcornGold;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear code fields
        for (var controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: AppTheme.brickRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepMidnightBrown,
              AppTheme.filmStripBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.popcornGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 60,
                    color: AppTheme.popcornGold,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmCream,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'We\'ve sent a 6-digit verification code to:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.warmCream.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Email address
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.popcornGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.popcornGold,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Code input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 60,
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warmCream,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor:
                              AppTheme.filmStripBlack.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  AppTheme.popcornGold.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  AppTheme.popcornGold.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.popcornGold,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Verify button
                ElevatedButton(
                  onPressed: _isVerifying
                      ? null
                      : () {
                          final code =
                              _codeControllers.map((c) => c.text).join();
                          if (code.length == 6) {
                            _verifyCode(code);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please enter the complete 6-digit code'),
                                backgroundColor: AppTheme.brickRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.popcornGold,
                    foregroundColor: AppTheme.filmStripBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Resend button
                TextButton(
                  onPressed: _isResending ? null : _resendVerificationCode,
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: AppTheme.popcornGold,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Resend Code',
                              style: TextStyle(
                                color: AppTheme.popcornGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // Help text
                Text(
                  'Didn\'t receive the code? Check your spam folder or try resending.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warmCream.withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
