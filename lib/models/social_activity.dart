enum SocialActivityType { liked, watchlisted, watched }
enum SocialItemType { movie, show }
enum ActivityVisibility { public, followersOnly, private }

class SocialActivity {
  final String id;
  final String actorUid;
  final SocialItemType itemType;
  final String itemId;
  final SocialActivityType activityType;
  final ActivityVisibility visibility;
  final DateTime createdAt;
  final String? actorDisplayName;

  const SocialActivity({
    required this.id,
    required this.actorUid,
    required this.itemType,
    required this.itemId,
    required this.activityType,
    required this.visibility,
    required this.createdAt,
    this.actorDisplayName,
  });

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    return SocialActivity(
      id: json['id'] as String? ?? '',
      actorUid: json['actorUid'] as String? ?? '',
      itemType: _itemTypeFromString(json['itemType'] as String?),
      itemId: json['itemId'] as String? ?? '',
      activityType: _activityTypeFromString(json['activityType'] as String?),
      visibility: _visibilityFromString(json['visibility'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      actorDisplayName: json['actorDisplayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorUid': actorUid,
      'itemType': itemType.name,
      'itemId': itemId,
      'activityType': activityType.name,
      'visibility': visibility.name,
      'createdAt': createdAt.toIso8601String(),
      if (actorDisplayName != null) 'actorDisplayName': actorDisplayName,
    };
  }

  static SocialItemType _itemTypeFromString(String? value) {
    switch (value) {
      case 'show':
        return SocialItemType.show;
      case 'movie':
      default:
        return SocialItemType.movie;
    }
  }

  static SocialActivityType _activityTypeFromString(String? value) {
    switch (value) {
      case 'watchlisted':
        return SocialActivityType.watchlisted;
      case 'watched':
        return SocialActivityType.watched;
      case 'liked':
      default:
        return SocialActivityType.liked;
    }
  }

  static ActivityVisibility _visibilityFromString(String? value) {
    switch (value) {
      case 'public':
        return ActivityVisibility.public;
      case 'private':
        return ActivityVisibility.private;
      case 'followersOnly':
      default:
        return ActivityVisibility.followersOnly;
    }
  }
}
