// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PopMatch';

  @override
  String get okButton => 'OK';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get backButton => 'Back';

  @override
  String get nextButton => 'Next';

  @override
  String get saveButton => 'Save';

  @override
  String get retryButton => 'Retry';

  @override
  String get viewAll => 'View all';

  @override
  String get loadingText => 'Loading...';

  @override
  String get anyOption => 'Any';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navSearch => 'Search';

  @override
  String get navWatchlist => 'Watchlist';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navProfile => 'Profile';

  @override
  String get moviesTab => 'MOVIES';

  @override
  String get showsTab => 'SHOWS';

  @override
  String get signInSubtitle => 'Sign in to continue discovering movies';

  @override
  String get emailHint => 'Email';

  @override
  String get emailErrorEmpty => 'Please enter your email';

  @override
  String get emailErrorInvalid => 'Please enter a valid email';

  @override
  String get passwordHint => 'Password';

  @override
  String get passwordErrorEmpty => 'Please enter your password';

  @override
  String get passwordErrorTooShort => 'Password must be at least 6 characters';

  @override
  String get signInButton => 'Sign In';

  @override
  String get orSeparator => 'OR';

  @override
  String get continueWithGoogleButton => 'Continue with Google';

  @override
  String get noAccountPrompt => 'Don\'t have an account? ';

  @override
  String get signUpLinkText => 'Sign Up';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get joinPopMatchTitle => 'JOIN POPMATCH';

  @override
  String get registerSubtitle =>
      'Create an account to start discovering movies';

  @override
  String get displayNameHint => 'Display Name';

  @override
  String get displayNameErrorEmpty => 'Please enter your display name';

  @override
  String get displayNameErrorTooShort =>
      'Display name must be at least 2 characters';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get confirmPasswordErrorEmpty => 'Please confirm your password';

  @override
  String get confirmPasswordErrorMismatch => 'Passwords do not match';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account? ';

  @override
  String get signInLinkText => 'Sign In';

  @override
  String get forgotPasswordTitle => 'FORGOT PASSWORD?';

  @override
  String get checkEmailTitle => 'CHECK YOUR EMAIL';

  @override
  String get forgotPasswordSubtitle =>
      'No worries! Enter your email and we\'ll send you reset instructions.';

  @override
  String checkEmailSubtitle(String email) {
    return 'We\'ve sent a password reset link to $email';
  }

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get resetEmailNotReceivedMessage =>
      'Didn\'t receive the email? Check your spam folder or try again in a few minutes.';

  @override
  String get resendEmailButton => 'Resend Email';

  @override
  String get backToLoginButton => 'Back to Login';

  @override
  String get rememberPasswordPrompt => 'Remember your password? ';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get verificationCodeDescription =>
      'We\'ve sent a 6-digit verification code to:';

  @override
  String get verifyCodeButton => 'Verify Code';

  @override
  String get resendCodeButton => 'Resend Code';

  @override
  String get emailVerificationHelper =>
      'Didn\'t receive the code? Check your spam folder or try resending.';

  @override
  String get incompleteCodeError => 'Please enter the complete 6-digit code';

  @override
  String get codeError => 'Please enter a 6-digit code';

  @override
  String get invalidCodeError => 'Invalid verification code. Please try again.';

  @override
  String get emailVerificationSuccess => 'Email verified successfully!';

  @override
  String get verificationCodeSentMessage =>
      'Verification code sent! Please check your email.';

  @override
  String get verificationCodeFallbackMessage =>
      'Email service is currently unavailable. Your code was generated in-app for verification.';

  @override
  String get verificationCodeDevMessage =>
      'Code generated in development mode. Check debug logs for the code.';

  @override
  String get verificationCodeGeneratedMessage =>
      'Verification code generated. Please try again if needed.';

  @override
  String get swipeToMatchTitle => 'SWIPE TO MATCH';

  @override
  String get swipeToMatchDescription =>
      'Swipe right to like, left to pass.\nFind your perfect movie match.';

  @override
  String get aiPoweredPicksTitle => 'AI Powered Picks';

  @override
  String get aiPoweredPicksDescription =>
      'Our AI learns your taste to suggest movies you will love.';

  @override
  String get curateWatchlistTitle => 'Curate Your Watchlist';

  @override
  String get curateWatchlistDescription =>
      'Save your matches and never wonder what to watch again.';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get welcomeTitle => 'WELCOME TO POPMATCH!';

  @override
  String get welcomeSubtitle =>
      'Let\'s personalize your movie discovery. Pick what you love and we\'ll find the best matches.';

  @override
  String get swipeFeature => 'Swipe to discover movies you\'ll love';

  @override
  String get bookmarkFeature => 'Save to your watchlist';

  @override
  String get filterFeature => 'Filter by genres and preferences';

  @override
  String get shareFeature => 'Share with friends';

  @override
  String get genresTitle => 'WHAT GENRES DO YOU LOVE?';

  @override
  String get genresSubtitle =>
      'Select your favorite genres for better recommendations.';

  @override
  String get platformsTitle => 'WHERE DO YOU WATCH MOVIES?';

  @override
  String get platformsSubtitle =>
      'Select the streaming services you have access to.';

  @override
  String pageIndicatorOf3(int current) {
    return '$current of 3';
  }

  @override
  String get loadingGenresMessage => 'Loading genres...';

  @override
  String get matchSwipeUpTooltip => 'Swipe up — Match';

  @override
  String get swipeLiked => 'Liked';

  @override
  String get swipePassed => 'Passed';

  @override
  String get swipeWatchlisted => 'Watchlisted';

  @override
  String get swipeSwiped => 'Swiped';

  @override
  String get undoButton => 'UNDO';

  @override
  String get matchItsA => 'It\'s a';

  @override
  String get matchTitle => 'MATCH!';

  @override
  String get savedToWatchlist => 'Saved to your watchlist';

  @override
  String get viewDetailsButton => 'View Details';

  @override
  String get addToWatchlistButton => 'Add to Watchlist';

  @override
  String reasonBecauseYouLike(String genre) {
    return 'Because you like $genre';
  }

  @override
  String get strategyLikedSimilar => 'Because you liked similar titles';

  @override
  String get strategyGenreMatch => 'Matches your genres';

  @override
  String get strategyTrending => 'Trending now';

  @override
  String get strategyTopRated => 'Top rated';

  @override
  String get strategyPersonalized => 'Picked for you';

  @override
  String get strategyCurated => 'Editor\'s pick';

  @override
  String get strategyActorDiscovery => 'From a cast you enjoy';

  @override
  String get strategyDirectorDiscovery => 'From a director you enjoy';

  @override
  String get relaxFiltersButton => 'Relax Filters';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get applyButton => 'Apply';

  @override
  String get clearAllButton => 'Clear All';

  @override
  String get filtersSectionTitle => 'Filters';

  @override
  String get moodFilterLabel => 'Mood';

  @override
  String get selectMoodsHint => 'Select moods';

  @override
  String get selectGenresHint => 'Select genres';

  @override
  String get platformFilterLabel => 'Platform';

  @override
  String get selectPlatformsHint => 'Select platforms';

  @override
  String get selectMoodsTitle => 'Select Moods';

  @override
  String get selectGenresTitle => 'Select Genres';

  @override
  String get selectPlatformsTitle => 'Select Platforms';

  @override
  String get nothingHereLabel => 'Nothing here';

  @override
  String get noMoviesFoundSwipe => 'No movies found';

  @override
  String get noShowsFoundSwipe => 'No shows found';

  @override
  String get tryRefreshingMovies => 'Try refreshing to load more movies';

  @override
  String get tryRefreshingShows => 'Try refreshing to load more shows';

  @override
  String get checkBackLaterNewReleases => 'Check back later for new releases';

  @override
  String get allCaughtUpLabel => 'You\'re all caught up';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHintMoviesShows => 'Search movies & shows...';

  @override
  String get searchMoviesAndShows => 'Search movies and shows';

  @override
  String get startTypingFindTitles => 'Start typing to find titles instantly';

  @override
  String addedToLikedMovies(String title) {
    return 'Added $title to your liked movies!';
  }

  @override
  String skippedMovie(String title) {
    return 'Skipped $title';
  }

  @override
  String get smartFiltersTitle => 'Smart Filters';

  @override
  String get genresFilterLabel => 'Genres';

  @override
  String get yearRangeFilterLabel => 'Year Range';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get applyFiltersButton => 'Apply Filters';

  @override
  String noMoviesFoundType(String type) {
    return 'No $type movies found';
  }

  @override
  String get tryAdjustingPreferences =>
      'Try adjusting your preferences or filters';

  @override
  String get errorLoadingRecommendations => 'Error loading recommendations';

  @override
  String get searchHint => 'Search movies, actors, or genres...';

  @override
  String get filtersButton => 'Filters';

  @override
  String get searchButton => 'Search';

  @override
  String get genreLabel => 'Genre';

  @override
  String get allGenresOption => 'All Genres';

  @override
  String get yearLabel => 'Year';

  @override
  String get allYearsOption => 'All Years';

  @override
  String get sortByLabel => 'Sort By';

  @override
  String get relevanceOption => 'Relevance';

  @override
  String get ratingOption => 'Rating';

  @override
  String get yearOption => 'Year';

  @override
  String get titleOption => 'Title';

  @override
  String get showOnlyAvailableCheckbox => 'Show only available on streaming';

  @override
  String get streamingPlatformsLabel => 'Streaming Platforms';

  @override
  String get recentSearchesTitle => 'Recent Searches';

  @override
  String get noMoviesFound => 'No movies found';

  @override
  String get tryAdjustingSearchTerms =>
      'Try adjusting your search terms or filters';

  @override
  String get searchErrorTitle => 'Search Error';

  @override
  String get overviewTab => 'Overview';

  @override
  String get seasonsEpisodesTab => 'Seasons & Episodes';

  @override
  String snackbarRemovedFromWatchlist(String title) {
    return 'Removed $title from watchlist';
  }

  @override
  String snackbarAddedToWatchlist(String title) {
    return 'Added $title to watchlist';
  }

  @override
  String get watchlistTitle => 'WATCHLIST';

  @override
  String get watchlistEmpty => 'Your watchlist is empty';

  @override
  String get startSwipingAddWatchlist =>
      'Start swiping to add movies and shows to your watchlist!';

  @override
  String removedFromWatchlist(String title) {
    return 'Removed $title from watchlist';
  }

  @override
  String movedToFavorites(String title) {
    return '$title moved to Favorites';
  }

  @override
  String markedAsDisliked(String title) {
    return '$title marked as disliked';
  }

  @override
  String get likedAction => 'Liked';

  @override
  String get likedActionSubtitle =>
      'Add to Favorites and remove from watchlist';

  @override
  String get dislikedAction => 'Disliked';

  @override
  String get dislikedActionSubtitle =>
      'Mark as disliked and remove from watchlist';

  @override
  String get removeAction => 'Remove';

  @override
  String get removeActionSubtitle => 'Remove from watchlist only';

  @override
  String get noMoviesInWatchlist => 'No movies in watchlist';

  @override
  String get startSwipingMovies => 'Start swiping to add movies!';

  @override
  String get noShowsInWatchlist => 'No shows in watchlist';

  @override
  String get startSwipingShows => 'Start swiping to add shows!';

  @override
  String get myWatchlistHeader => 'My Watchlist';

  @override
  String moviesInLists(int movieCount, int listCount) {
    return '$movieCount movies in $listCount lists';
  }

  @override
  String get advancedFiltersMenuItem => 'Advanced Filters';

  @override
  String get exportDataMenuItem => 'Export Data';

  @override
  String get searchMoviesHint => 'Search movies...';

  @override
  String get allTagsFilter => 'All';

  @override
  String get listsTab => 'Lists';

  @override
  String get moviesTabLabel => 'Movies';

  @override
  String get tagsTab => 'Tags';

  @override
  String get errorLoadingLists => 'Error loading lists';

  @override
  String get tryAdjustingSearchOrFilters =>
      'Try adjusting your search or filters';

  @override
  String get noMoviesInList => 'No movies in this list';

  @override
  String get addMoviesToGetStarted => 'Add some movies to get started!';

  @override
  String get noTagsYet => 'No tags yet';

  @override
  String get addTagsToOrganize =>
      'Add tags to your movies to organize them better';

  @override
  String get createNewListTitle => 'Create New List';

  @override
  String get listNameLabel => 'List Name';

  @override
  String get listNameRequired => 'Please enter a list name';

  @override
  String get listDescriptionLabel => 'Description (optional)';

  @override
  String get chooseColorLabel => 'Choose a color:';

  @override
  String get createButton => 'Create';

  @override
  String createdList(String name) {
    return 'Created list: $name';
  }

  @override
  String get exportSuccessMessage =>
      'Watchlist data export generated locally. Sharing/download will be added in a future update.';

  @override
  String exportFailedMessage(String error) {
    return 'Failed to export data: $error';
  }

  @override
  String moviesWithTagCount(int count) {
    return '$count movie(s)';
  }

  @override
  String get sortTooltip => 'Sort';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get noFavoriteShowsFound => 'No favorite shows found';

  @override
  String get favoritesTitle => 'FAVORITES';

  @override
  String get sortMoviesBy => 'Sort movies by';

  @override
  String get sortShowsBy => 'Sort shows by';

  @override
  String get watchingFirstSort => 'Watching first';

  @override
  String get finishedFirstSort => 'Finished first';

  @override
  String get titleAscendingSort => 'Title A–Z';

  @override
  String get titleDescendingSort => 'Title Z–A';

  @override
  String get yearNewestSort => 'Year (newest first)';

  @override
  String get yearOldestSort => 'Year (oldest first)';

  @override
  String get ratingHighestSort => 'Rating (highest first)';

  @override
  String get ratingLowestSort => 'Rating (lowest first)';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get startSwipingLikeMovies => 'Start swiping to like movies!';

  @override
  String get errorLoadingFavorites => 'Error loading favorites';

  @override
  String get noFavoritesFound => 'No favorites found';

  @override
  String get noFavoriteShowsYet => 'No favorite shows yet';

  @override
  String get startSwipingLikeShows => 'Start swiping to like shows!';

  @override
  String get selectMoviesToDelete => 'Select Movies to Delete';

  @override
  String get selectShowsToDelete => 'Select Shows to Delete';

  @override
  String get deleteLabel => 'Delete';

  @override
  String deleteItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items',
      one: 'Delete 1 item',
    );
    return '$_temp0';
  }

  @override
  String get finishedBadge => 'Finished';

  @override
  String get watchingBadge => 'Watching';

  @override
  String removedMoviesFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count movies from favorites',
      one: 'Removed 1 movie from favorites',
    );
    return '$_temp0';
  }

  @override
  String removedShowsFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count shows from favorites',
      one: 'Removed 1 show from favorites',
    );
    return '$_temp0';
  }

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get watchlistStat => 'Watchlist';

  @override
  String get likedMoviesStat => 'Liked Movies';

  @override
  String get likedShowsStat => 'Liked Shows';

  @override
  String get recentlyLikedMoviesTitle => 'Recently Liked Movies';

  @override
  String get recentlyLikedShowsTitle => 'Recently Liked Shows';

  @override
  String get accountSettingsTitle => 'ACCOUNT SETTINGS';

  @override
  String get editPreferencesLabel => 'Edit Preferences';

  @override
  String get editPreferencesSubtitle => 'Genres and streaming platforms';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get notificationsSubtitle => 'Push, reminders, recommendations';

  @override
  String get privacyLabel => 'Privacy';

  @override
  String get privacySubtitle => 'Data usage and your data';

  @override
  String get socialLabel => 'Social';

  @override
  String get socialSubtitle => 'Friends and what they are watching';

  @override
  String get helpSupportLabel => 'Help & Support';

  @override
  String get helpSupportSubtitle => 'FAQ, contact, about';

  @override
  String get removeAdsLabel => 'Remove Ads';

  @override
  String get removeAdsSubtitle => 'Not available yet';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage =>
      'Ad-free mode is not available yet. Stay tuned for updates!';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get loadingMovie => 'Loading Movie...';

  @override
  String get loadingShow => 'Loading Show...';

  @override
  String get notificationsPageTitle => 'NOTIFICATIONS';

  @override
  String get notificationsIntro => 'Choose what you want to be notified about.';

  @override
  String get followRequestsToggle => 'Follow requests';

  @override
  String get followRequestsToggleSubtitle => 'Review who wants to follow you';

  @override
  String get pushNotificationsToggle => 'Push notifications';

  @override
  String get pushNotificationsToggleSubtitle =>
      'Receive notifications from the app';

  @override
  String get matchRemindersToggle => 'Match reminders';

  @override
  String get matchRemindersToggleSubtitle => 'Remind you when you get a match';

  @override
  String get newRecommendationsToggle => 'New recommendations';

  @override
  String get newRecommendationsToggleSubtitle =>
      'Updates when we add new picks for you';

  @override
  String get friendRequestsToggle => 'Friend requests';

  @override
  String get friendRequestsToggleSubtitle => 'Notify when someone follows you';

  @override
  String get followAcceptedToggle => 'Follow accepted';

  @override
  String get followAcceptedToggleSubtitle =>
      'Notify when a follow request is accepted';

  @override
  String get sharedListsToggle => 'Shared lists';

  @override
  String get sharedListsToggleSubtitle =>
      'Notify when a friend shares a list with you';

  @override
  String get privacyPageTitle => 'PRIVACY';

  @override
  String get privacyIntro =>
      'Control how your data is used to personalize your experience.';

  @override
  String get useDataRecommendations => 'Use data for recommendations';

  @override
  String get useDataRecommendationsSubtitle =>
      'Allow us to use your likes, watchlist and activity to improve your recommendations.';

  @override
  String get socialPrivacySection => 'Social privacy';

  @override
  String get allowFollowers => 'Allow followers';

  @override
  String get allowFollowersSubtitle => 'Let other users send follow requests';

  @override
  String get shareLikes => 'Share likes';

  @override
  String get shareLikesSubtitle => 'Followers can see what you like';

  @override
  String get shareWatchlist => 'Share watchlist';

  @override
  String get shareWatchlistSubtitle =>
      'Followers can see your watchlist activity';

  @override
  String get shareWatchingActivity => 'Share watching activity';

  @override
  String get shareWatchingActivitySubtitle =>
      'Followers can see what you are currently watching';

  @override
  String get yourDataSection => 'Your data';

  @override
  String get whatWeStore => 'What we store';

  @override
  String get whatWeStoreSubtitle =>
      'We store your email, watchlist, likes and dislikes, and preferences to provide the service.';

  @override
  String get deleteMyData => 'Delete my data';

  @override
  String get deleteMyDataSubtitle => 'Request account and data deletion';

  @override
  String get deleteDataDialogTitle => 'Delete my data';

  @override
  String get deleteDataDialogContent =>
      'This will remove your account and all associated data (watchlist, likes, preferences) from our servers. This action cannot be undone.';

  @override
  String get deleteDataLearnMore => 'Learn more';

  @override
  String get deleteDataSnackbar =>
      'To delete your account, please contact support@popmatch.app';

  @override
  String get helpSupportPageTitle => 'HELP & SUPPORT';

  @override
  String get faqSection => 'Frequently asked questions';

  @override
  String get faq1Question => 'How does swiping work?';

  @override
  String get faq1Answer =>
      'Swipe right to like a movie or show, left to dislike, up for a match (save to watch later), and down to skip. Your choices help us recommend better content.';

  @override
  String get faq2Question => 'How do I add something to my watchlist?';

  @override
  String get faq2Answer =>
      'Swipe up on a card to open the match screen, then choose to add to watchlist. You can also open the title and tap the watchlist button on the detail screen.';

  @override
  String get faq3Question => 'Can I change my streaming platforms?';

  @override
  String get faq3Answer =>
      'Yes. Go to Profile → Edit Preferences and select your streaming services. We use this to tailor recommendations.';

  @override
  String get faq4Question => 'How do I reset my password?';

  @override
  String get faq4Answer =>
      'On the login screen, tap \"Forgot Password?\" and enter your email. We\'ll send you a link to reset it.';

  @override
  String get contactSection => 'Contact us';

  @override
  String get emailSupportLabel => 'Email support';

  @override
  String get emailSupportAddress => 'support@popmatch.app';

  @override
  String get emailErrorSnackbar =>
      'Could not open email app. Contact: support@popmatch.app';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutDescription =>
      'Swipe-based movie and show discovery. Find what to watch next.';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get editPreferencesAppBarTitle => 'Edit Preferences';

  @override
  String get genrePageTitle => 'What genres do you love?';

  @override
  String get genrePageSubtitle =>
      'Select your favorite movie genres to get better recommendations.';

  @override
  String get platformPageTitle => 'Where do you watch movies?';

  @override
  String get platformPageSubtitle =>
      'Select your streaming platforms to find movies available on your services.';

  @override
  String pageIndicatorOf2(int page) {
    return '$page of 2';
  }

  @override
  String get preferencesSavedSnackbar => 'Preferences saved successfully!';

  @override
  String get socialPageTitle => 'SOCIAL';

  @override
  String get friendsWatchingCard => 'What your friends are watching';

  @override
  String get friendsWatchingCardSubtitle =>
      'Swipe cards based on people you follow';

  @override
  String get activityFeedCard => 'Friends activity';

  @override
  String get activityFeedCardSubtitle =>
      'A timeline of what your friends are into';

  @override
  String get activityFeedPageTitle => 'FRIENDS ACTIVITY';

  @override
  String get activityFeedEmptyTitle => 'No activity yet';

  @override
  String get activityFeedEmptyBody =>
      'Follow more friends to see what they\'re liking and adding to their watchlists.';

  @override
  String get activityFeedErrorBody =>
      'We couldn\'t load the activity feed. Please try again.';

  @override
  String activityLikedBy(String name) {
    return '$name liked';
  }

  @override
  String activityWatchlistedBy(String name) {
    return '$name added to watchlist';
  }

  @override
  String activityWatchedBy(String name) {
    return '$name watched';
  }

  @override
  String get activityBucketToday => 'Today';

  @override
  String get activityBucketThisWeek => 'This week';

  @override
  String get activityBucketEarlier => 'Earlier';

  @override
  String get sharedWithYouCard => 'Shared with you';

  @override
  String get sharedWithYouCardSubtitle => 'Lists your friends sent you';

  @override
  String get sharedWithYouPageTitle => 'SHARED WITH YOU';

  @override
  String get sharedWithYouEmptyTitle => 'Nothing shared yet';

  @override
  String get sharedWithYouEmptyBody =>
      'When a friend shares a list with you, it\'ll show up here.';

  @override
  String get sharedWithYouErrorBody =>
      'We couldn\'t load shared lists. Please try again.';

  @override
  String sharedByLabel(String name) {
    return 'Shared by $name';
  }

  @override
  String get sharedByFallbackName => 'A friend';

  @override
  String sharedListItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return '$_temp0';
  }

  @override
  String get saveToMyListsButton => 'Save to my lists';

  @override
  String get savedToMyListsSnackbar => 'Saved to your lists';

  @override
  String get sharedListExistsSnackbar =>
      'You already have a list with that name';

  @override
  String get sharedListSaveFailedSnackbar =>
      'Couldn\'t save the list. Please try again.';

  @override
  String get shareListMenuItem => 'Share with a friend';

  @override
  String get shareListEmptySnackbar =>
      'This list is empty — add titles before sharing.';

  @override
  String get shareListNoFriendsSnackbar =>
      'Follow someone first to share a list with them.';

  @override
  String get shareListPickFriendTitle => 'Share with…';

  @override
  String listSharedSnackbar(String name) {
    return 'Shared with $name';
  }

  @override
  String get shareListFailedSnackbar =>
      'Couldn\'t share the list. Please try again.';

  @override
  String get matchesCard => 'Your matches';

  @override
  String get matchesCardSubtitle => 'Movies and shows you both liked';

  @override
  String get matchesPageTitle => 'YOUR MATCHES';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String get matchesEmptyBody =>
      'Like more titles, or follow more friends to find movies you both love.';

  @override
  String get matchesErrorBody =>
      'We couldn\'t load your matches. Please try again.';

  @override
  String matchesWithFriend(String name) {
    return 'You & $name';
  }

  @override
  String matchesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get findUsersSection => 'Find users';

  @override
  String get socialSearchHint => 'Search by name or email';

  @override
  String get followingStatus => 'Following';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get followButton => 'Follow';

  @override
  String get followRequestSentSnackbar => 'Follow request sent';

  @override
  String get followRequestsSection => 'Follow requests';

  @override
  String get noFollowRequests => 'No pending requests.';

  @override
  String get wantsToFollowYou => 'wants to follow you';

  @override
  String get declineButton => 'Decline';

  @override
  String get acceptButton => 'Accept';

  @override
  String get friendsWatchingTitle => 'FRIENDS WATCHING';

  @override
  String get feedDisabledMessage => 'Friends feed is currently disabled.';

  @override
  String get friendsEmptyState =>
      'No friend activity yet.\nFollow more people and check back soon.';

  @override
  String get friendsFeedTitle => 'What your friends are watching';

  @override
  String get moodAppBarTitle => 'How are you feeling?';

  @override
  String get moodPageTitle => 'What\'s your mood today?';

  @override
  String get moodPageSubtitle =>
      'We\'ll recommend movies that match your current vibe';

  @override
  String get selectMoodButton => 'Select Your Mood';

  @override
  String findMoodMoviesButton(String moodName) {
    return 'Find $moodName Movies';
  }

  @override
  String get advancedFiltersTitle => 'Advanced Filters';

  @override
  String get resetButton => 'Reset';

  @override
  String get filtersTab => 'Filters';

  @override
  String get sortTab => 'Sort';

  @override
  String get resultsTab => 'Results';

  @override
  String get sortByTitle => 'Sort By';

  @override
  String get sortDirectionLabel => 'Sort Direction:';

  @override
  String get descendingOption => 'Descending';

  @override
  String get ascendingOption => 'Ascending';

  @override
  String get noMoviesMatchFilters => 'No movies match your filters';

  @override
  String get tryAdjustingFilterCriteria => 'Try adjusting your filter criteria';

  @override
  String applyFiltersCount(int count) {
    return 'Apply Filters ($count movies)';
  }

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get genresFilter => 'Genres';

  @override
  String get yearRangeFilter => 'Year Range';

  @override
  String get ratingRangeFilter => 'Rating Range';

  @override
  String get minRatingLabel => 'Min Rating';

  @override
  String get maxRatingLabel => 'Max Rating';

  @override
  String get languagesFilter => 'Languages';

  @override
  String get contentTypeFilter => 'Content Type';

  @override
  String get allContentOption => 'All Content';

  @override
  String get familyFriendlyOption => 'Family Friendly';

  @override
  String get adultContentOption => 'Adult Content';

  @override
  String get availabilityFilter => 'Availability';

  @override
  String get showOnlyAvailableStream => 'Show only available to stream';

  @override
  String get temporarilyUnavailable => 'Temporarily unavailable in this build';

  @override
  String get popularitySort => 'Popularity';

  @override
  String get runtimeSort => 'Runtime';

  @override
  String get releaseDateSort => 'Release Date';

  @override
  String get streamingFiltersTitle => 'Streaming Filters';

  @override
  String get clearFiltersTooltip => 'Clear filters';

  @override
  String get filterByPlatformTitle => 'Filter by Streaming Platform';

  @override
  String get failedToLoadMovies => 'Failed to load movies';

  @override
  String get noMoviesFoundFilter => 'No movies found';

  @override
  String get tryDifferentPlatforms =>
      'Try selecting different streaming platforms';

  @override
  String moviesFoundCount(int count) {
    return '$count movies found';
  }

  @override
  String filteredByPlatforms(int count) {
    return 'Filtered by $count platform(s)';
  }

  @override
  String get searchingText => 'Searching...';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get tryDifferentTitleKeyword => 'Try a different title or keyword';

  @override
  String get noShowsFound => 'No shows found';

  @override
  String get recentLabel => 'Recent';

  @override
  String get clearLabel => 'Clear';

  @override
  String get searchForMoviesHint => 'Search for movies, actors, or genres';

  @override
  String get recentSearchesAppearHere =>
      'Your recent searches will appear here';

  @override
  String get likedByFriendsLabel => 'Liked by friends';

  @override
  String get skipLabel => 'Skip';

  @override
  String get likeLabel => 'Like';

  @override
  String get synopsisLabel => 'Synopsis';

  @override
  String get moreLabel => 'More';

  @override
  String get showLessLabel => 'Show less';

  @override
  String get castCrewLabel => 'Cast & Crew';

  @override
  String get trailersVideosLabel => 'Trailers & Videos';

  @override
  String get moviesLikeThisLabel => 'Movies Like This';

  @override
  String get showsLikeThisLabel => 'Shows Like This';

  @override
  String get failedToLoadSimilarShows => 'Failed to load similar shows';

  @override
  String get noSimilarShowsFound => 'No similar shows found';

  @override
  String get failedToLoadSimilarMovies => 'Failed to load similar movies';

  @override
  String get noSimilarMoviesFound => 'No similar movies found';

  @override
  String get whereToWatchLabel => 'Where to Watch:';

  @override
  String removedFromFavoritesSnackbar(String title) {
    return 'Removed $title from favorites';
  }

  @override
  String addedToFavoritesSnackbar(String title) {
    return 'Added $title to favorites';
  }

  @override
  String removedFromDislikedSnackbar(String title) {
    return 'Removed $title from disliked';
  }

  @override
  String addedToDislikedSnackbar(String title) {
    return 'Added $title to disliked';
  }

  @override
  String get noSeasonsAvailable => 'No seasons available';

  @override
  String seasonLabel(int number) {
    return 'Season $number';
  }

  @override
  String episodesLabel(int count) {
    return '$count Episodes';
  }

  @override
  String get closeButton => 'Close';

  @override
  String minutesLabel(int count) {
    return '$count min';
  }

  @override
  String get sortDescending => 'Descending';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filter criteria';

  @override
  String get ratingRangeLabel => 'Rating Range';

  @override
  String get languagesLabel => 'Languages';

  @override
  String get contentTypeLabel => 'Content Type';

  @override
  String get allContentLabel => 'All Content';

  @override
  String get familyFriendlyLabel => 'Family Friendly';

  @override
  String get adultContentLabel => 'Adult Content';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get showOnlyStreamableLabel => 'Show only available to stream';

  @override
  String get temporarilyUnavailableLabel =>
      'Temporarily unavailable in this build';

  @override
  String get popularityOption => 'Popularity';

  @override
  String get runtimeOption => 'Runtime';

  @override
  String get releaseDateOption => 'Release Date';

  @override
  String upToRatingLabel(String rating) {
    return 'Up to $rating';
  }

  @override
  String get myWatchlistTitle => 'My Watchlist';

  @override
  String get exportDataButton => 'Export Data';

  @override
  String get noMoviesMatchFiltersShort => 'No movies match your filters';

  @override
  String get addSomeMovies => 'Add some movies to get started!';

  @override
  String get addTagsDescription =>
      'Add tags to your movies to organize them better';

  @override
  String get listNameError => 'Please enter a list name';

  @override
  String createdListSnackbar(String name) {
    return 'Created list: $name';
  }

  @override
  String get exportDataLocalSnackbar =>
      'Watchlist data export generated locally. Sharing/download will be added in a future update.';

  @override
  String failedToExportSnackbar(String error) {
    return 'Failed to export data: $error';
  }

  @override
  String get listsTooltip => 'Your lists';

  @override
  String get addToListTitle => 'Add to List';

  @override
  String get listNameExists => 'A list with that name already exists.';

  @override
  String get noListsYet => 'No lists yet — create one below.';

  @override
  String get newListHint => 'New list name';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get addTagHint => 'Add a tag';

  @override
  String get forYouTitle => 'For You';

  @override
  String get forYouTooltip => 'For You';

  @override
  String get forYouBecauseYouLiked => 'Because You Liked';

  @override
  String forYouBecauseYouLikedTitle(String title) {
    return 'Because you liked $title';
  }

  @override
  String get forYouRecommended => 'Recommended For You';

  @override
  String get forYouTrending => 'Trending Now';

  @override
  String get forYouFriendsWatching => 'Friends Are Watching';

  @override
  String get forYouTopPick => 'Top Pick for You';

  @override
  String get forYouCurating => 'Curating your picks…';

  @override
  String get forYouOpen => 'Open';

  @override
  String get forYouEmpty =>
      'Like a few titles and your personalized picks will show up here.';

  @override
  String get premiumUpsellTitle => 'PopMatch Premium';

  @override
  String get premiumPerkUnlimitedSwipes => 'Unlimited swipes';

  @override
  String get premiumPerkNoAds => 'Ad-free experience';

  @override
  String get premiumPerkForYou => 'Personalized “For You” recommendations';

  @override
  String get premiumUpgradeCta => 'Upgrade to Premium';

  @override
  String get premiumComingSoon => 'Subscriptions are coming soon.';

  @override
  String get premiumDevEnable => 'Enable Premium (dev)';

  @override
  String get signInFailedError => 'Sign-in failed. Please try again.';

  @override
  String get resetEnterCodeTitle => 'ENTER CODE';

  @override
  String resetCodeSentTo(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get resetDoneTitle => 'PASSWORD RESET';

  @override
  String get resetDoneSubtitle => 'Your password has been updated.';

  @override
  String get resetCodeOnItsWay =>
      'If that email has an account, a code is on its way.';

  @override
  String get resetEnterCodeError => 'Enter the 6-digit code.';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get newPasswordHint => 'New password';

  @override
  String get confirmNewPasswordHint => 'Confirm new password';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get backToSignInButton => 'Back to sign in';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get continueButton => 'Continue';

  @override
  String get resetNewPasswordTitle => 'NEW PASSWORD';

  @override
  String get resetNewPasswordSubtitle =>
      'Choose a new password for your account.';
}
