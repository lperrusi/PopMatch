/// Single source of truth for auth form validation, shared across the
/// sign-in, sign-up, forgot-password, and verification screens.
class AuthValidators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// Returns an error message, or null if [value] is a valid email.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Returns an error message, or null if [value] is an acceptable password.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// For sign-in we only require non-empty (don't reveal length rules).
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password';
    return null;
  }

  /// Returns an error message, or null if [confirm] matches [original].
  static String? confirmPassword(String? confirm, String? original) {
    if ((confirm ?? '').isEmpty) return 'Please confirm your password';
    if (confirm != original) return 'Passwords do not match';
    return null;
  }

  /// Validates a display name (optional-friendly: only checks length if given).
  static String? displayName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  /// Validates a 6-digit verification code.
  static String? code(String? value) {
    final v = (value ?? '').trim();
    if (v.length != 6 || int.tryParse(v) == null) {
      return 'Enter the 6-digit code';
    }
    return null;
  }
}

/// Coarse password-strength estimate for the strength meter.
enum PasswordStrength { weak, fair, strong }

extension PasswordStrengthX on PasswordStrength {
  String get label => switch (this) {
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Fair',
        PasswordStrength.strong => 'Strong',
      };
}

/// Estimates password strength from length + character-class variety.
PasswordStrength estimatePasswordStrength(String password) {
  if (password.length < 6) return PasswordStrength.weak;
  var classes = 0;
  if (RegExp(r'[a-z]').hasMatch(password)) classes++;
  if (RegExp(r'[A-Z]').hasMatch(password)) classes++;
  if (RegExp(r'[0-9]').hasMatch(password)) classes++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) classes++;
  if (password.length >= 10 && classes >= 3) return PasswordStrength.strong;
  if (password.length >= 8 && classes >= 2) return PasswordStrength.fair;
  return PasswordStrength.weak;
}
