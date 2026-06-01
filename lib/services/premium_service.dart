import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal premium-entitlement seam.
///
/// The app's model is swipe-based: free users get a swipe cap + ads; premium
/// gets unlimited swipes, ad-free, and premium-only surfaces (e.g. "For You").
/// This is a **stub** — entitlement is a persisted flag, dev-togglable via
/// [setPremium]. The monetization axis will later back it with real IAP /
/// receipt validation without changing call sites that read [isPremium].
class PremiumService extends ChangeNotifier {
  static const String _prefsKey = 'premium_active';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// Loads the persisted entitlement. Call once at startup (and awaitable in
  /// tests). Safe to call more than once.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_prefsKey) ?? false;
      if (value != _isPremium) {
        _isPremium = value;
        notifyListeners();
      }
    } catch (_) {
      // Default to non-premium on any storage error.
    }
  }

  /// Sets and persists the entitlement. (Dev/testing today; real purchase later.)
  Future<void> setPremium(bool value) async {
    if (_isPremium != value) {
      _isPremium = value;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // Keep the in-memory value even if persistence fails.
    }
  }
}
