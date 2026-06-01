import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';

/// View-model for one card in a [DetailSimilarSection].
class DetailSimilarItem {
  final String? posterUrl;
  final String title;
  final String? year;
  final String? rating;
  final VoidCallback onTap;

  const DetailSimilarItem({
    required this.posterUrl,
    required this.title,
    this.year,
    this.rating,
    required this.onTap,
  });
}

/// Shared "… Like This" related-titles section for the movie and show detail
/// screens. The caller supplies [loadItems] (its own fetch/rank logic mapped to
/// [DetailSimilarItem]s); this widget owns the section chrome and load/error/
/// empty/list states.
class DetailSimilarSection extends StatefulWidget {
  final String title;
  final String errorLabel;
  final String emptyLabel;
  final Future<List<DetailSimilarItem>> Function() loadItems;

  const DetailSimilarSection({
    super.key,
    required this.title,
    required this.errorLabel,
    required this.emptyLabel,
    required this.loadItems,
  });

  @override
  State<DetailSimilarSection> createState() => _DetailSimilarSectionState();
}

class _DetailSimilarSectionState extends State<DetailSimilarSection> {
  List<DetailSimilarItem> _items = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final items = await widget.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Prefer the empty/quiet state over a hard error for transient issues.
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            // Reserve the row's height with a shimmer so titles fill in after
            // reveal without shifting the layout.
            SizedBox(
              height: 220,
              child: Shimmer.fromColors(
                baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
                highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.filmStripBlack
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.filmStripBlack.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (_hasError)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppTheme.brickRed, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    widget.errorLabel,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 70),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brickRed,
                      foregroundColor: AppTheme.warmCream,
                    ),
                    child: Text(context.l10n.retryButton),
                  ),
                ],
              ),
            )
          else if (_items.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.movie_outlined,
                      color: AppTheme.filmStripBlack.withValues(alpha: 30),
                      size: 48),
                  const SizedBox(height: 12),
                  Text(
                    widget.emptyLabel,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 60),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _items.length,
                itemBuilder: (context, index) =>
                    DetailSimilarCard(item: _items[index]),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single poster card in a [DetailSimilarSection].
class DetailSimilarCard extends StatelessWidget {
  final DetailSimilarItem item;

  const DetailSimilarCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppTheme.vintagePaper),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.vintagePaper,
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppTheme.filmStripBlack.withValues(alpha: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.year != null) ...[
                  Text(
                    item.year!,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 60),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (item.rating != null) ...[
                  Icon(Icons.star_rounded, color: AppTheme.brickRed, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    item.rating!,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 80),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
