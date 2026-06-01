import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('PremiumService', () {
    test('defaults to not premium', () async {
      final service = PremiumService();
      await service.initialize();
      expect(service.isPremium, isFalse);
    });

    test('setPremium persists and a fresh instance reloads it', () async {
      final service = PremiumService();
      await service.initialize();

      var notified = false;
      service.addListener(() => notified = true);
      await service.setPremium(true);

      expect(service.isPremium, isTrue);
      expect(notified, isTrue);

      // A new instance should load the persisted entitlement.
      final reloaded = PremiumService();
      await reloaded.initialize();
      expect(reloaded.isPremium, isTrue);
    });

    test('setPremium(false) clears the entitlement', () async {
      final service = PremiumService();
      await service.setPremium(true);
      await service.setPremium(false);
      expect(service.isPremium, isFalse);

      final reloaded = PremiumService();
      await reloaded.initialize();
      expect(reloaded.isPremium, isFalse);
    });
  });
}
