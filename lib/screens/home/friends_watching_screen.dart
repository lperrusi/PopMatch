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
  final CardSwiperController _swiperController = CardSwiperController();
  final List<_SocialFeedCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final social = context.read<SocialProvider>();
    await social.loadFriendsFeed();
    final activities = social.friendsFeed;
    final tmdb = TMDBService();

    final dedupe = <String>{};
    final cards = <_SocialFeedCard>[];
    for (final activity in activities) {
      final key = '${activity.itemType.name}:${activity.itemId}';
      if (!dedupe.add(key)) continue;

      final actor = activity.actorDisplayName?.trim().isNotEmpty == true
          ? activity.actorDisplayName!
          : 'A friend';
      final reason = 'Liked by $actor';

      try {
        if (activity.itemType == SocialItemType.movie) {
          final movie = await tmdb.getMovieDetails(int.parse(activity.itemId));
          cards.add(_SocialFeedCard.movie(movie, reason));
        } else {
          final show = await tmdb.getShowDetails(int.parse(activity.itemId));
          cards.add(_SocialFeedCard.show(show, reason));
        }
      } catch (_) {
        // Skip items that fail to resolve.
      }
    }

    if (!mounted) return;
    setState(() {
      _cards
        ..clear()
        ..addAll(cards);
      _loading = false;
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
          'FRIENDS WATCHING',
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
                    'Friends feed is currently disabled.',
                    style: GoogleFonts.lato(
                      color: AppTheme.warmCream,
                      fontSize: 16,
                    ),
                  ),
                )
          : _cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No friend activity yet.\nFollow more people and check back soon.',
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
                      'What your friends are watching',
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
                          onSwipe: (_, __, ___) => true,
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
