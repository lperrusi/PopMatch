import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/movie.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../services/feature_flags.dart';
import '../../services/tmdb_service.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/recommendation_filters.dart';
import '../../utils/theme.dart';
import '../../widgets/for_you/for_you_hero_card.dart';
import '../../widgets/for_you/for_you_rail.dart';
import '../../widgets/transparent_button_image.dart';
import 'movie_detail_screen.dart';

/// Premium-only browsable recommendations surface. The personalized rail + hero
/// come from the canonical scoring engine ([MovieProvider.buildForYouRecommendations]);
/// every rail is hard-filtered (no already-liked/disliked or sub-quality titles)
/// so a premium "Top Picks" surface never shows a likely-dislike. Tapping a
/// poster opens its detail screen.
class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with SingleTickerProviderStateMixin {
  List<Movie> _forYou = [];
  bool _loadingForYou = false;
  bool _loadingTrending = false;
  bool _friendsLoaded = false;
  bool _forceReady = false;
  Set<int> _userGenreIds = {};

  // "Because you liked {title}" rail — seeded from the user's most recent like.
  List<Movie> _becauseYouLiked = [];
  String? _becauseSeedTitle;
  bool _becauseReady = false;

  late final AnimationController _pulseController;
  Timer? _revealFallback;

  bool get _friendsEnabled =>
      FeatureFlags.socialUiEnabled && FeatureFlags.friendsFeedEnabled;

