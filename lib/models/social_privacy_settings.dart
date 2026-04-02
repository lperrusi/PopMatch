class SocialPrivacySettings {
  final bool allowFollowers;
  final bool shareLikes;
  final bool shareWatchlist;
  final bool shareWatchingActivity;
  final String activityVisibility; // public | followersOnly | private

  const SocialPrivacySettings({
    this.allowFollowers = true,
    this.shareLikes = true,
    this.shareWatchlist = true,
    this.shareWatchingActivity = true,
    this.activityVisibility = 'followersOnly',
  });

  factory SocialPrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SocialPrivacySettings();
    return SocialPrivacySettings(
      allowFollowers: map['allowFollowers'] as bool? ?? true,
      shareLikes: map['shareLikes'] as bool? ?? true,
      shareWatchlist: map['shareWatchlist'] as bool? ?? true,
      shareWatchingActivity: map['shareWatchingActivity'] as bool? ?? true,
      activityVisibility:
          map['activityVisibility'] as String? ?? 'followersOnly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowFollowers': allowFollowers,
      'shareLikes': shareLikes,
      'shareWatchlist': shareWatchlist,
      'shareWatchingActivity': shareWatchingActivity,
      'activityVisibility': activityVisibility,
    };
  }

  SocialPrivacySettings copyWith({
    bool? allowFollowers,
    bool? shareLikes,
    bool? shareWatchlist,
    bool? shareWatchingActivity,
    String? activityVisibility,
  }) {
    return SocialPrivacySettings(
      allowFollowers: allowFollowers ?? this.allowFollowers,
      shareLikes: shareLikes ?? this.shareLikes,
      shareWatchlist: shareWatchlist ?? this.shareWatchlist,
      shareWatchingActivity: shareWatchingActivity ?? this.shareWatchingActivity,
      activityVisibility: activityVisibility ?? this.activityVisibility,
    );
  }
}
