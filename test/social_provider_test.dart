import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/providers/social_provider.dart';
import 'package:popmatch/models/social_privacy_settings.dart';
import 'package:popmatch/services/firebase_config.dart';

void main() {
  group('SocialProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FirebaseConfig.setTestMode(true);
    });

    tearDown(() {
      FirebaseConfig.setTestMode(false);
    });

    test('initialize loads defaults without Firebase', () async {
      final provider = SocialProvider();
      await provider.initialize();

      expect(provider.error, isNull);
      expect(provider.incomingRequests, isEmpty);
      expect(provider.friendsFeed, isEmpty);
      expect(provider.privacy.allowFollowers, isTrue);
    });

    test('updatePrivacy updates local state', () async {
      final provider = SocialProvider();
      const updated = SocialPrivacySettings(
        allowFollowers: false,
        shareLikes: false,
        shareWatchlist: true,
        shareWatchingActivity: false,
      );

      await provider.updatePrivacy(updated);

      expect(provider.privacy.allowFollowers, isFalse);
      expect(provider.privacy.shareLikes, isFalse);
      expect(provider.privacy.shareWatchlist, isTrue);
      expect(provider.privacy.shareWatchingActivity, isFalse);
    });
  });
}