  /// Hold the branded "curating" loader until the core sections (personalized +
  /// trending) are ready, then cross-fade in. Friends loads silently and never
  /// gates the reveal. [_forceReady] is a safety net against a hung load.
  bool get _isReady => _forceReady || (!_loadingForYou && !_loadingTrending);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
      _revealFallback = Timer(const Duration(seconds: 6), () {
        if (mounted && !_forceReady) setState(() => _forceReady = true);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealFallback?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final rec = context.read<RecommendationsProvider>();
    final movieProvider = context.read<MovieProvider>();
    final user = auth.userData;
    if (user == null) return;
    rec.setCurrentUser(user);

    _userGenreIds = _genreIdsFrom(user.preferences['selectedGenres']);

    // Show every section's skeleton up front, then load in parallel so each
    // rail fills in independently (no section pops in late behind another).
    setState(() {
      _loadingForYou = true;
      _loadingTrending = true;
    });

    await Future.wait([
      _loadForYou(movieProvider, user),
      _loadTrending(rec),
      _loadBecauseYouLiked(user),
      if (_friendsEnabled) _loadFriends(rec),
    ]);
  }

  /// Loads a "Because you liked {title}" rail from the user's most recent like
  /// (silent — like the Friends rail, it never gates the reveal and stays hidden
  /// when there's no seed or no similar titles resolve).
  Future<void> _loadBecauseYouLiked(User user) async {
    final seedId = mostRecentLikedMovieId(user.likedMovies);
    if (seedId == null) {
      if (mounted) setState(() => _becauseReady = true);
      return;
    }
    try {
      final tmdb = TMDBService();
      final seed = await tmdb.getMovieDetails(seedId);
      final similar = await tmdb.getSimilarMovies(seedId);
      if (!mounted) return;
      setState(() {
        _becauseYouLiked = similar;
        _becauseSeedTitle = seed.title;
        _becauseReady = true;
      });
    } catch (e) {
      debugPrint('ForYou: because-you-liked load failed: $e');
      if (mounted) setState(() => _becauseReady = true);
    }
  }

  /// Personalized hero + rail — canonical engine (already filtered + scored).
  Future<void> _loadForYou(MovieProvider movieProvider, User user) async {
    final forYou = await movieProvider.buildForYouRecommendations(user);
    if (mounted) {
      setState(() {
        _forYou = forYou;
        _loadingForYou = false;
      });
    }
  }

  Future<void> _loadTrending(RecommendationsProvider rec) async {
    await rec.loadTrendingRecommendations();
    if (mounted) setState(() => _loadingTrending = false);
  }

  /// Loads silently — the Friends rail only appears once it has filtered
  /// content (avoids a loading flash when there are no friends).
  Future<void> _loadFriends(RecommendationsProvider rec) async {
    await rec.loadFriendsRecommendations(refresh: true);
    if (mounted) setState(() => _friendsLoaded = true);
  }

  Set<int> _genreIdsFrom(dynamic raw) {
    final ids = <int>{};
    if (raw is List) {
      for (final g in raw) {
        final id = g is int ? g : int.tryParse(g.toString());
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  void _openDetail(Movie movie) {
    Navigator.of(context).push(
      NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final user = auth.userData;
    final excludeIds = user == null
        ? <int>{}
        : likedDislikedIds(
            liked: user.likedMovies, disliked: user.dislikedMovies);

    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
        title: Text(
          l10n.forYouTitle.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            fontSize: 30,
            color: AppTheme.warmCream,
            letterSpacing: 1.5,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.workspace_premium_rounded,
                color: AppTheme.popcornGold),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _isReady
            ? _buildContent(excludeIds)
            : _buildCuratingLoader(),
      ),
    );
  }

  Widget _buildContent(Set<int> excludeIds) {
    final l10n = context.l10n;
    return Consumer<RecommendationsProvider>(
      key: const ValueKey('forYouContent'),
      builder: (context, rec, _) {
          final hero = _forYou.isNotEmpty ? _forYou.first : null;
          final heroId = hero?.id;

          // Cumulative de-dup: a title appears in only its highest-priority rail
          // (hero → Recommended → Trending → Friends).
          final shown = <int>{if (heroId != null) heroId};
          List<Movie> takeUnshown(List<Movie> list) {
            final out = <Movie>[];
            for (final m in list) {
              if (shown.add(m.id)) out.add(m);
            }
            return out;
          }

          // Highest-priority rail after the hero, so it claims its titles first.
          final because =
              takeUnshown(filterForYou(_becauseYouLiked, excludeIds: excludeIds));
          final recommended = takeUnshown(_forYou);
          final trending = takeUnshown(
            filterForYou(rec.trendingRecommendations, excludeIds: excludeIds),
          );
          final friends = takeUnshown(
            filterForYou(
              rec.friendsRecommendations,
              excludeIds: excludeIds,
              requireGenreOverlap: _userGenreIds,
            ),
          );

          final everythingEmpty = !_loadingForYou &&
              !_loadingTrending &&
              hero == null &&
              because.isEmpty &&
              recommended.isEmpty &&
              trending.isEmpty &&
              friends.isEmpty;

          return RefreshIndicator(
            color: AppTheme.cinemaRed,
            onRefresh: _loadAll,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                ForYouHeroCard(
                  movie: hero,
                  isLoading: hero == null && _loadingForYou,
                  onTap: () {
                    if (hero != null) _openDetail(hero);
                  },
                ),
                if (_becauseReady &&
                    _becauseSeedTitle != null &&
                    because.isNotEmpty)
                  ForYouRail(
                    title: l10n.forYouBecauseYouLikedTitle(_becauseSeedTitle!),
                    movies: because,
                    isLoading: false,
                    onTap: _openDetail,
                  ),
                ForYouRail(
                  title: l10n.forYouRecommended,
                  movies: recommended,
                  isLoading: _loadingForYou,
                  onTap: _openDetail,
                ),
                ForYouRail(
                  title: l10n.forYouTrending,
                  movies: trending,
                  isLoading: _loadingTrending,
                  onTap: _openDetail,
                ),
                // Friends: render only once loaded with filtered content (no flash).
                if (_friendsEnabled && _friendsLoaded && friends.isNotEmpty)
                  ForYouRail(
                    title: l10n.forYouFriendsWatching,
                    movies: friends,
                    isLoading: false,
                    onTap: _openDetail,
                  ),
                if (everythingEmpty) _buildEmptyState(),
              ],
            ),
          );
        },
      );
  }

  /// Branded "curating your picks" loader shown until the core sections are
  /// ready, then cross-faded out. Premium feel: a gently pulsing gold ticket.
  Widget _buildCuratingLoader() {
    final l10n = context.l10n;
    final pulse =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    return Center(
      key: const ValueKey('forYouLoader'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.65, end: 1.0).animate(pulse),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.05).animate(pulse),
              child: const TransparentButtonImage(
                assetPath: 'assets/buttons/vip_access_ticket_icon.png',
                width: 104,
                height: 104,
                fit: BoxFit.contain,
                errorWidget: Icon(Icons.workspace_premium_rounded,
                    size: 88, color: AppTheme.popcornGold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.forYouCurating,
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: AppTheme.cinemaRed,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      child: Column(
        children: [
          Icon(Icons.auto_awesome,
              size: 56, color: AppTheme.filmStripBlack.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            l10n.forYouEmpty,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 15,
              color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
