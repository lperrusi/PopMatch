import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/social_activity.dart';
import '../../providers/social_provider.dart';
import '../../services/tmdb_service.dart';
import '../../services/feature_flags.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/retro_cinema_movie_card.dart';
import '../../widgets/retro_cinema_show_card.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

class FriendsWatchingScreen extends StatefulWidget {
  const FriendsWatchingScreen({super.key});

  @override
  State<FriendsWatchingScreen> createState() => _FriendsWatchingScreenState();
}

class _SocialFeedCard {
  final Movie? movie;
  final TvShow? show;
  final String reason;

  const _SocialFeedCard.movie(this.movie, this.reason) : show = null;
  const _SocialFeedCard.show(this.show, this.reason) : movie = null;
}

class _FriendsWatchingScreenState extends State<FriendsWatchingScreen> {
  // Resolve TMDB details in pages so a large friend graph doesn't trigger a
  // burst of requests on open; the next page loads as the deck runs low.
  static const int _pageSize = 20;

  final CardSwiperController _swiperController = CardSwiperController();
  final List<_SocialFeedCard> _cards = [];
  final List<SocialActivity> _activities = [];
  final Set<String> _dedupe = {};
  int _cursor = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  bool get _hasMoreActivities => _cursor < _activities.length;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
        _cards.clear();
        _activities.clear();
        _dedupe.clear();
        _cursor = 0;
      });
    }

    final social = context.read<SocialProvider>();
    await social.loadFriendsFeed();
    if (!mounted) return;
    _activities.addAll(social.friendsFeed);

    await _resolveNextPage(initial: true);
  }

  /// Resolves up to [_pageSize] more activities into displayable cards,
  /// skipping items that fail to fetch. On the initial page, if every item
  /// failed to resolve (but activities existed), surfaces an error state.
  Future<void> _resolveNextPage({bool initial = false}) async {
    if (_loadingMore || !_hasMoreActivities) return;
    _loadingMore = true;

    final tmdb = TMDBService();
    final newCards = <_SocialFeedCard>[];
    int failures = 0;
    int attempted = 0;

    while (_cursor < _activities.length && newCards.length < _pageSize) {
      final activity = _activities[_cursor];
      _cursor++;

      final key = '${activity.itemType.name}:${activity.itemId}';
      if (!_dedupe.add(key)) continue;
      attempted++;

      final actor = activity.actorDisplayName?.trim().isNotEmpty == true
          ? activity.actorDisplayName!
          : 'A friend';
      final reason = 'Liked by $actor';

      try {
        if (activity.itemType == SocialItemType.movie) {
          final movie = await tmdb.getMovieDetails(int.parse(activity.itemId));
          newCards.add(_SocialFeedCard.movie(movie, reason));
        } else {
          final show = await tmdb.getShowDetails(int.parse(activity.itemId));
          newCards.add(_SocialFeedCard.show(show, reason));
        }
      } catch (e) {
        failures++;
        debugPrint(
            'FriendsWatching: failed to resolve ${activity.itemType.name} ${activity.itemId}: $e');
      }
    }

    _loadingMore = false;
    if (!mounted) return;
    setState(() {
      _cards.addAll(newCards);
      _loading = false;
      // Only flag an error when the very first page produced nothing despite
      // having attempted some items — i.e. resolution is broken, not "no feed".
      _error = initial && _cards.isEmpty && attempted > 0 && failures == attempted;
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepMidnightBrown,
      appBar: AppBar(
        backgroundColor: AppTheme.cinemaRed,
        title: Text(
          context.l10n.friendsWatchingTitle,
          style: GoogleFonts.bebasNeue(
            fontSize: 30,
            color: AppTheme.warmCream,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !FeatureFlags.friendsFeedEnabled
              ? Center(
                  child: Text(
                    context.l10n.feedDisabledMessage,
                    style: GoogleFonts.lato(
                      color: AppTheme.warmCream,
                      fontSize: 16,
                    ),
                  ),
                )
          : _error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.failedToLoadMovies,
                          style: GoogleFonts.lato(
                            color: AppTheme.warmCream,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFeed,
                          child: Text(context.l10n.retryButton),
                        ),
                      ],
                    ),
                  ),
                )
          : _cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.friendsEmptyState,
                      style: GoogleFonts.lato(
                        color: AppTheme.warmCream,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.friendsFeedTitle,
                      style: GoogleFonts.bebasNeue(
                        color: AppTheme.warmCream,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cards.first.reason,
                      style: GoogleFonts.lato(
                        color: AppTheme.popcornGold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CardSwiper(
                          controller: _swiperController,
                          cardsCount: _cards.length,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            // Resolve the next page as the deck nears its end.
                            if (currentIndex != null &&
                                _cards.length - currentIndex <= 5 &&
                                _hasMoreActivities) {
                              _resolveNextPage();
                            }
                            return true;
                          },
                          cardBuilder: (context, index, _, __) {
                            final card = _cards[index];
                            if (card.movie != null) {
                              return RetroCinemaMovieCard(
                                movie: card.movie!,
                                onTap: () {
                                  Navigator.of(context).push(
                                    NavigationUtils.fastSlideRoute(
                                      MovieDetailScreen(movie: card.movie!),
                                    ),
                                  );
                                },
                              );
                            }
                            return RetroCinemaShowCard(
                              show: card.show!,
                              onTap: () {
                                Navigator.of(context).push(
                                  NavigationUtils.fastSlideRoute(
                                    ShowDetailScreen(show: card.show!),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
    );
  }
}
