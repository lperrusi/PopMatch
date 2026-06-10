import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/movie.dart';
import '../../models/social_activity.dart';
import '../../models/tv_show.dart';
import '../../providers/social_provider.dart';
import '../../services/tmdb_service.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/theme.dart';
import '../../widgets/poster_list_skeleton.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

/// Recency buckets for the activity timeline.
enum ActivityBucket { today, thisWeek, earlier }

/// A friend activity grouped under a [ActivityBucket].
class ActivityGroup {
  final ActivityBucket bucket;
  final List<SocialActivity> activities;
  const ActivityGroup(this.bucket, this.activities);
}

/// Groups [activities] into Today / This week / Earlier, newest-first within each
/// bucket, dropping empty buckets. Pure (testable) — pass [now] in tests.
List<ActivityGroup> groupActivitiesByRecency(
  List<SocialActivity> activities, {
  required DateTime now,
}) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfToday.subtract(const Duration(days: 7));

  final today = <SocialActivity>[];
  final week = <SocialActivity>[];
  final earlier = <SocialActivity>[];

  final sorted = [...activities]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final a in sorted) {
    if (!a.createdAt.isBefore(startOfToday)) {
      today.add(a);
    } else if (!a.createdAt.isBefore(startOfWeek)) {
      week.add(a);
    } else {
      earlier.add(a);
    }
  }

  return [
    if (today.isNotEmpty) ActivityGroup(ActivityBucket.today, today),
    if (week.isNotEmpty) ActivityGroup(ActivityBucket.thisWeek, week),
    if (earlier.isNotEmpty) ActivityGroup(ActivityBucket.earlier, earlier),
  ];
}

/// "Friends activity" — a chronological timeline of what people you follow have
/// liked / added to their watchlist, grouped by recency. Tapping a row opens the
/// movie/show detail. Reads [SocialProvider.friendsFeed]; posters from TMDB.
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  static const int _maxResolved = 60;

  bool _loading = true;
  bool _error = false;
  List<ActivityGroup> _groups = const [];
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
    try {
      final social = context.read<SocialProvider>();
      await social.loadFriendsFeed();
      if (!mounted) return;
      final feed = social.friendsFeed;
      await social.resolveNames(feed.map((a) => a.actorUid).toList());
      if (!mounted) return;
      await _resolvePosters(feed);
      if (!mounted) return;
      setState(() {
        _groups = groupActivitiesByRecency(feed, now: DateTime.now());
        _loading = false;
      });
    } catch (e) {
      debugPrint('ActivityFeedScreen load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _resolvePosters(List<SocialActivity> feed) async {
    final tmdb = TMDBService();
    final seen = <String>{};
    var resolved = 0;
    for (final a in feed) {
      if (resolved >= _maxResolved) break;
      final key = '${a.itemType.name}:${a.itemId}';
      if (!seen.add(key)) continue;
      if (_movies.containsKey(key) || _shows.containsKey(key)) continue;
      try {
        final id = int.parse(a.itemId);
        if (a.itemType == SocialItemType.movie) {
          _movies[key] = await tmdb.getMovieDetails(id);
        } else {
          _shows[key] = await tmdb.getShowDetails(id);
        }
        resolved++;
      } catch (e) {
        debugPrint('ActivityFeed: failed to resolve $key: $e');
      }
    }
  }

  String _bucketLabel(ActivityBucket b) {
    final l10n = context.l10n;
    switch (b) {
      case ActivityBucket.today:
        return l10n.activityBucketToday;
      case ActivityBucket.thisWeek:
        return l10n.activityBucketThisWeek;
      case ActivityBucket.earlier:
        return l10n.activityBucketEarlier;
    }
  }

  String _actionPhrase(SocialActivity a, String name) {
    final l10n = context.l10n;
    switch (a.activityType) {
      case SocialActivityType.watchlisted:
        return l10n.activityWatchlistedBy(name);
      case SocialActivityType.watched:
        return l10n.activityWatchedBy(name);
      case SocialActivityType.liked:
        return l10n.activityLikedBy(name);
    }
  }

  void _open(SocialActivity a) {
    final key = '${a.itemType.name}:${a.itemId}';
    final movie = _movies[key];
    final show = _shows[key];
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
          l10n.activityFeedPageTitle,
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
              : _groups.isEmpty
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
              l10n.activityFeedErrorBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
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
            const Icon(Icons.dynamic_feed_outlined,
                size: 64, color: AppTheme.cinemaRed),
            const SizedBox(height: 16),
            Text(
              l10n.activityFeedEmptyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.activityFeedEmptyBody,
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
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _groups.length,
        itemBuilder: (context, i) => _buildGroup(_groups[i]),
      ),
    );
  }

  Widget _buildGroup(ActivityGroup group) {
    // Only rows whose title/poster resolved are shown.
    final rows = group.activities
        .where((a) =>
            _movies.containsKey('${a.itemType.name}:${a.itemId}') ||
            _shows.containsKey('${a.itemType.name}:${a.itemId}'))
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            _bucketLabel(group.bucket),
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: AppTheme.sepiaBrown,
              letterSpacing: 1,
            ),
          ),
        ),
        ...rows.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(SocialActivity a) {
    final social = context.read<SocialProvider>();
    final key = '${a.itemType.name}:${a.itemId}';
    final movie = _movies[key];
    final show = _shows[key];
    final posterUrl = movie?.posterUrl ?? show?.posterUrl;
    final title = movie?.title ?? show?.name ?? '';
    final name = (a.actorDisplayName?.trim().isNotEmpty ?? false)
        ? a.actorDisplayName!.trim()
        : (social.nameFor(a.actorUid) ?? context.l10n.sharedByFallbackName);

    return InkWell(
      onTap: () => _open(a),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 46,
                height: 69,
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.filmStripBlack
                                .withValues(alpha: 0.1)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                          child: const Icon(Icons.movie_rounded,
                              size: 18, color: AppTheme.sepiaBrown),
                        ),
                      )
                    : Container(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                        child: const Icon(Icons.movie_rounded,
                            size: 18, color: AppTheme.sepiaBrown),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _actionPhrase(a, name),
                    style: GoogleFonts.lato(
                      color: AppTheme.sepiaBrown,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
