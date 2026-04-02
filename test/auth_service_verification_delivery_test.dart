import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/services/auth_service.dart';
import 'package:popmatch/services/firebase_config.dart';

void main() {
  group('AuthService verification delivery', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FirebaseConfig.setTestMode(true);
      authService = AuthService();
    });

    tearDown(() {
      FirebaseConfig.setTestMode(false);
    });

    test('uses deterministic dev-mode delivery when Firebase is disabled', () async {
      final delivery = await authService.sendVerificationCodeEmail('test@example.com');

      expect(delivery, VerificationCodeDelivery.devModeCodeGenerated);

      final prefs = await SharedPreferences.getInstance();
      final storedCodesJson = prefs.getString('verification_codes');
      expect(storedCodesJson, isNotNull);

      final storedCodes = Map<String, dynamic>.from(
        jsonDecode(storedCodesJson!),
      );
      expect(storedCodes.containsKey('test@example.com'), isTrue);
      expect(storedCodes['test@example.com']['code'], isA<String>());
    });
  });
}
