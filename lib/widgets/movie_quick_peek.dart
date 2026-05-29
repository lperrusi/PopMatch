import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

/// Quick-peek bottom sheet shown when the user taps the info icon on a swipe card.
/// Displays synopsis, top cast, ratings, and quick actions without leaving the deck.
///
/// Use [MovieQuickPeek.forMovie] or [MovieQuickPeek.forShow] factory constructors.
class MovieQuickPeek extends StatefulWidget {
  final Movie? movie;
  final TvShow? show;
  final VoidCallback onOpenDetails;

  const MovieQuickPeek._({
    super.key,
    this.movie,
    this.show,
    required this.onOpenDetails,
  }) : assert(movie != null || show != null);

  factory MovieQuickPeek.forMovie({
    Key? key,
    required Movie movie,
    required VoidCallback onOpenDetails,
  }) =>
      MovieQuickPeek._(key: key, movie: movie, onOpenDetails: onOpenDetails);

  factory MovieQuickPeek.forShow({
    Key? key,
    required TvShow show,
    required VoidCallback onOpenDetails,
  }) =>
      MovieQuickPeek._(key: key, show: show, onOpenDetails: onOpenDetails);

  @override
  State<MovieQuickPeek> createState() => _MovieQuickPeekState();
}

class _MovieQuickPeekState extends State<MovieQuickPeek> {
  bool _watchlistAdded = false;
  bool _overviewExpanded = false;

  // Unified accessors
  String get _title => widget.movie?.title ?? widget.show!.name;
  String? get _posterUrl => widget.movie?.posterUrl ?? widget.show?.posterUrl;
  String? get _overview => widget.movie?.overview ?? widget.show?.overview;
  String? get _year => widget.movie?.year ?? widget.show?.year;
  double? get _voteAverage =>
      widget.movie?.voteAverage ?? widget.show?.voteAverage;
  String get _formattedRating =>
      widget.movie?.formattedRating ?? widget.show?.formattedRating ?? '';
  List<String>? get _genres => widget.movie?.genres ?? widget.show?.genres;
  List<dynamic>? get _cast => widget.movie?.cast ?? widget.show?.cast;
  double? get _imdbRating =>
      widget.movie?.imdbRating ?? widget.show?.imdbRating;
  int? get _rtScore => widget.movie?.rottenTomatoesTomatometer ??
      widget.show?.rottenTomatoesTomatometer;

  String? get _runtimeOrSeasons {
    if (widget.movie != null) {
      final rt = widget.movie!.runtime;
      if (rt == null || rt <= 0) return null;
      final h = rt ~/ 60;
      final m = rt % 60;
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } else {
      final s = widget.show!.numberOfSeasons;
      if (s == null) return null;
      return s == 1 ? '1 Season' : '$s Seasons';
    }
  }

  bool get _isInWatchlist {
    final auth = context.read<AuthProvider>();
    if (widget.movie != null) {
      return auth.isInWatchlist(widget.movie!.id.toString());
    } else {
      return auth.isInWatchlistShow(widget.show!.id.toString());
    }
  }

  Future<void> _toggleWatchlist() async {
    final auth = context.read<AuthProvider>();
    if (widget.movie != null) {
      await auth.addToWatchlist(widget.movie!.id.toString());
    } else {
      await auth.addShowToWatchlist(widget.show!.id.toString());
    }
    if (mounted) setState(() => _watchlistAdded = true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.filmStripBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.warmCream.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: poster + title block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster thumbnail
                          if (_posterUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _posterUrl!,
                                width: 60,
                                height: 90,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 60,
                                  height: 90,
                                  color: AppTheme.deepMidnightBrown,
                                  child: const Icon(Icons.movie_outlined,
                                      color: AppTheme.warmCream, size: 24),
                                ),
                              ),
                            ),
                          const SizedBox(width: 14),
                          // Title + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title,
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 26,
                                    color: AppTheme.warmCream,
                                    letterSpacing: 1.2,
                                    height: 1.1,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Meta row: year · runtime/seasons · rating
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (_year != null)
                                      _metaChip(_year!),
                                    if (_runtimeOrSeasons != null)
                                      _metaChip(_runtimeOrSeasons!),
                                    if (_voteAverage != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: AppTheme.brickRed,
                                              size: 14),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formattedRating,
                                            style: GoogleFonts.lato(
                                              color: AppTheme.warmCream,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                // IMDb + RT
                                if (_imdbRating != null ||
                                    _rtScore != null) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 10,
                                    children: [
                                      if (_imdbRating != null)
                                        Text(
                                          'IMDb ${_imdbRating!.toStringAsFixed(1)}',
                                          style: GoogleFonts.lato(
                                            color: AppTheme.popcornGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (_rtScore != null)
                                        Text(
                                          '🍅 $_rtScore%',
                                          style: GoogleFonts.lato(
                                            color: AppTheme.warmCream,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Genres
                      if (_genres != null && _genres!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _genres!.take(4).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brickRed.withValues(alpha: 20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      AppTheme.brickRed.withValues(alpha: 50),
                                ),
                              ),
                              child: Text(
                                genre,
                                style: GoogleFonts.lato(
                                  color: AppTheme.warmCream,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Synopsis
                      if (_overview != null && _overview!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Synopsis',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            color: AppTheme.popcornGold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setState(
                              () => _overviewExpanded = !_overviewExpanded),
                          child: Text(
                            _overview!,
                            maxLines: _overviewExpanded ? null : 4,
                            overflow: _overviewExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: AppTheme.warmCream.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (!_overviewExpanded && _overview!.length > 200)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Read more',
                              style: GoogleFonts.lato(
                                color: AppTheme.popcornGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],

                      // Top cast
                      if (_cast != null && _cast!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Cast',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            color: AppTheme.popcornGold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (_cast!.length > 6 ? 6 : _cast!.length),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final member = _cast![i];
                              final profileUrl = member.profileUrl as String?;
                              final name = member.name as String;
                              return Column(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppTheme.deepMidnightBrown,
                                    backgroundImage: profileUrl != null
                                        ? CachedNetworkImageProvider(profileUrl)
                                        : null,
                                    child: profileUrl == null
                                        ? const Icon(Icons.person,
                                            color: AppTheme.warmCream, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      name.split(' ').first,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.lato(
                                        color: AppTheme.warmCream
                                            .withValues(alpha: 0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],

                      // Action buttons
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Watchlist button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _watchlistAdded || _isInWatchlist
                                  ? null
                                  : _toggleWatchlist,
                              icon: Icon(
                                _watchlistAdded || _isInWatchlist
                                    ? Icons.bookmark_added
                                    : Icons.bookmark_add_outlined,
                                size: 18,
                              ),
                              label: Text(
                                _watchlistAdded || _isInWatchlist
                                    ? 'In Watchlist'
                                    : 'Add to Watchlist',
                                style: GoogleFonts.lato(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.popcornGold,
                                side: BorderSide(
                                  color: AppTheme.popcornGold
                                      .withValues(alpha: 0.6),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Full details button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onOpenDetails();
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: Text(
                                'Full Details',
                                style: GoogleFonts.lato(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cinemaRed,
                                foregroundColor: AppTheme.warmCream,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.sepiaBrown.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          color: AppTheme.warmCream.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
