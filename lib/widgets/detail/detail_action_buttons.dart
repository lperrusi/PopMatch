import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';
import '../add_to_list_sheet.dart';
import 'watchlist_icon.dart';

/// The Watchlist / Like / Dislike / (Add-to-list) / Share action row shared by
/// the movie and show detail screens. [isShow] switches between the movie- and
/// show-variant [AuthProvider] calls and the provider whose feed is refreshed;
/// the add-to-list button is movie-only (custom lists are movie-based).
/// Behaviour mirrors the previous inline rows exactly.
class DetailActionButtons extends StatelessWidget {
  /// TMDB id as a string.
  final String itemId;

  /// Title/name used in the action snackbars.
  final String title;

  final bool isShow;
  final Color textColor;
  final VoidCallback onShare;

  const DetailActionButtons({
    super.key,
    required this.itemId,
    required this.title,
    required this.isShow,
    required this.textColor,
    required this.onShare,
  });

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.fadedCurtain,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Keep the swipe feed in sync with detail actions.
  void _refreshFeed(BuildContext context, AuthProvider auth) {
    if (isShow) {
      Provider.of<ShowProvider>(context, listen: false)
          .refreshFilters(auth.userData);
    } else {
      Provider.of<MovieProvider>(context, listen: false)
          .refreshFilters(auth.userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Watchlist button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isInWatchlist = isShow
                ? authProvider.isInWatchlistShow(itemId)
                : authProvider.isInWatchlist(itemId);
            return IconButton(
              // Flush-left so the first icon aligns with the header's content
              // edge (title / meta / "Where to watch") instead of the default
              // ~8px IconButton inset.
              padding: const EdgeInsets.only(right: 8),
              icon: WatchlistIcon(
                size: 28,
                added: isInWatchlist,
                inactiveColor: textColor,
              ),
              onPressed: () async {
                if (isInWatchlist) {
                  if (isShow) {
                    await authProvider.removeFromWatchlistShow(itemId);
                  } else {
                    await authProvider.removeFromWatchlist(itemId);
                  }
                  if (!context.mounted) return;
                  _snack(context, context.l10n.snackbarRemovedFromWatchlist(title));
                } else {
                  if (isShow) {
                    await authProvider.addShowToWatchlist(itemId);
                  } else {
                    await authProvider.addToWatchlist(itemId);
                  }
                  if (!context.mounted) return;
                  _snack(context, context.l10n.snackbarAddedToWatchlist(title));
                }
                if (!context.mounted) return;
                _refreshFeed(context, authProvider);
              },
            );
          },
        ),
        // Like button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isLiked = isShow
                ? authProvider.isLikedShow(itemId)
                : authProvider.isLikedMovie(itemId);
            return IconButton(
              icon: Icon(
                isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                color: isLiked ? AppTheme.vintagePaper : textColor,
                size: 24,
              ),
              onPressed: () async {
                if (authProvider.userData == null) return;
                if (isLiked) {
                  if (isShow) {
                    await authProvider.removeLikedShow(itemId);
                  } else {
                    await authProvider.removeLikedMovie(itemId);
                  }
                  if (context.mounted) {
                    _snack(context, context.l10n.removedFromFavoritesSnackbar(title));
                  }
                } else {
                  if (isShow) {
                    await authProvider.removeDislikedShow(itemId);
                    await authProvider.addLikedShow(itemId);
                  } else {
                    await authProvider.removeDislikedMovie(itemId);
                    await authProvider.addLikedMovie(itemId);
                  }
                  if (context.mounted) {
                    _snack(context, context.l10n.addedToFavoritesSnackbar(title));
                  }
                }
                if (!context.mounted) return;
                _refreshFeed(context, authProvider);
              },
            );
          },
        ),
        // Dislike button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isDisliked = isShow
                ? authProvider.isDislikedShow(itemId)
                : authProvider.isDislikedMovie(itemId);
            return IconButton(
              icon: Icon(
                isDisliked
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                color: isDisliked
                    ? AppTheme.vintagePaper
                    : textColor.withValues(alpha: 0.8),
                size: 24,
              ),
              onPressed: () async {
                if (authProvider.userData == null) return;
                if (isDisliked) {
                  if (isShow) {
                    await authProvider.removeDislikedShow(itemId);
                  } else {
                    await authProvider.removeDislikedMovie(itemId);
                  }
                  if (context.mounted) {
                    _snack(context, context.l10n.removedFromDislikedSnackbar(title));
                  }
                } else {
                  if (isShow) {
                    await authProvider.removeLikedShow(itemId);
                    await authProvider.addDislikedShow(itemId);
                  } else {
                    await authProvider.removeLikedMovie(itemId);
                    await authProvider.addDislikedMovie(itemId);
                  }
                  if (context.mounted) {
                    _snack(context, context.l10n.addedToDislikedSnackbar(title));
                  }
                }
                if (!context.mounted) return;
                _refreshFeed(context, authProvider);
              },
            );
          },
        ),
        // Add to custom list / tag — movie-only (custom lists are movie-based).
        if (!isShow)
          IconButton(
            icon: Icon(Icons.playlist_add_rounded, color: textColor, size: 24),
            tooltip: context.l10n.addToListTitle,
            onPressed: () => showAddToListSheet(
              context,
              movieId: itemId,
              title: title,
            ),
          ),
        // Share button
        IconButton(
          icon: Icon(Icons.share_rounded, color: textColor, size: 24),
          onPressed: onShare,
        ),
      ],
    );
  }
}
