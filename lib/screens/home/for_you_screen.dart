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
import '../../widgets/recommendations_widget.dart';
import 'movie_detail_screen.dart';

/// Premium-only browsable recommendations surface: horizontal rails sourced from
/// [RecommendationsProvider] (Because You Liked / Trending / Friends). Tapping a
/// poster opens its detail screen (which owns like/watchlist actions), so there
/// is no swipe-bypassing like/dislike here.
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
      ),
      body: Consumer<RecommendationsProvider>(
        builder: (context, rec, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              if (_hasLikedSeed)
                RecommendationsWidget(
                  title: l10n.forYouBecauseYouLiked,
                  movies: rec.becauseYouLikedRecommendations,
                  isLoading: _loadingBecause,
                  showActions: false,
                  onMovieTap: _openDetail,
                ),
              RecommendationsWidget(
                title: l10n.forYouTrending,
                movies: rec.trendingRecommendations,
                isLoading: _loadingTrending,
                showActions: false,
                onMovieTap: _openDetail,
              ),
              if (_friendsEnabled &&
                  (_loadingFriends || rec.friendsRecommendations.isNotEmpty))
                RecommendationsWidget(
                  title: l10n.forYouFriendsWatching,
                  movies: rec.friendsRecommendations,
                  isLoading: _loadingFriends,
                  showActions: false,
                  onMovieTap: _openDetail,
                ),
            ],
          );
        },
      ),
    );
  }
}
