class FeatureFlags {
  static const bool socialUiEnabled =
      bool.fromEnvironment('SOCIAL_UI_ENABLED', defaultValue: true);
  static const bool friendsFeedEnabled =
      bool.fromEnvironment('FRIENDS_FEED_ENABLED', defaultValue: true);
}
