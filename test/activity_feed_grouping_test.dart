import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/social_activity.dart';
import 'package:popmatch/screens/home/activity_feed_screen.dart';

SocialActivity _act(String id, DateTime when,
    {SocialActivityType type = SocialActivityType.liked}) {
  return SocialActivity(
    id: id,
    actorUid: 'u_$id',
    itemType: SocialItemType.movie,
    itemId: id,
    activityType: type,
    visibility: ActivityVisibility.followersOnly,
    createdAt: when,
  );
}

void main() {
  // Fixed "now" so the buckets are deterministic.
  final now = DateTime(2026, 6, 10, 12, 0);

  group('groupActivitiesByRecency', () {
    test('buckets into today / this week / earlier', () {
      final activities = [
        _act('today', DateTime(2026, 6, 10, 1)), // same calendar day
        _act('week', DateTime(2026, 6, 6, 9)), // 4 days ago
        _act('old', DateTime(2026, 5, 1)), // > 7 days ago
      ];

      final groups = groupActivitiesByRecency(activities, now: now);

      expect(groups.map((g) => g.bucket), [
        ActivityBucket.today,
        ActivityBucket.thisWeek,
        ActivityBucket.earlier,
      ]);
      expect(groups[0].activities.single.itemId, 'today');
      expect(groups[1].activities.single.itemId, 'week');
      expect(groups[2].activities.single.itemId, 'old');
    });

    test('drops empty buckets', () {
      final groups = groupActivitiesByRecency(
        [_act('old', DateTime(2026, 1, 1))],
        now: now,
      );
      expect(groups.length, 1);
      expect(groups.single.bucket, ActivityBucket.earlier);
    });

    test('sorts newest-first within a bucket', () {
      final groups = groupActivitiesByRecency([
        _act('a', DateTime(2026, 6, 10, 8)),
        _act('b', DateTime(2026, 6, 10, 11)),
        _act('c', DateTime(2026, 6, 10, 9)),
      ], now: now);

      expect(groups.single.bucket, ActivityBucket.today);
      expect(groups.single.activities.map((a) => a.itemId), ['b', 'c', 'a']);
    });

    test('returns empty for no activities', () {
      expect(groupActivitiesByRecency(const [], now: now), isEmpty);
    });
  });
}
