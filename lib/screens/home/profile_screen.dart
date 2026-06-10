import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../providers/social_provider.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../widgets/poster_list_skeleton.dart';
import '../../services/movie_cache_service.dart';
import '../../services/tmdb_service.dart';
import '../../services/feature_flags.dart';
import '../../services/social_service.dart';
import '../auth/login_screen.dart';
import 'edit_preferences_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'help_support_screen.dart';
import 'social_hub_screen.dart';
import 'favorites_screen.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

/// Profile screen showing user information and account management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: AppTheme.warmCream,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = authProvider.userData!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info card - centered
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar (photo from Google/Apple when available)
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.cinemaRed,
                            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                                ? CachedNetworkImageProvider(user.photoURL!)
                                : null,
                            child: user.photoURL == null || user.photoURL!.isEmpty
                                ? Text(
                                    user.email[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Email (theme color so visible on dark card)
                          Text(
                            user.email,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (user.displayName != null && user.displayName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              user.displayName!,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: l10n.watchlistStat,
                        value: (user.watchlist.length + user.watchlistShowsOrEmpty.length).toString(),
                        icon: Icons.bookmark_rounded,
                        color: AppTheme.filmStripBlack,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: l10n.likedMoviesStat,
                        value: user.likedMovies.length.toString(),
                        icon: Icons.favorite_rounded,
                        color: AppTheme.filmStripBlack,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: l10n.likedShowsStat,
                        value: user.likedShows.length.toString(),
                        icon: Icons.tv_rounded,
                        color: AppTheme.filmStripBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recently liked movies (complete: from provider or loaded by ID via MovieCacheService)
                if (user.likedMovies.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentlyLikedMoviesTitle,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          letterSpacing: 1,
                          color: AppTheme.filmStripBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const FavoritesScreen()),
                          );
                        },
                        child: Text(
                          l10n.viewAll,
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cinemaRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RecentLikedMoviesSection(likedMovieIds: user.likedMovies),
                  const SizedBox(height: 20),
                ],

                // Recently liked shows (complete: from provider or loaded by ID via TMDB)
                if (user.likedShows.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentlyLikedShowsTitle,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          letterSpacing: 1,
                          color: AppTheme.filmStripBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const FavoritesScreen()),
                          );
                        },
                        child: Text(
                          l10n.viewAll,
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cinemaRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RecentLikedShowsSection(likedShowIds: user.likedShows),
                  const SizedBox(height: 20),
                ],

                // Account settings
                Text(
                  l10n.accountSettingsTitle,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    letterSpacing: 1,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.onSurface),
                        title: Text(l10n.editPreferencesLabel),
                        subtitle: Text(l10n.editPreferencesSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const EditPreferencesScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
                        title: Text(l10n.notificationsLabel),
                        subtitle: Text(l10n.notificationsSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const NotificationsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.onSurface),
                        title: Text(l10n.privacyLabel),
                        subtitle: Text(l10n.privacySubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const PrivacyScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      if (FeatureFlags.socialUiEnabled) ...[
                        ListTile(
                          leading: Icon(Icons.groups_rounded, color: Theme.of(context).colorScheme.onSurface),
                          title: Text(l10n.socialLabel),
                          subtitle: Text(l10n.socialSubtitle),
                          trailing: Consumer<SocialProvider>(
                            builder: (context, social, _) {
                              final pending = social.incomingRequests.length;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (pending > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cinemaRed,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$pending',
                                        style: GoogleFonts.lato(
                                          color: AppTheme.warmCream,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(Icons.chevron_right),
                                ],
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              NavigationUtils.fastSlideRoute(
                                const SocialHubScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                      ],
                      if (kDebugMode) ...[
                        ListTile(
                          leading: Icon(Icons.science_rounded,
                              color: Theme.of(context).colorScheme.onSurface),
                          title: const Text('Seed social data (dev)'),
                          subtitle: const Text(
                              'Demo friends + activity · needs Firebase + DEV_SEED_ENABLED'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await SocialService.instance.devSeedSocial();
                              messenger.showSnackBar(const SnackBar(
                                  content: Text('Seeded demo social data')));
                            } catch (e) {
                              messenger.showSnackBar(
                                  SnackBar(content: Text('Seed failed: $e')));
                            }
                          },
                        ),
                        const Divider(height: 1),
                      ],
                      ListTile(
                        leading: Icon(Icons.help_outline_rounded, color: Theme.of(context).colorScheme.onSurface),
                        title: Text(l10n.helpSupportLabel),
                        subtitle: Text(l10n.helpSupportSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationUtils.fastSlideRoute(const HelpSupportScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.block_rounded, color: Theme.of(context).colorScheme.onSurface),
                        title: Text(l10n.removeAdsLabel),
                        subtitle: Text(l10n.removeAdsSubtitle),
                        trailing: const Icon(Icons.lock_outline_rounded),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.vintagePaper,
                              title: Text(
                                l10n.comingSoonTitle,
                                style: GoogleFonts.bebasNeue(
                                  color: AppTheme.filmStripBlack,
                                  letterSpacing: 1,
                                ),
                              ),
                              content: Text(
                                l10n.comingSoonMessage,
                                style: GoogleFonts.lato(color: AppTheme.filmStripBlack),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(l10n.okButton, style: GoogleFonts.lato(color: AppTheme.filmStripBlack)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                    ),
                    child: Text(l10n.signOutButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.vintagePaper,
        title: Text(
          context.l10n.signOutTitle,
          style: GoogleFonts.bebasNeue(color: AppTheme.filmStripBlack, letterSpacing: 1),
        ),
        content: Text(
          context.l10n.signOutConfirmation,
          style: GoogleFonts.lato(color: AppTheme.filmStripBlack),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancelButton, style: GoogleFonts.lato(color: AppTheme.filmStripBlack)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cinemaRed,
              foregroundColor: AppTheme.warmCream,
            ),
            child: Text(context.l10n.signOutButton, style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Handles user logout
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

}

/// Recently liked movies: shows first 5 in order of liked IDs; loads by ID if not in MovieProvider.
class _RecentLikedMoviesSection extends StatefulWidget {
  final List<String> likedMovieIds;

  const _RecentLikedMoviesSection({required this.likedMovieIds});

  @override
  State<_RecentLikedMoviesSection> createState() => _RecentLikedMoviesSectionState();
}

class _RecentLikedMoviesSectionState extends State<_RecentLikedMoviesSection> {
  static const int _maxDisplay = 5;
  final Map<String, Movie> _loadedById = {};
  final Set<String> _loadingIds = {};

  void _loadMovieIfNeeded(String id, List<Movie> fromProvider) {
    if (_loadedById.containsKey(id) || _loadingIds.contains(id)) return;
    final inProvider = fromProvider.any((m) => m.id.toString() == id);
    if (inProvider) return;
    final movieId = int.tryParse(id);
    if (movieId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadedById.containsKey(id) || _loadingIds.contains(id)) return;
      setState(() => _loadingIds.add(id));
      MovieCacheService.instance.getMovieDetails(movieId).then((movie) {
        if (!mounted) return;
        setState(() {
          _loadedById[id] = movie;
          _loadingIds.remove(id);
        });
      }).catchError((_) {
        if (mounted) setState(() => _loadingIds.remove(id));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetIds = widget.likedMovieIds.take(_maxDisplay).toList();
    if (targetIds.isEmpty) return const SizedBox.shrink();

    return Consumer<MovieProvider>(
      builder: (context, movieProvider, _) {
        final fromProvider = movieProvider.movies;
        for (final id in targetIds) {
          _loadMovieIfNeeded(id, fromProvider);
        }

        final List<Widget> tiles = [];
        for (final id in targetIds) {
          Movie? movie = _loadedById[id];
          if (movie == null) {
            final found = fromProvider.where((m) => m.id.toString() == id);
            if (found.isNotEmpty) movie = found.first;
          }
          if (movie != null) {
            tiles.add(_LikedMovieTile(
              movie: movie,
              onTap: () {
                Navigator.of(context).push(
                  NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie!)),
                );
              },
            ));
          } else {
            // No data yet: show a shimmer placeholder matching the liked tile.
            tiles.add(const PosterListTileSkeleton());
          }
        }
        return Column(children: tiles);
      },
    );
  }
}

/// Recently liked shows: shows first 5 in order of liked IDs; loads by ID if not in ShowProvider.
class _RecentLikedShowsSection extends StatefulWidget {
  final List<String> likedShowIds;

  const _RecentLikedShowsSection({required this.likedShowIds});

  @override
  State<_RecentLikedShowsSection> createState() => _RecentLikedShowsSectionState();
}

class _RecentLikedShowsSectionState extends State<_RecentLikedShowsSection> {
  static const int _maxDisplay = 5;
  final Map<String, TvShow> _loadedById = {};
  final Set<String> _loadingIds = {};
  final TMDBService _tmdbService = TMDBService();

  void _loadShowIfNeeded(String id, List<TvShow> fromProvider) {
    if (_loadedById.containsKey(id) || _loadingIds.contains(id)) return;
    if (fromProvider.any((s) => s.id.toString() == id)) return;
    final showId = int.tryParse(id);
    if (showId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadedById.containsKey(id) || _loadingIds.contains(id)) return;
      setState(() => _loadingIds.add(id));
      _tmdbService.getShowDetails(showId).then((show) {
        if (!mounted) return;
        setState(() {
          _loadedById[id] = show;
          _loadingIds.remove(id);
        });
      }).catchError((_) {
        if (mounted) setState(() => _loadingIds.remove(id));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetIds = widget.likedShowIds.take(_maxDisplay).toList();
    if (targetIds.isEmpty) return const SizedBox.shrink();

    return Consumer<ShowProvider>(
      builder: (context, showProvider, _) {
        final fromProvider = showProvider.shows;
        for (final id in targetIds) {
          _loadShowIfNeeded(id, fromProvider);
        }

        final List<Widget> tiles = [];
        for (final id in targetIds) {
          TvShow? show = _loadedById[id];
          if (show == null) {
            final found = fromProvider.where((s) => s.id.toString() == id);
            if (found.isNotEmpty) show = found.first;
          }
          if (show != null) {
            tiles.add(_LikedShowTile(
              show: show,
              onTap: () {
                Navigator.of(context).push(
                  NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show!)),
                );
              },
            ));
          } else {
            tiles.add(const PosterListTileSkeleton());
          }
        }
        return Column(children: tiles);
      },
    );
  }
}

/// Statistics card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                fontSize: 28,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Liked movie tile widget
class _LikedMovieTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const _LikedMovieTile({required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 60,
            child: movie.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
          ),
        ),
        title: Text(
          movie.title,
          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          movie.year ?? '',
          style: GoogleFonts.lato(fontSize: 13, color: onSurface.withValues(alpha: 0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.sepiaBrown, size: 18),
            const SizedBox(width: 4),
            Text(
              movie.formattedRating,
              style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liked show tile widget
class _LikedShowTile extends StatelessWidget {
  final TvShow show;
  final VoidCallback? onTap;

  const _LikedShowTile({required this.show, this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 60,
            child: show.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: show.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.tv_rounded, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.tv_rounded, color: Colors.grey),
                  ),
          ),
        ),
        title: Text(
          show.name,
          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          show.year ?? '',
          style: GoogleFonts.lato(fontSize: 13, color: onSurface.withValues(alpha: 0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.sepiaBrown, size: 18),
            const SizedBox(width: 4),
            Text(
              show.formattedRating,
              style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
} 