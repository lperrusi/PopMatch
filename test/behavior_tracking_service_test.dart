import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/services/behavior_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = BehaviorTrackingService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service.resetForTest();
  });

  group('BehaviorTrackingService persistence', () {
    test('like interest signal round-trips across a reset', () async {
      service.recordSwipe('u1', 7, 'like');
      await service.saveForTest();

      service.resetForTest();
      await service.initialize();

      expect(service.getInterestScore(7), greaterThanOrEqualTo(1.0));
    });

    test('skipped movie stays hidden, then resurfaces after N launches',
        () async {
      service.recordSwipe('u1', 42, 'skip');
      await service.saveForTest();

      // Counter starts at kSkipResurfaceLaunches; each initialize() ages it by 1.
      for (var i = 0;
          i < BehaviorTrackingService.kSkipResurfaceLaunches - 1;
          i++) {
        service.resetForTest();
        await service.initialize();
        expect(service.getSkippedMovies('u1'), contains(42),
            reason: 'still hidden at launch ${i + 1}');
      }

      // The final aging drops the counter to zero → the movie resurfaces.
      service.resetForTest();
      await service.initialize();
      expect(service.getSkippedMovies('u1'), isNot(contains(42)));
    });

    test('initialize is idempotent within a run (does not double-age)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('behavior_skips', jsonEncode({
        'u1': {'99': 2},
      }));

      service.resetForTest();
      await service.initialize(); // ages 2 -> 1
      await service.initialize(); // guarded no-op (no further aging)

      expect(service.getSkippedMovies('u1'), contains(99));
    });
  });
}
