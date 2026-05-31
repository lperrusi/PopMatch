import 'package:flutter/widgets.dart';

/// Utility for detecting the user's country from the device locale.
class LocaleUtils {
  /// Returns the ISO 3166-1 alpha-2 country code from the device locale.
  /// Falls back to 'US' if the country code cannot be determined.
  ///
  /// Examples: pt-BR → 'BR', en-US → 'US', fr-FR → 'FR', en → 'US'
  static String detectCountryCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;

    // Prefer the explicit countryCode from the Locale object
    final code = locale.countryCode?.toUpperCase();
    if (code != null && code.length == 2) return code;

    // Fallback: parse the language tag e.g. "pt-BR" → "BR"
    final tag = locale.toLanguageTag();
    final parts = tag.split('-');
    if (parts.length >= 2 && parts.last.length == 2) {
      return parts.last.toUpperCase();
    }

    return 'US';
  }
}
