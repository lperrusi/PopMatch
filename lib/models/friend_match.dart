import 'social_activity.dart';

/// A single title that a friend and the current user both liked.
class MatchItem {
  final String itemId;
  final SocialItemType itemType;

  const MatchItem({required this.itemId, required this.itemType});

  /// Stable de-dupe key (`movie:603`, `show:1399`).
  String get key => '${itemType.name}:$itemId';
}

/// All the mutual likes between the current user and one friend.
class FriendMatch {
  final String friendUid;
  final String friendName;
  final List<MatchItem> items;

  const FriendMatch({
    required this.friendUid,
    required this.friendName,
    required this.items,
  });

  int get count => items.length;
}
