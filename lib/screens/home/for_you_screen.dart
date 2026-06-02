import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../services/feature_flags.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/for_you/for_you_hero_card.dart';
import '../../widgets/for_you/for_you_rail.dart';
import 'movie_detail_screen.dart';

/// Premium-only browsable recommendations surface: a featured hero + Retro
/// Cinema rails (Because You Liked / Trending / Friends) sourced from
/// [RecommendationsProvider]. Tapping a poster opens its detail screen (which
/// owns like/watchlist), so there's no swipe-bypassing like/dislike here.
class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  bool _loadingBecause = false;
  bool _loadingTrending = false;
  bool _loadingFriends = false;
  bool _hasLikedSeed = false;

  bool get _friendsEnabled =>
      FeatureFlags.socialUiEnabled && FeatureFlags.friendsFeedEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final rec = context.read<RecommendationsProvider>();
    final user = auth.userData;
    if (user != null) rec.setCurrentUser(user);

    // Because You Liked — seed from the most recently liked title.
    final likedSeed = (user != null && user.likedMovies.isNotEmpty)
        ? user.likedMovies.last
        : null;
    if (likedSeed != null) {
      setState(() {
        _hasLikedSeed = true;
        _loadingBecause = true;
      });
      await rec.loadBecauseYouLikedRecommendations(likedSeed);
      if (mounted) setState(() => _loadingBecause = false);
    }

    if (!mounted) return;
    setState(() => _loadingTrending = true);
    await rec.loadTrendingRecommendations();
    if (mounted) setState(() => _loadingTrending = false);

    if (_friendsEnabled) {
      if (!mounted) return;
      setState(() => _loadingFriends = true);
      await rec.loadFriendsRecommendations(refresh: true);
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  void _openDetail(Movie movie) {
    Navigator.of(context).push(
      NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
    );
  }

  List<Movie> _excludeHero(List<Movie> list, Movie? hero) {
    if (hero == null) return list;
    return list.where((m) => m.id != hero.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
      body: Consumer<RecommendationsProvider>(
        builder: (context, rec, _) {
          final because = rec.becauseYouLikedRecommendations;
          final trending = rec.trendingRecommendations;
          final friends = rec.friendsRecommendations;

          final hero = because.isNotEmpty
              ? because.first
              : (trending.isNotEmpty ? trending.first : null);
          final heroLoading =
              hero == null && (_loadingBecause || _loadingTrending);

          final anyLoading =
              _loadingBecause || _loadingTrending || _loadingFriends;
          final everythingEmpty = hero == null &&
              because.isEmpty &&
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
                  isLoading: heroLoading,
                  onTap: () {
                    if (hero != null) _openDetail(hero);
                  },
                ),
                if (_hasLikedSeed)
                  ForYouRail(
                    title: l10n.forYouBecauseYouLiked,
                    movies: _excludeHero(because, hero),
                    isLoading: _loadingBecause,
                    onTap: _openDetail,
                  ),
                ForYouRail(
                  title: l10n.forYouTrending,
                  movies: _excludeHero(trending, hero),
                  isLoading: _loadingTrending,
                  onTap: _openDetail,
                ),
                if (_friendsEnabled)
                  ForYouRail(
                    title: l10n.forYouFriendsWatching,
                    movies: _excludeHero(friends, hero),
                    isLoading: _loadingFriends,
                    onTap: _openDetail,
                  ),
                if (!anyLoading && everythingEmpty) _buildEmptyState(),
              ],
            ),
          );
        },
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
