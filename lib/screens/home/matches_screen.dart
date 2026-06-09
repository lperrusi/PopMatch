import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/friend_match.dart';
import '../../models/movie.dart';
import '../../models/social_activity.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/tmdb_service.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/poster_list_skeleton.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

/// "Your Matches" — titles the current user and a followed friend both liked,
/// grouped per friend. Computed client-side from the friends feed ∩ the user's
/// likes (see [SocialProvider.matchesFor]); posters are resolved from TMDB.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // Safety cap so an unusually large overlap can't fan out into a request storm.
  static const int _maxResolved = 60;

  bool _loading = true;
  bool _error = false;
  List<FriendMatch> _matches = const [];
  // Resolved TMDB details keyed by MatchItem.key (`movie:603`).
  final Map<String, Movie> _movies = {};
  final Map<String, TvShow> _shows = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    final social = context.read<SocialProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.userData;

    try {
      await social.loadFriendsFeed();
      if (!mounted) return;

      final myMovies = user?.likedMovies.toSet() ?? <String>{};
      final myShows = user?.likedShows.toSet() ?? <String>{};
      final matches = social.matchesFor(
        myLikedMovieIds: myMovies,
        myLikedShowIds: myShows,
        selfUid: user?.id,
      );

      // Resolve friend display names for any that are still generic.
      await social
          .resolveNames(matches.map((m) => m.friendUid).toList());
      if (!mounted) return;

      await _resolvePosters(matches);
      if (!mounted) return;

      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      debugPrint('MatchesScreen load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  /// Resolves each unique matched item once (skip-on-failure, bounded).
  Future<void> _resolvePosters(List<FriendMatch> matches) async {
    final tmdb = TMDBService();
    final seen = <String>{};
    var resolved = 0;
    for (final match in matches) {
      for (final item in match.items) {
        if (resolved >= _maxResolved) return;
        if (!seen.add(item.key)) continue;
        if (_movies.containsKey(item.key) || _shows.containsKey(item.key)) {
          continue;
        }
        try {
          final id = int.parse(item.itemId);
          if (item.itemType == SocialItemType.movie) {
            _movies[item.key] = await tmdb.getMovieDetails(id);
          } else {
            _shows[item.key] = await tmdb.getShowDetails(id);
          }
          resolved++;
        } catch (e) {
          debugPrint('MatchesScreen: failed to resolve ${item.key}: $e');
        }
      }
    }
  }

  void _openItem(MatchItem item) {
    final movie = _movies[item.key];
    final show = _shows[item.key];
    if (movie != null) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
      );
    } else if (show != null) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.matchesPageTitle,
          style: GoogleFonts.bebasNeue(
            fontSize: 30,
            color: AppTheme.warmCream,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
      ),
      body: _loading
          ? const PosterListSkeleton()
          : _error
              ? _buildErrorState()
              : _matches.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppTheme.cinemaRed),
            const SizedBox(height: 12),
            Text(
              l10n.matchesErrorBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 64, color: AppTheme.cinemaRed),
            const SizedBox(height: 16),
            Text(
              l10n.matchesEmptyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchesEmptyBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _matches.length,
        itemBuilder: (context, index) => _buildFriendSection(_matches[index]),
      ),
    );
  }

  Widget _buildFriendSection(FriendMatch match) {
    final l10n = context.l10n;
    // Only show items whose posters resolved; skip the section if none did.
    final resolved = match.items
        .where((i) => _movies.containsKey(i.key) || _shows.containsKey(i.key))
        .toList();
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  size: 20, color: AppTheme.cinemaRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.matchesWithFriend(match.friendName),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cinemaRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.matchesCountLabel(resolved.length),
                  style: GoogleFonts.lato(
                    color: AppTheme.warmCream,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: resolved.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _buildPosterCard(resolved[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterCard(MatchItem item) {
    final movie = _movies[item.key];
    final show = _shows[item.key];
    final posterUrl = movie?.posterUrl ?? show?.posterUrl;
    final title = movie?.title ?? show?.name ?? '';

    return GestureDetector(
      onTap: () => _openItem(item),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 170,
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppTheme.filmStripBlack.withValues(alpha: 0.1)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                          child: const Icon(Icons.movie_rounded,
                              color: AppTheme.sepiaBrown),
                        ),
                      )
                    : Container(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                        child: const Icon(Icons.movie_rounded,
                            color: AppTheme.sepiaBrown),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
