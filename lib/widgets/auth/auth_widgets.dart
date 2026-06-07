import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../utils/auth_validators.dart';
import '../../utils/l10n_extension.dart';

/// Shared chrome for every auth screen: background, optional back button,
/// popcorn logo, title + subtitle, and a scrollable form body.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onBack,
  });

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left, size: 28),
                      color: AppTheme.authCream,
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        24, onBack != null ? 8 : 48, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/screens/figma/popcorn.png',
                            width: 112,
                            height: 112,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_rounded,
                                size: 72,
                                color: AppTheme.popcornGold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 38,
                            color: AppTheme.authCream,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                color: AppTheme.authCreamMuted, fontSize: 15),
                          ),
                        ],
                        const SizedBox(height: 28),
                        ...children,
                      ],
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

/// Rounded, cream-on-dark text field used across auth screens.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      cursorColor: AppTheme.creamyWhite,
      style: GoogleFonts.lato(color: AppTheme.authCream),
      decoration: _authInputDecoration(hint: hint, icon: icon),
    );
  }
}

/// Password field with a show/hide toggle and an optional strength meter.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showStrength;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.hint = 'Password',
    this.validator,
    this.onChanged,
    this.showStrength = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          validator: widget.validator,
          onChanged: (v) {
            if (widget.showStrength) setState(() {});
            widget.onChanged?.call(v);
          },
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: AppTheme.creamyWhite,
          style: GoogleFonts.lato(color: AppTheme.authCream),
          decoration: _authInputDecoration(
            hint: widget.hint,
            icon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.authCream.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
        ),
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordStrengthMeter(password: widget.controller.text),
        ],
      ],
    );
  }
}

/// A thin strength bar + label driven by [estimatePasswordStrength].
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = estimatePasswordStrength(password);
    final l10n = context.l10n;
    final (fraction, color, label) = switch (strength) {
      PasswordStrength.weak => (0.33, AppTheme.authRed, l10n.passwordStrengthWeak),
      PasswordStrength.fair =>
        (0.66, AppTheme.popcornGold, l10n.passwordStrengthFair),
      PasswordStrength.strong =>
        (1.0, const Color(0xFF6FBF73), l10n.passwordStrengthStrong),
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppTheme.authBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.lato(color: color, fontSize: 12)),
      ],
    );
  }
}

/// Primary red auth action button with built-in loading + disabled states.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.authRed,
          foregroundColor: AppTheme.authCream,
          disabledBackgroundColor: AppTheme.authRed.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.authCream)),
              )
            : Text(label,
                style: GoogleFonts.bebasNeue(
                    fontSize: 18, letterSpacing: 1.0)),
      ),
    );
  }
}

/// "Resend code" button that disables and counts down for [cooldownSeconds]
/// after each press (and after first mount, to reflect the just-sent code).
class ResendCooldownButton extends StatefulWidget {
  final Future<void> Function() onResend;
  final int cooldownSeconds;
  final bool startCoolingDown;

  const ResendCooldownButton({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 45,
    this.startCoolingDown = true,
  });

  @override
  State<ResendCooldownButton> createState() => _ResendCooldownButtonState();
}

class _ResendCooldownButtonState extends State<ResendCooldownButton> {
  Timer? _timer;
  int _remaining = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.startCoolingDown) _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  Future<void> _handle() async {
    setState(() => _sending = true);
    try {
      await widget.onResend();
      if (mounted) _startCooldown();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining <= 0 && !_sending;
    return TextButton(
      onPressed: canResend ? _handle : null,
      child: Text(
        _remaining > 0
            ? context.l10n.resendCodeInSeconds(_remaining)
            : context.l10n.resendCodeButton,
        style: GoogleFonts.lato(
          color: canResend
              ? AppTheme.popcornGold
              : AppTheme.authCream.withValues(alpha: 0.4),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shared input decoration so every auth field looks identical.
InputDecoration _authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    filled: true,
    fillColor: AppTheme.authInputBg,
    hintText: hint,
    hintStyle: GoogleFonts.lato(color: AppTheme.authCream.withValues(alpha: 0.4)),
    prefixIcon:
        Icon(icon, color: AppTheme.authCream.withValues(alpha: 0.6), size: 20),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(AppTheme.authBorder),
    focusedBorder: border(AppTheme.popcornGold),
    errorBorder: border(AppTheme.authRed),
    focusedErrorBorder: border(AppTheme.authRed),
    errorStyle: GoogleFonts.lato(color: AppTheme.authRed, fontSize: 12),
  );
}
