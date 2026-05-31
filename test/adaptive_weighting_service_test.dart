import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/services/adaptive_weighting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Single source of truth for the service's default weights.
  const defaults = {
    'contentBased': 0.40,
    'contextual': 0.20,
    'behavior': 0.15,
    'embedding': 0.20,
    'collaborative': 0.05,
  };

  group('AdaptiveWeightingService persistence', () {
    final service = AdaptiveWeightingService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Force the in-memory singleton back to defaults before each test.
      await service.resetWeights('seed');
    });

    test('restores previously saved weights (round-trip)', () async {
      const custom = {
        'contentBased': 0.30,
        'contextual': 0.10,
        'behavior': 0.25,
        'embedding': 0.30,
        'collaborative': 0.05,
      };
      final prefs = await SharedPreferences.getInstance();
      // Mirrors exactly what _saveWeights writes.
      await prefs.setString('adaptive_weights_userA', jsonEncode(custom));

      await service.loadWeights('userA');

      expect(service.getWeights(), equals(custom));
    });

    test('keeps defaults when stored value is corrupt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adaptive_weights_userB', 'not-json{');

      await service.loadWeights('userB');

      expect(service.getWeights(), equals(defaults));
    });

    test('keeps defaults when stored map is missing keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'adaptive_weights_userC', jsonEncode({'contentBased': 0.9}));

      await service.loadWeights('userC');

      expect(service.getWeights(), equals(defaults));
    });

    test('keeps defaults when no value is stored', () async {
      await service.loadWeights('never_saved_user');
      expect(service.getWeights(), equals(defaults));
    });

    test('resetWeights writes a valid JSON map that decodes to defaults',
        () async {
      await service.resetWeights('userD');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('adaptive_weights_userD');
      expect(raw, isNotNull);

      final decoded = (jsonDecode(raw!) as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      expect(decoded, equals(defaults));
    });
  });
}
