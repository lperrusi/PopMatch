import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/social_activity.dart';
import 'package:popmatch/providers/social_provider.dart';

SocialActivity _liked({
  required String actorUid,
  required String itemId,
  SocialItemType itemType = SocialItemType.movie,
  String? actorDisplayName,
  SocialActivityType activityType = SocialActivityType.liked,
}) {
  return SocialActivity(
    id: '$actorUid-$itemId-${itemType.name}',
    actorUid: actorUid,
    itemType: itemType,
    itemId: itemId,
    activityType: activityType,
    visibility: ActivityVisibility.followersOnly,
    createdAt: DateTime(2026, 1, 1),
    actorDisplayName: actorDisplayName,
  );
}

void main() {
  group('SocialProvider.computeFriendMatches', () {
    test('returns only titles the user also liked, grouped per friend', () {
      final feed = [
        _liked(actorUid: 'alice', itemId: '603', actorDisplayName: 'Alice'),
        _liked(actorUid: 'alice', itemId: '999', actorDisplayName: 'Alice'),
        _liked(actorUid: 'bob', itemId: '603', actorDisplayName: 'Bob'),
      ];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'603'}, // user did not like 999
        myLikedShowIds: {},
      );

      expect(matches.length, 2);
      final alice = matches.firstWhere((m) => m.friendUid == 'alice');
      expect(alice.items.map((i) => i.itemId), ['603']); // 999 excluded
      expect(alice.friendName, 'Alice');
      final bob = matches.firstWhere((m) => m.friendUid == 'bob');
      expect(bob.items.single.itemId, '603');
    });

    test('separates movies and shows by id space', () {
      final feed = [
        _liked(actorUid: 'alice', itemId: '10', itemType: SocialItemType.movie),
        _liked(actorUid: 'alice', itemId: '10', itemType: SocialItemType.show),
      ];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'10'},
        myLikedShowIds: {}, // show 10 not liked
      );

      expect(matches.single.items.length, 1);
      expect(matches.single.items.single.itemType, SocialItemType.movie);
    });

    test('excludes self and non-liked activity types', () {
      final feed = [
        _liked(actorUid: 'me', itemId: '603'),
        _liked(
            actorUid: 'alice',
            itemId: '603',
            activityType: SocialActivityType.watchlisted),
        _liked(actorUid: 'alice', itemId: '603'),
      ];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'603'},
        myLikedShowIds: {},
        selfUid: 'me',
      );

      expect(matches.length, 1);
      expect(matches.single.friendUid, 'alice');
      expect(matches.single.items.length, 1); // watchlisted not counted
    });

    test('de-dupes repeated items within a friend', () {
      final feed = [
        _liked(actorUid: 'alice', itemId: '603'),
        _liked(actorUid: 'alice', itemId: '603'),
      ];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'603'},
        myLikedShowIds: {},
      );

      expect(matches.single.items.length, 1);
    });

    test('sorts friends by match count descending', () {
      final feed = [
        _liked(actorUid: 'alice', itemId: '1'),
        _liked(actorUid: 'bob', itemId: '1'),
        _liked(actorUid: 'bob', itemId: '2'),
        _liked(actorUid: 'bob', itemId: '3'),
      ];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'1', '2', '3'},
        myLikedShowIds: {},
      );

      expect(matches.first.friendUid, 'bob'); // 3 matches before alice's 1
      expect(matches.first.count, 3);
    });

    test('returns empty when there is no overlap', () {
      final feed = [_liked(actorUid: 'alice', itemId: '603')];

      final matches = SocialProvider.computeFriendMatches(
        feed: feed,
        myLikedMovieIds: {'111'},
        myLikedShowIds: {},
      );

      expect(matches, isEmpty);
    });
  });
}
