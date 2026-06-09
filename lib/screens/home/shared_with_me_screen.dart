import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/shared_watchlist.dart';
import '../../models/watchlist_list.dart';
import '../../providers/social_provider.dart';
import '../../services/tmdb_service.dart';
import '../../services/watchlist_service.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';
import '../../widgets/poster_list_skeleton.dart';

/// "Shared with you" — custom lists friends sent the current user. Each is a
/// point-in-time snapshot; the user can save a copy into their own local lists.
class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  // Posters resolved per list for the preview row.
  static const int _previewPerList = 8;

  bool _loading = true;
  bool _error = false;
  List<SharedWatchlist> _lists = const [];
  // Resolved posters keyed by `movie:603` / `show:1399`.
  final Map<String, String> _posterUrls = {};
  final Set<String> _saving = {};

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
      await social.loadSharedWithMe();
      if (!mounted) return;
      final lists = social.sharedWithMe;
      await _resolvePreviewPosters(lists);
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SharedWithMeScreen load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _resolvePreviewPosters(List<SharedWatchlist> lists) async {
    final tmdb = TMDBService();
    for (final list in lists) {
      var resolved = 0;
      for (final id in list.movieIds) {
        if (resolved >= _previewPerList) break;
        final key = 'movie:$id';
        if (_posterUrls.containsKey(key)) {
          resolved++;
          continue;
        }
        try {
          final m = await tmdb.getMovieDetails(int.parse(id));
          if (m.posterUrl != null) _posterUrls[key] = m.posterUrl!;
          resolved++;
        } catch (_) {/* skip */}
      }
      for (final id in list.showIds) {
        if (resolved >= _previewPerList) break;
        final key = 'show:$id';
        if (_posterUrls.containsKey(key)) {
          resolved++;
          continue;
        }
        try {
          final s = await tmdb.getShowDetails(int.parse(id));
          if (s.posterUrl != null) _posterUrls[key] = s.posterUrl!;
          resolved++;
        } catch (_) {/* skip */}
      }
    }
  }

  Future<void> _saveToMyLists(SharedWatchlist shared) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving.add(shared.id));
    try {
      final ws = WatchlistService.instance;
      final created = await ws.createList(
        name: shared.name,
        description: shared.description,
        color: shared.color,
      );
      if (created == null) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.sharedListExistsSnackbar),
          backgroundColor: AppTheme.cinemaRed,
        ));
        return;
      }
      await ws.updateList(WatchlistList(
        id: created.id,
        name: created.name,
        description: created.description,
        color: created.color,
        movieIds: shared.movieIds,
        showIds: shared.showIds,
        createdAt: created.createdAt,
        updatedAt: DateTime.now(),
      ));
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.savedToMyListsSnackbar),
        backgroundColor: AppTheme.popcornGold,
      ));
    } catch (e) {
      debugPrint('saveToMyLists failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.sharedListSaveFailedSnackbar),
        backgroundColor: AppTheme.cinemaRed,
      ));
    } finally {
      if (mounted) setState(() => _saving.remove(shared.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.sharedWithYouPageTitle,
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
              : _lists.isEmpty
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
              l10n.sharedWithYouErrorBody,
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
            const Icon(Icons.folder_shared_outlined,
                size: 64, color: AppTheme.cinemaRed),
            const SizedBox(height: 16),
            Text(
              l10n.sharedWithYouEmptyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sharedWithYouEmptyBody,
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
        padding: const EdgeInsets.all(12),
        itemCount: _lists.length,
        itemBuilder: (context, index) => _buildListCard(_lists[index]),
      ),
    );
  }

  Widget _buildListCard(SharedWatchlist list) {
    final l10n = context.l10n;
    final owner = (list.ownerName?.isNotEmpty ?? false)
        ? list.ownerName!
        : l10n.sharedByFallbackName;
    final keys = [
      ...list.movieIds.map((id) => 'movie:$id'),
      ...list.showIds.map((id) => 'show:$id'),
    ].where(_posterUrls.containsKey).take(_previewPerList).toList();
    final isSaving = _saving.contains(list.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              list.name,
              style: GoogleFonts.bebasNeue(
                fontSize: 22,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${l10n.sharedByLabel(owner)} · ${l10n.sharedListItemsCount(list.itemCount)}',
              style: GoogleFonts.lato(
                color: AppTheme.sepiaBrown,
                fontSize: 13,
              ),
            ),
            if (list.description != null && list.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                list.description!,
                style: GoogleFonts.lato(
                    color: AppTheme.filmStripBlack, fontSize: 13),
              ),
            ],
            if (keys.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: keys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _posterUrls[keys[i]]!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 80,
                          color:
                              AppTheme.filmStripBlack.withValues(alpha: 0.1)),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                        child: const Icon(Icons.movie_rounded,
                            color: AppTheme.sepiaBrown),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : () => _saveToMyLists(list),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined, size: 18),
                label: Text(l10n.saveToMyListsButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cinemaRed,
                  foregroundColor: AppTheme.warmCream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
