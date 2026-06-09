import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PopMatch'**
  String get appTitle;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// No description provided for @anyOption.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyOption;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get navWatchlist;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @moviesTab.
  ///
  /// In en, this message translates to:
  /// **'MOVIES'**
  String get moviesTab;

  /// No description provided for @showsTab.
  ///
  /// In en, this message translates to:
  /// **'SHOWS'**
  String get showsTab;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue discovering movies'**
  String get signInSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @emailErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailErrorEmpty;

  /// No description provided for @emailErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailErrorInvalid;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @passwordErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordErrorEmpty;

  /// No description provided for @passwordErrorTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordErrorTooShort;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orSeparator;

  /// No description provided for @continueWithGoogleButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogleButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountPrompt;

  /// No description provided for @signUpLinkText.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLinkText;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @joinPopMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'JOIN POPMATCH'**
  String get joinPopMatchTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start discovering movies'**
  String get registerSubtitle;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameHint;

  /// No description provided for @displayNameErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your display name'**
  String get displayNameErrorEmpty;

  /// No description provided for @displayNameErrorTooShort.
  ///
  /// In en, this message translates to:
  /// **'Display name must be at least 2 characters'**
  String get displayNameErrorTooShort;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordErrorEmpty;

  /// No description provided for @confirmPasswordErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get confirmPasswordErrorMismatch;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountPrompt;

  /// No description provided for @signInLinkText.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLinkText;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD?'**
  String get forgotPasswordTitle;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'CHECK YOUR EMAIL'**
  String get checkEmailTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email and we\'ll send you reset instructions.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @checkEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}'**
  String checkEmailSubtitle(String email);

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// No description provided for @resetEmailNotReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Check your spam folder or try again in a few minutes.'**
  String get resetEmailNotReceivedMessage;

  /// No description provided for @resendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmailButton;

  /// No description provided for @backToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginButton;

  /// No description provided for @rememberPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get rememberPasswordPrompt;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// No description provided for @verificationCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit verification code to:'**
  String get verificationCodeDescription;

  /// No description provided for @verifyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCodeButton;

  /// No description provided for @resendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCodeButton;

  /// No description provided for @emailVerificationHelper.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? Check your spam folder or try resending.'**
  String get emailVerificationHelper;

  /// No description provided for @incompleteCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get incompleteCodeError;

  /// No description provided for @codeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 6-digit code'**
  String get codeError;

  /// No description provided for @invalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code. Please try again.'**
  String get invalidCodeError;

  /// No description provided for @emailVerificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerificationSuccess;

  /// No description provided for @verificationCodeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent! Please check your email.'**
  String get verificationCodeSentMessage;

  /// No description provided for @verificationCodeFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Email service is currently unavailable. Your code was generated in-app for verification.'**
  String get verificationCodeFallbackMessage;

  /// No description provided for @verificationCodeDevMessage.
  ///
  /// In en, this message translates to:
  /// **'Code generated in development mode. Check debug logs for the code.'**
  String get verificationCodeDevMessage;

  /// No description provided for @verificationCodeGeneratedMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification code generated. Please try again if needed.'**
  String get verificationCodeGeneratedMessage;

  /// No description provided for @swipeToMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'SWIPE TO MATCH'**
  String get swipeToMatchTitle;

  /// No description provided for @swipeToMatchDescription.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to like, left to pass.\nFind your perfect movie match.'**
  String get swipeToMatchDescription;

  /// No description provided for @aiPoweredPicksTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Powered Picks'**
  String get aiPoweredPicksTitle;

  /// No description provided for @aiPoweredPicksDescription.
  ///
  /// In en, this message translates to:
  /// **'Our AI learns your taste to suggest movies you will love.'**
  String get aiPoweredPicksDescription;

  /// No description provided for @curateWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Curate Your Watchlist'**
  String get curateWatchlistTitle;

  /// No description provided for @curateWatchlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your matches and never wonder what to watch again.'**
  String get curateWatchlistDescription;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'WELCOME TO POPMATCH!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your movie discovery. Pick what you love and we\'ll find the best matches.'**
  String get welcomeSubtitle;

  /// No description provided for @swipeFeature.
  ///
  /// In en, this message translates to:
  /// **'Swipe to discover movies you\'ll love'**
  String get swipeFeature;

  /// No description provided for @bookmarkFeature.
  ///
  /// In en, this message translates to:
  /// **'Save to your watchlist'**
  String get bookmarkFeature;

  /// No description provided for @filterFeature.
  ///
  /// In en, this message translates to:
  /// **'Filter by genres and preferences'**
  String get filterFeature;

  /// No description provided for @shareFeature.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get shareFeature;

  /// No description provided for @genresTitle.
  ///
  /// In en, this message translates to:
  /// **'WHAT GENRES DO YOU LOVE?'**
  String get genresTitle;

  /// No description provided for @genresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite genres for better recommendations.'**
  String get genresSubtitle;

  /// No description provided for @platformsTitle.
  ///
  /// In en, this message translates to:
  /// **'WHERE DO YOU WATCH MOVIES?'**
  String get platformsTitle;

  /// No description provided for @platformsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the streaming services you have access to.'**
  String get platformsSubtitle;

  /// No description provided for @pageIndicatorOf3.
  ///
  /// In en, this message translates to:
  /// **'{current} of 3'**
  String pageIndicatorOf3(int current);

  /// No description provided for @loadingGenresMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading genres...'**
  String get loadingGenresMessage;

  /// No description provided for @matchSwipeUpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swipe up — Match'**
  String get matchSwipeUpTooltip;

  /// No description provided for @swipeLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get swipeLiked;

  /// No description provided for @swipePassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get swipePassed;

  /// No description provided for @swipeWatchlisted.
  ///
  /// In en, this message translates to:
  /// **'Watchlisted'**
  String get swipeWatchlisted;

  /// No description provided for @swipeSwiped.
  ///
  /// In en, this message translates to:
  /// **'Swiped'**
  String get swipeSwiped;

  /// No description provided for @undoButton.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undoButton;

  /// No description provided for @matchItsA.
  ///
  /// In en, this message translates to:
  /// **'It\'s a'**
  String get matchItsA;

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'MATCH!'**
  String get matchTitle;

  /// No description provided for @savedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Saved to your watchlist'**
  String get savedToWatchlist;

  /// No description provided for @viewDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsButton;

  /// No description provided for @addToWatchlistButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Watchlist'**
  String get addToWatchlistButton;

  /// No description provided for @reasonBecauseYouLike.
  ///
  /// In en, this message translates to:
  /// **'Because you like {genre}'**
  String reasonBecauseYouLike(String genre);

  /// No description provided for @strategyLikedSimilar.
  ///
  /// In en, this message translates to:
  /// **'Because you liked similar titles'**
  String get strategyLikedSimilar;

  /// No description provided for @strategyGenreMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches your genres'**
  String get strategyGenreMatch;

  /// No description provided for @strategyTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get strategyTrending;

  /// No description provided for @strategyTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get strategyTopRated;

  /// No description provided for @strategyPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get strategyPersonalized;

  /// No description provided for @strategyCurated.
  ///
  /// In en, this message translates to:
  /// **'Editor\'s pick'**
  String get strategyCurated;

  /// No description provided for @strategyActorDiscovery.
  ///
  /// In en, this message translates to:
  /// **'From a cast you enjoy'**
  String get strategyActorDiscovery;

  /// No description provided for @strategyDirectorDiscovery.
  ///
  /// In en, this message translates to:
  /// **'From a director you enjoy'**
  String get strategyDirectorDiscovery;

  /// No description provided for @relaxFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Relax Filters'**
  String get relaxFiltersButton;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @clearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButton;

  /// No description provided for @filtersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersSectionTitle;

  /// No description provided for @moodFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get moodFilterLabel;

  /// No description provided for @selectMoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Select moods'**
  String get selectMoodsHint;

  /// No description provided for @selectGenresHint.
  ///
  /// In en, this message translates to:
  /// **'Select genres'**
  String get selectGenresHint;

  /// No description provided for @platformFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformFilterLabel;

  /// No description provided for @selectPlatformsHint.
  ///
  /// In en, this message translates to:
  /// **'Select platforms'**
  String get selectPlatformsHint;

  /// No description provided for @selectMoodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Moods'**
  String get selectMoodsTitle;

  /// No description provided for @selectGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Genres'**
  String get selectGenresTitle;

  /// No description provided for @selectPlatformsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Platforms'**
  String get selectPlatformsTitle;

  /// No description provided for @nothingHereLabel.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHereLabel;

  /// No description provided for @noMoviesFoundSwipe.
  ///
  /// In en, this message translates to:
  /// **'No movies found'**
  String get noMoviesFoundSwipe;

  /// No description provided for @noShowsFoundSwipe.
  ///
  /// In en, this message translates to:
  /// **'No shows found'**
  String get noShowsFoundSwipe;

  /// No description provided for @tryRefreshingMovies.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing to load more movies'**
  String get tryRefreshingMovies;

  /// No description provided for @tryRefreshingShows.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing to load more shows'**
  String get tryRefreshingShows;

  /// No description provided for @checkBackLaterNewReleases.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new releases'**
  String get checkBackLaterNewReleases;

  /// No description provided for @allCaughtUpLabel.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get allCaughtUpLabel;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHintMoviesShows.
  ///
  /// In en, this message translates to:
  /// **'Search movies & shows...'**
  String get searchHintMoviesShows;

  /// No description provided for @searchMoviesAndShows.
  ///
  /// In en, this message translates to:
  /// **'Search movies and shows'**
  String get searchMoviesAndShows;

  /// No description provided for @startTypingFindTitles.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find titles instantly'**
  String get startTypingFindTitles;

  /// No description provided for @addedToLikedMovies.
  ///
  /// In en, this message translates to:
  /// **'Added {title} to your liked movies!'**
  String addedToLikedMovies(String title);

  /// No description provided for @skippedMovie.
  ///
  /// In en, this message translates to:
  /// **'Skipped {title}'**
  String skippedMovie(String title);

  /// No description provided for @smartFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Filters'**
  String get smartFiltersTitle;

  /// No description provided for @genresFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genresFilterLabel;

  /// No description provided for @yearRangeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Year Range'**
  String get yearRangeFilterLabel;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @applyFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFiltersButton;

  /// No description provided for @noMoviesFoundType.
  ///
  /// In en, this message translates to:
  /// **'No {type} movies found'**
  String noMoviesFoundType(String type);

  /// No description provided for @tryAdjustingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your preferences or filters'**
  String get tryAdjustingPreferences;

  /// No description provided for @errorLoadingRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Error loading recommendations'**
  String get errorLoadingRecommendations;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies, actors, or genres...'**
  String get searchHint;

  /// No description provided for @filtersButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersButton;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @genreLabel.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genreLabel;

  /// No description provided for @allGenresOption.
  ///
  /// In en, this message translates to:
  /// **'All Genres'**
  String get allGenresOption;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @allYearsOption.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get allYearsOption;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortByLabel;

  /// No description provided for @relevanceOption.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get relevanceOption;

  /// No description provided for @ratingOption.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingOption;

  /// No description provided for @yearOption.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearOption;

  /// No description provided for @titleOption.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleOption;

  /// No description provided for @showOnlyAvailableCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Show only available on streaming'**
  String get showOnlyAvailableCheckbox;

  /// No description provided for @streamingPlatformsLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaming Platforms'**
  String get streamingPlatformsLabel;

  /// No description provided for @recentSearchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearchesTitle;

  /// No description provided for @noMoviesFound.
  ///
  /// In en, this message translates to:
  /// **'No movies found'**
  String get noMoviesFound;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms or filters'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @searchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Error'**
  String get searchErrorTitle;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @seasonsEpisodesTab.
  ///
  /// In en, this message translates to:
  /// **'Seasons & Episodes'**
  String get seasonsEpisodesTab;

  /// No description provided for @snackbarRemovedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from watchlist'**
  String snackbarRemovedFromWatchlist(String title);

  /// No description provided for @snackbarAddedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Added {title} to watchlist'**
  String snackbarAddedToWatchlist(String title);

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'WATCHLIST'**
  String get watchlistTitle;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist is empty'**
  String get watchlistEmpty;

  /// No description provided for @startSwipingAddWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to add movies and shows to your watchlist!'**
  String get startSwipingAddWatchlist;

  /// No description provided for @removedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from watchlist'**
  String removedFromWatchlist(String title);

  /// No description provided for @movedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'{title} moved to Favorites'**
  String movedToFavorites(String title);

  /// No description provided for @markedAsDisliked.
  ///
  /// In en, this message translates to:
  /// **'{title} marked as disliked'**
  String markedAsDisliked(String title);

  /// No description provided for @likedAction.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get likedAction;

  /// No description provided for @likedActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites and remove from watchlist'**
  String get likedActionSubtitle;

  /// No description provided for @dislikedAction.
  ///
  /// In en, this message translates to:
  /// **'Disliked'**
  String get dislikedAction;

  /// No description provided for @dislikedActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as disliked and remove from watchlist'**
  String get dislikedActionSubtitle;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @removeActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist only'**
  String get removeActionSubtitle;

  /// No description provided for @noMoviesInWatchlist.
  ///
  /// In en, this message translates to:
  /// **'No movies in watchlist'**
  String get noMoviesInWatchlist;

  /// No description provided for @startSwipingMovies.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to add movies!'**
  String get startSwipingMovies;

  /// No description provided for @noShowsInWatchlist.
  ///
  /// In en, this message translates to:
  /// **'No shows in watchlist'**
  String get noShowsInWatchlist;

  /// No description provided for @startSwipingShows.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to add shows!'**
  String get startSwipingShows;

  /// No description provided for @myWatchlistHeader.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get myWatchlistHeader;

  /// No description provided for @moviesInLists.
  ///
  /// In en, this message translates to:
  /// **'{movieCount} movies in {listCount} lists'**
  String moviesInLists(int movieCount, int listCount);

  /// No description provided for @advancedFiltersMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFiltersMenuItem;

  /// No description provided for @exportDataMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataMenuItem;

  /// No description provided for @searchMoviesHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies...'**
  String get searchMoviesHint;

  /// No description provided for @allTagsFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTagsFilter;

  /// No description provided for @listsTab.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsTab;

  /// No description provided for @moviesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get moviesTabLabel;

  /// No description provided for @tagsTab.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTab;

  /// No description provided for @errorLoadingLists.
  ///
  /// In en, this message translates to:
  /// **'Error loading lists'**
  String get errorLoadingLists;

  /// No description provided for @tryAdjustingSearchOrFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingSearchOrFilters;

  /// No description provided for @noMoviesInList.
  ///
  /// In en, this message translates to:
  /// **'No movies in this list'**
  String get noMoviesInList;

  /// No description provided for @addMoviesToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add some movies to get started!'**
  String get addMoviesToGetStarted;

  /// No description provided for @noTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get noTagsYet;

  /// No description provided for @addTagsToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Add tags to your movies to organize them better'**
  String get addTagsToOrganize;

  /// No description provided for @createNewListTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get createNewListTitle;

  /// No description provided for @listNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get listNameLabel;

  /// No description provided for @listNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a list name'**
  String get listNameRequired;

  /// No description provided for @listDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get listDescriptionLabel;

  /// No description provided for @chooseColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a color:'**
  String get chooseColorLabel;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @createdList.
  ///
  /// In en, this message translates to:
  /// **'Created list: {name}'**
  String createdList(String name);

  /// No description provided for @exportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Watchlist data export generated locally. Sharing/download will be added in a future update.'**
  String get exportSuccessMessage;

  /// No description provided for @exportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to export data: {error}'**
  String exportFailedMessage(String error);

  /// No description provided for @moviesWithTagCount.
  ///
  /// In en, this message translates to:
  /// **'{count} movie(s)'**
  String moviesWithTagCount(int count);

  /// No description provided for @sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @noFavoriteShowsFound.
  ///
  /// In en, this message translates to:
  /// **'No favorite shows found'**
  String get noFavoriteShowsFound;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get favoritesTitle;

  /// No description provided for @sortMoviesBy.
  ///
  /// In en, this message translates to:
  /// **'Sort movies by'**
  String get sortMoviesBy;

  /// No description provided for @sortShowsBy.
  ///
  /// In en, this message translates to:
  /// **'Sort shows by'**
  String get sortShowsBy;

  /// No description provided for @watchingFirstSort.
  ///
  /// In en, this message translates to:
  /// **'Watching first'**
  String get watchingFirstSort;

  /// No description provided for @finishedFirstSort.
  ///
  /// In en, this message translates to:
  /// **'Finished first'**
  String get finishedFirstSort;

  /// No description provided for @titleAscendingSort.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get titleAscendingSort;

  /// No description provided for @titleDescendingSort.
  ///
  /// In en, this message translates to:
  /// **'Title Z–A'**
  String get titleDescendingSort;

  /// No description provided for @yearNewestSort.
  ///
  /// In en, this message translates to:
  /// **'Year (newest first)'**
  String get yearNewestSort;

  /// No description provided for @yearOldestSort.
  ///
  /// In en, this message translates to:
  /// **'Year (oldest first)'**
  String get yearOldestSort;

  /// No description provided for @ratingHighestSort.
  ///
  /// In en, this message translates to:
  /// **'Rating (highest first)'**
  String get ratingHighestSort;

  /// No description provided for @ratingLowestSort.
  ///
  /// In en, this message translates to:
  /// **'Rating (lowest first)'**
  String get ratingLowestSort;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @startSwipingLikeMovies.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to like movies!'**
  String get startSwipingLikeMovies;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @noFavoritesFound.
  ///
  /// In en, this message translates to:
  /// **'No favorites found'**
  String get noFavoritesFound;

  /// No description provided for @noFavoriteShowsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite shows yet'**
  String get noFavoriteShowsYet;

  /// No description provided for @startSwipingLikeShows.
  ///
  /// In en, this message translates to:
  /// **'Start swiping to like shows!'**
  String get startSwipingLikeShows;

  /// No description provided for @selectMoviesToDelete.
  ///
  /// In en, this message translates to:
  /// **'Select Movies to Delete'**
  String get selectMoviesToDelete;

  /// No description provided for @selectShowsToDelete.
  ///
  /// In en, this message translates to:
  /// **'Select Shows to Delete'**
  String get selectShowsToDelete;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item} other{Delete {count} items}}'**
  String deleteItems(int count);

  /// No description provided for @finishedBadge.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishedBadge;

  /// No description provided for @watchingBadge.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watchingBadge;

  /// No description provided for @removedMoviesFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 movie from favorites} other{Removed {count} movies from favorites}}'**
  String removedMoviesFromFavorites(int count);

  /// No description provided for @removedShowsFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 show from favorites} other{Removed {count} shows from favorites}}'**
  String removedShowsFromFavorites(int count);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileTitle;

  /// No description provided for @watchlistStat.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistStat;

  /// No description provided for @likedMoviesStat.
  ///
  /// In en, this message translates to:
  /// **'Liked Movies'**
  String get likedMoviesStat;

  /// No description provided for @likedShowsStat.
  ///
  /// In en, this message translates to:
  /// **'Liked Shows'**
  String get likedShowsStat;

  /// No description provided for @recentlyLikedMoviesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently Liked Movies'**
  String get recentlyLikedMoviesTitle;

  /// No description provided for @recentlyLikedShowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently Liked Shows'**
  String get recentlyLikedShowsTitle;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettingsTitle;

  /// No description provided for @editPreferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get editPreferencesLabel;

  /// No description provided for @editPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Genres and streaming platforms'**
  String get editPreferencesSubtitle;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push, reminders, recommendations'**
  String get notificationsSubtitle;

  /// No description provided for @privacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyLabel;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data usage and your data'**
  String get privacySubtitle;

  /// No description provided for @socialLabel.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialLabel;

  /// No description provided for @socialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends and what they are watching'**
  String get socialSubtitle;

  /// No description provided for @helpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportLabel;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, contact, about'**
  String get helpSupportSubtitle;

  /// No description provided for @removeAdsLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAdsLabel;

  /// No description provided for @removeAdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get removeAdsSubtitle;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Ad-free mode is not available yet. Stay tuned for updates!'**
  String get comingSoonMessage;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButton;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @loadingMovie.
  ///
  /// In en, this message translates to:
  /// **'Loading Movie...'**
  String get loadingMovie;

  /// No description provided for @loadingShow.
  ///
  /// In en, this message translates to:
  /// **'Loading Show...'**
  String get loadingShow;

  /// No description provided for @notificationsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsPageTitle;

  /// No description provided for @notificationsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to be notified about.'**
  String get notificationsIntro;

  /// No description provided for @followRequestsToggle.
  ///
  /// In en, this message translates to:
  /// **'Follow requests'**
  String get followRequestsToggle;

  /// No description provided for @followRequestsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review who wants to follow you'**
  String get followRequestsToggleSubtitle;

  /// No description provided for @pushNotificationsToggle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotificationsToggle;

  /// No description provided for @pushNotificationsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications from the app'**
  String get pushNotificationsToggleSubtitle;

  /// No description provided for @matchRemindersToggle.
  ///
  /// In en, this message translates to:
  /// **'Match reminders'**
  String get matchRemindersToggle;

  /// No description provided for @matchRemindersToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind you when you get a match'**
  String get matchRemindersToggleSubtitle;

  /// No description provided for @newRecommendationsToggle.
  ///
  /// In en, this message translates to:
  /// **'New recommendations'**
  String get newRecommendationsToggle;

  /// No description provided for @newRecommendationsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates when we add new picks for you'**
  String get newRecommendationsToggleSubtitle;

  /// No description provided for @friendRequestsToggle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequestsToggle;

  /// No description provided for @friendRequestsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when someone follows you'**
  String get friendRequestsToggleSubtitle;

  /// No description provided for @followAcceptedToggle.
  ///
  /// In en, this message translates to:
  /// **'Follow accepted'**
  String get followAcceptedToggle;

  /// No description provided for @followAcceptedToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when a follow request is accepted'**
  String get followAcceptedToggleSubtitle;

  /// No description provided for @sharedListsToggle.
  ///
  /// In en, this message translates to:
  /// **'Shared lists'**
  String get sharedListsToggle;

  /// No description provided for @sharedListsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when a friend shares a list with you'**
  String get sharedListsToggleSubtitle;

  /// No description provided for @privacyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacyPageTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Control how your data is used to personalize your experience.'**
  String get privacyIntro;

  /// No description provided for @useDataRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Use data for recommendations'**
  String get useDataRecommendations;

  /// No description provided for @useDataRecommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow us to use your likes, watchlist and activity to improve your recommendations.'**
  String get useDataRecommendationsSubtitle;

  /// No description provided for @socialPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Social privacy'**
  String get socialPrivacySection;

  /// No description provided for @allowFollowers.
  ///
  /// In en, this message translates to:
  /// **'Allow followers'**
  String get allowFollowers;

  /// No description provided for @allowFollowersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let other users send follow requests'**
  String get allowFollowersSubtitle;

  /// No description provided for @shareLikes.
  ///
  /// In en, this message translates to:
  /// **'Share likes'**
  String get shareLikes;

  /// No description provided for @shareLikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Followers can see what you like'**
  String get shareLikesSubtitle;

  /// No description provided for @shareWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Share watchlist'**
  String get shareWatchlist;

  /// No description provided for @shareWatchlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Followers can see your watchlist activity'**
  String get shareWatchlistSubtitle;

  /// No description provided for @shareWatchingActivity.
  ///
  /// In en, this message translates to:
  /// **'Share watching activity'**
  String get shareWatchingActivity;

  /// No description provided for @shareWatchingActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Followers can see what you are currently watching'**
  String get shareWatchingActivitySubtitle;

  /// No description provided for @yourDataSection.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourDataSection;

  /// No description provided for @whatWeStore.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get whatWeStore;

  /// No description provided for @whatWeStoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We store your email, watchlist, likes and dislikes, and preferences to provide the service.'**
  String get whatWeStoreSubtitle;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteMyData;

  /// No description provided for @deleteMyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request account and data deletion'**
  String get deleteMyDataSubtitle;

  /// No description provided for @deleteDataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteDataDialogTitle;

  /// No description provided for @deleteDataDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove your account and all associated data (watchlist, likes, preferences) from our servers. This action cannot be undone.'**
  String get deleteDataDialogContent;

  /// No description provided for @deleteDataLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get deleteDataLearnMore;

  /// No description provided for @deleteDataSnackbar.
  ///
  /// In en, this message translates to:
  /// **'To delete your account, please contact support@popmatch.app'**
  String get deleteDataSnackbar;

  /// No description provided for @helpSupportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'HELP & SUPPORT'**
  String get helpSupportPageTitle;

  /// No description provided for @faqSection.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqSection;

  /// No description provided for @faq1Question.
  ///
  /// In en, this message translates to:
  /// **'How does swiping work?'**
  String get faq1Question;

  /// No description provided for @faq1Answer.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to like a movie or show, left to dislike, up for a match (save to watch later), and down to skip. Your choices help us recommend better content.'**
  String get faq1Answer;

  /// No description provided for @faq2Question.
  ///
  /// In en, this message translates to:
  /// **'How do I add something to my watchlist?'**
  String get faq2Question;

  /// No description provided for @faq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Swipe up on a card to open the match screen, then choose to add to watchlist. You can also open the title and tap the watchlist button on the detail screen.'**
  String get faq2Answer;

  /// No description provided for @faq3Question.
  ///
  /// In en, this message translates to:
  /// **'Can I change my streaming platforms?'**
  String get faq3Question;

  /// No description provided for @faq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Go to Profile → Edit Preferences and select your streaming services. We use this to tailor recommendations.'**
  String get faq3Answer;

  /// No description provided for @faq4Question.
  ///
  /// In en, this message translates to:
  /// **'How do I reset my password?'**
  String get faq4Question;

  /// No description provided for @faq4Answer.
  ///
  /// In en, this message translates to:
  /// **'On the login screen, tap \"Forgot Password?\" and enter your email. We\'ll send you a link to reset it.'**
  String get faq4Answer;

  /// No description provided for @contactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactSection;

  /// No description provided for @emailSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupportLabel;

  /// No description provided for @emailSupportAddress.
  ///
  /// In en, this message translates to:
  /// **'support@popmatch.app'**
  String get emailSupportAddress;

  /// No description provided for @emailErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app. Contact: support@popmatch.app'**
  String get emailErrorSnackbar;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Swipe-based movie and show discovery. Find what to watch next.'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @editPreferencesAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get editPreferencesAppBarTitle;

  /// No description provided for @genrePageTitle.
  ///
  /// In en, this message translates to:
  /// **'What genres do you love?'**
  String get genrePageTitle;

  /// No description provided for @genrePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite movie genres to get better recommendations.'**
  String get genrePageSubtitle;

  /// No description provided for @platformPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you watch movies?'**
  String get platformPageTitle;

  /// No description provided for @platformPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your streaming platforms to find movies available on your services.'**
  String get platformPageSubtitle;

  /// No description provided for @pageIndicatorOf2.
  ///
  /// In en, this message translates to:
  /// **'{page} of 2'**
  String pageIndicatorOf2(int page);

  /// No description provided for @preferencesSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully!'**
  String get preferencesSavedSnackbar;

  /// No description provided for @socialPageTitle.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL'**
  String get socialPageTitle;

  /// No description provided for @friendsWatchingCard.
  ///
  /// In en, this message translates to:
  /// **'What your friends are watching'**
  String get friendsWatchingCard;

  /// No description provided for @friendsWatchingCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe cards based on people you follow'**
  String get friendsWatchingCardSubtitle;

  /// No description provided for @sharedWithYouCard.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get sharedWithYouCard;

  /// No description provided for @sharedWithYouCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lists your friends sent you'**
  String get sharedWithYouCardSubtitle;

  /// No description provided for @sharedWithYouPageTitle.
  ///
  /// In en, this message translates to:
  /// **'SHARED WITH YOU'**
  String get sharedWithYouPageTitle;

  /// No description provided for @sharedWithYouEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared yet'**
  String get sharedWithYouEmptyTitle;

  /// No description provided for @sharedWithYouEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When a friend shares a list with you, it\'ll show up here.'**
  String get sharedWithYouEmptyBody;

  /// No description provided for @sharedWithYouErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load shared lists. Please try again.'**
  String get sharedWithYouErrorBody;

  /// No description provided for @sharedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String sharedByLabel(String name);

  /// No description provided for @sharedByFallbackName.
  ///
  /// In en, this message translates to:
  /// **'A friend'**
  String get sharedByFallbackName;

  /// No description provided for @sharedListItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 title} other{{count} titles}}'**
  String sharedListItemsCount(int count);

  /// No description provided for @saveToMyListsButton.
  ///
  /// In en, this message translates to:
  /// **'Save to my lists'**
  String get saveToMyListsButton;

  /// No description provided for @savedToMyListsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved to your lists'**
  String get savedToMyListsSnackbar;

  /// No description provided for @sharedListExistsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You already have a list with that name'**
  String get sharedListExistsSnackbar;

  /// No description provided for @sharedListSaveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the list. Please try again.'**
  String get sharedListSaveFailedSnackbar;

  /// No description provided for @shareListMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Share with a friend'**
  String get shareListMenuItem;

  /// No description provided for @shareListEmptySnackbar.
  ///
  /// In en, this message translates to:
  /// **'This list is empty — add titles before sharing.'**
  String get shareListEmptySnackbar;

  /// No description provided for @shareListNoFriendsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Follow someone first to share a list with them.'**
  String get shareListNoFriendsSnackbar;

  /// No description provided for @shareListPickFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with…'**
  String get shareListPickFriendTitle;

  /// No description provided for @listSharedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Shared with {name}'**
  String listSharedSnackbar(String name);

  /// No description provided for @shareListFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the list. Please try again.'**
  String get shareListFailedSnackbar;

  /// No description provided for @matchesCard.
  ///
  /// In en, this message translates to:
  /// **'Your matches'**
  String get matchesCard;

  /// No description provided for @matchesCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Movies and shows you both liked'**
  String get matchesCardSubtitle;

  /// No description provided for @matchesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR MATCHES'**
  String get matchesPageTitle;

  /// No description provided for @matchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesEmptyTitle;

  /// No description provided for @matchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Like more titles, or follow more friends to find movies you both love.'**
  String get matchesEmptyBody;

  /// No description provided for @matchesErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your matches. Please try again.'**
  String get matchesErrorBody;

  /// No description provided for @matchesWithFriend.
  ///
  /// In en, this message translates to:
  /// **'You & {name}'**
  String matchesWithFriend(String name);

  /// No description provided for @matchesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String matchesCountLabel(int count);

  /// No description provided for @findUsersSection.
  ///
  /// In en, this message translates to:
  /// **'Find users'**
  String get findUsersSection;

  /// No description provided for @socialSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get socialSearchHint;

  /// No description provided for @followingStatus.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @followButton.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followButton;

  /// No description provided for @followRequestSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Follow request sent'**
  String get followRequestSentSnackbar;

  /// No description provided for @followRequestsSection.
  ///
  /// In en, this message translates to:
  /// **'Follow requests'**
  String get followRequestsSection;

  /// No description provided for @noFollowRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noFollowRequests;

  /// No description provided for @wantsToFollowYou.
  ///
  /// In en, this message translates to:
  /// **'wants to follow you'**
  String get wantsToFollowYou;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @friendsWatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS WATCHING'**
  String get friendsWatchingTitle;

  /// No description provided for @feedDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Friends feed is currently disabled.'**
  String get feedDisabledMessage;

  /// No description provided for @friendsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No friend activity yet.\nFollow more people and check back soon.'**
  String get friendsEmptyState;

  /// No description provided for @friendsFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'What your friends are watching'**
  String get friendsFeedTitle;

  /// No description provided for @moodAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get moodAppBarTitle;

  /// No description provided for @moodPageTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your mood today?'**
  String get moodPageTitle;

  /// No description provided for @moodPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll recommend movies that match your current vibe'**
  String get moodPageSubtitle;

  /// No description provided for @selectMoodButton.
  ///
  /// In en, this message translates to:
  /// **'Select Your Mood'**
  String get selectMoodButton;

  /// No description provided for @findMoodMoviesButton.
  ///
  /// In en, this message translates to:
  /// **'Find {moodName} Movies'**
  String findMoodMoviesButton(String moodName);

  /// No description provided for @advancedFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFiltersTitle;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @filtersTab.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTab;

  /// No description provided for @sortTab.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTab;

  /// No description provided for @resultsTab.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTab;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortByTitle;

  /// No description provided for @sortDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort Direction:'**
  String get sortDirectionLabel;

  /// No description provided for @descendingOption.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descendingOption;

  /// No description provided for @ascendingOption.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascendingOption;

  /// No description provided for @noMoviesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No movies match your filters'**
  String get noMoviesMatchFilters;

  /// No description provided for @tryAdjustingFilterCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria'**
  String get tryAdjustingFilterCriteria;

  /// No description provided for @applyFiltersCount.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters ({count} movies)'**
  String applyFiltersCount(int count);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @genresFilter.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genresFilter;

  /// No description provided for @yearRangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Year Range'**
  String get yearRangeFilter;

  /// No description provided for @ratingRangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Rating Range'**
  String get ratingRangeFilter;

  /// No description provided for @minRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Rating'**
  String get minRatingLabel;

  /// No description provided for @maxRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Rating'**
  String get maxRatingLabel;

  /// No description provided for @languagesFilter.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesFilter;

  /// No description provided for @contentTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get contentTypeFilter;

  /// No description provided for @allContentOption.
  ///
  /// In en, this message translates to:
  /// **'All Content'**
  String get allContentOption;

  /// No description provided for @familyFriendlyOption.
  ///
  /// In en, this message translates to:
  /// **'Family Friendly'**
  String get familyFriendlyOption;

  /// No description provided for @adultContentOption.
  ///
  /// In en, this message translates to:
  /// **'Adult Content'**
  String get adultContentOption;

  /// No description provided for @availabilityFilter.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityFilter;

  /// No description provided for @showOnlyAvailableStream.
  ///
  /// In en, this message translates to:
  /// **'Show only available to stream'**
  String get showOnlyAvailableStream;

  /// No description provided for @temporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable in this build'**
  String get temporarilyUnavailable;

  /// No description provided for @popularitySort.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularitySort;

  /// No description provided for @runtimeSort.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtimeSort;

  /// No description provided for @releaseDateSort.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDateSort;

  /// No description provided for @streamingFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Streaming Filters'**
  String get streamingFiltersTitle;

  /// No description provided for @clearFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFiltersTooltip;

  /// No description provided for @filterByPlatformTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by Streaming Platform'**
  String get filterByPlatformTitle;

  /// No description provided for @failedToLoadMovies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load movies'**
  String get failedToLoadMovies;

  /// No description provided for @noMoviesFoundFilter.
  ///
  /// In en, this message translates to:
  /// **'No movies found'**
  String get noMoviesFoundFilter;

  /// No description provided for @tryDifferentPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Try selecting different streaming platforms'**
  String get tryDifferentPlatforms;

  /// No description provided for @moviesFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} movies found'**
  String moviesFoundCount(int count);

  /// No description provided for @filteredByPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Filtered by {count} platform(s)'**
  String filteredByPlatforms(int count);

  /// No description provided for @searchingText.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingText;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @tryDifferentTitleKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different title or keyword'**
  String get tryDifferentTitleKeyword;

  /// No description provided for @noShowsFound.
  ///
  /// In en, this message translates to:
  /// **'No shows found'**
  String get noShowsFound;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @searchForMoviesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for movies, actors, or genres'**
  String get searchForMoviesHint;

  /// No description provided for @recentSearchesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your recent searches will appear here'**
  String get recentSearchesAppearHere;

  /// No description provided for @likedByFriendsLabel.
  ///
  /// In en, this message translates to:
  /// **'Liked by friends'**
  String get likedByFriendsLabel;

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// No description provided for @likeLabel.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeLabel;

  /// No description provided for @synopsisLabel.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsisLabel;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// No description provided for @showLessLabel.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLessLabel;

  /// No description provided for @castCrewLabel.
  ///
  /// In en, this message translates to:
  /// **'Cast & Crew'**
  String get castCrewLabel;

  /// No description provided for @trailersVideosLabel.
  ///
  /// In en, this message translates to:
  /// **'Trailers & Videos'**
  String get trailersVideosLabel;

  /// No description provided for @moviesLikeThisLabel.
  ///
  /// In en, this message translates to:
  /// **'Movies Like This'**
  String get moviesLikeThisLabel;

  /// No description provided for @showsLikeThisLabel.
  ///
  /// In en, this message translates to:
  /// **'Shows Like This'**
  String get showsLikeThisLabel;

  /// No description provided for @failedToLoadSimilarShows.
  ///
  /// In en, this message translates to:
  /// **'Failed to load similar shows'**
  String get failedToLoadSimilarShows;

  /// No description provided for @noSimilarShowsFound.
  ///
  /// In en, this message translates to:
  /// **'No similar shows found'**
  String get noSimilarShowsFound;

  /// No description provided for @failedToLoadSimilarMovies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load similar movies'**
  String get failedToLoadSimilarMovies;

  /// No description provided for @noSimilarMoviesFound.
  ///
  /// In en, this message translates to:
  /// **'No similar movies found'**
  String get noSimilarMoviesFound;

  /// No description provided for @whereToWatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Where to Watch:'**
  String get whereToWatchLabel;

  /// No description provided for @removedFromFavoritesSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from favorites'**
  String removedFromFavoritesSnackbar(String title);

  /// No description provided for @addedToFavoritesSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added {title} to favorites'**
  String addedToFavoritesSnackbar(String title);

  /// No description provided for @removedFromDislikedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed {title} from disliked'**
  String removedFromDislikedSnackbar(String title);

  /// No description provided for @addedToDislikedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added {title} to disliked'**
  String addedToDislikedSnackbar(String title);

  /// No description provided for @noSeasonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No seasons available'**
  String get noSeasonsAvailable;

  /// No description provided for @seasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonLabel(int number);

  /// No description provided for @episodesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Episodes'**
  String episodesLabel(int count);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesLabel(int count);

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria'**
  String get tryAdjustingFilters;

  /// No description provided for @ratingRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating Range'**
  String get ratingRangeLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @contentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get contentTypeLabel;

  /// No description provided for @allContentLabel.
  ///
  /// In en, this message translates to:
  /// **'All Content'**
  String get allContentLabel;

  /// No description provided for @familyFriendlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Friendly'**
  String get familyFriendlyLabel;

  /// No description provided for @adultContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Adult Content'**
  String get adultContentLabel;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel;

  /// No description provided for @showOnlyStreamableLabel.
  ///
  /// In en, this message translates to:
  /// **'Show only available to stream'**
  String get showOnlyStreamableLabel;

  /// No description provided for @temporarilyUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable in this build'**
  String get temporarilyUnavailableLabel;

  /// No description provided for @popularityOption.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularityOption;

  /// No description provided for @runtimeOption.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtimeOption;

  /// No description provided for @releaseDateOption.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDateOption;

  /// No description provided for @upToRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Up to {rating}'**
  String upToRatingLabel(String rating);

  /// No description provided for @myWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get myWatchlistTitle;

  /// No description provided for @exportDataButton.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataButton;

  /// No description provided for @noMoviesMatchFiltersShort.
  ///
  /// In en, this message translates to:
  /// **'No movies match your filters'**
  String get noMoviesMatchFiltersShort;

  /// No description provided for @addSomeMovies.
  ///
  /// In en, this message translates to:
  /// **'Add some movies to get started!'**
  String get addSomeMovies;

  /// No description provided for @addTagsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add tags to your movies to organize them better'**
  String get addTagsDescription;

  /// No description provided for @listNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a list name'**
  String get listNameError;

  /// No description provided for @createdListSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Created list: {name}'**
  String createdListSnackbar(String name);

  /// No description provided for @exportDataLocalSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Watchlist data export generated locally. Sharing/download will be added in a future update.'**
  String get exportDataLocalSnackbar;

  /// No description provided for @failedToExportSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Failed to export data: {error}'**
  String failedToExportSnackbar(String error);

  /// No description provided for @listsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Your lists'**
  String get listsTooltip;

  /// No description provided for @addToListTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToListTitle;

  /// No description provided for @listNameExists.
  ///
  /// In en, this message translates to:
  /// **'A list with that name already exists.'**
  String get listNameExists;

  /// No description provided for @noListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet — create one below.'**
  String get noListsYet;

  /// No description provided for @newListHint.
  ///
  /// In en, this message translates to:
  /// **'New list name'**
  String get newListHint;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @addTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get addTagHint;

  /// No description provided for @forYouTitle.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYouTitle;

  /// No description provided for @forYouTooltip.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYouTooltip;

  /// No description provided for @forYouBecauseYouLiked.
  ///
  /// In en, this message translates to:
  /// **'Because You Liked'**
  String get forYouBecauseYouLiked;

  /// No description provided for @forYouRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get forYouRecommended;

  /// No description provided for @forYouTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get forYouTrending;

  /// No description provided for @forYouFriendsWatching.
  ///
  /// In en, this message translates to:
  /// **'Friends Are Watching'**
  String get forYouFriendsWatching;

  /// No description provided for @forYouTopPick.
  ///
  /// In en, this message translates to:
  /// **'Top Pick for You'**
  String get forYouTopPick;

  /// No description provided for @forYouCurating.
  ///
  /// In en, this message translates to:
  /// **'Curating your picks…'**
  String get forYouCurating;

  /// No description provided for @forYouOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get forYouOpen;

  /// No description provided for @forYouEmpty.
  ///
  /// In en, this message translates to:
  /// **'Like a few titles and your personalized picks will show up here.'**
  String get forYouEmpty;

  /// No description provided for @premiumUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'PopMatch Premium'**
  String get premiumUpsellTitle;

  /// No description provided for @premiumPerkUnlimitedSwipes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited swipes'**
  String get premiumPerkUnlimitedSwipes;

  /// No description provided for @premiumPerkNoAds.
  ///
  /// In en, this message translates to:
  /// **'Ad-free experience'**
  String get premiumPerkNoAds;

  /// No description provided for @premiumPerkForYou.
  ///
  /// In en, this message translates to:
  /// **'Personalized “For You” recommendations'**
  String get premiumPerkForYou;

  /// No description provided for @premiumUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get premiumUpgradeCta;

  /// No description provided for @premiumComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are coming soon.'**
  String get premiumComingSoon;

  /// No description provided for @premiumDevEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Premium (dev)'**
  String get premiumDevEnable;

  /// No description provided for @signInFailedError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInFailedError;

  /// No description provided for @resetEnterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'ENTER CODE'**
  String get resetEnterCodeTitle;

  /// No description provided for @resetCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String resetCodeSentTo(String email);

  /// No description provided for @resetDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD RESET'**
  String get resetDoneTitle;

  /// No description provided for @resetDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get resetDoneSubtitle;

  /// No description provided for @resetCodeOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'If that email has an account, a code is on its way.'**
  String get resetCodeOnItsWay;

  /// No description provided for @resetEnterCodeError.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get resetEnterCodeError;

  /// No description provided for @sendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCodeButton;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @backToSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignInButton;

  /// No description provided for @resendCodeInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeInSeconds(int seconds);

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @resetNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get resetNewPasswordTitle;

  /// No description provided for @resetNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get resetNewPasswordSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
