import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/streaming_platform.dart' show MovieStreamingAvailability;
import '../../providers/streaming_provider.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/streaming_url_launcher.dart';
import '../../utils/theme.dart';

/// Shared inline "Where to watch" row for the movie and show detail headers.
///
/// Loads availability via [StreamingProvider] ([isShow] picks the TV vs movie
/// lookup) and renders tappable platform chips. Renders nothing while loading,
/// on error, or when no platforms are available.
class DetailInlineStreamingAvailability extends StatefulWidget {
  final int itemId;
  final String title;
  final bool isShow;
  final Color textColor;

  const DetailInlineStreamingAvailability({
    super.key,
    required this.itemId,
    required this.title,
    required this.isShow,
    this.textColor = AppTheme.warmCream,
  });

  @override
  State<DetailInlineStreamingAvailability> createState() =>
      _DetailInlineStreamingAvailabilityState();
}

class _DetailInlineStreamingAvailabilityState
    extends State<DetailInlineStreamingAvailability> {
  MovieStreamingAvailability? _availability;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreamingAvailability();
  }

  Future<void> _loadStreamingAvailability() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final streamingProvider =
          Provider.of<StreamingProvider>(context, listen: false);
      final availability = widget.isShow
          ? await streamingProvider.getStreamingAvailabilityForTv(widget.itemId)
          : await streamingProvider.getStreamingAvailability(widget.itemId);

      if (mounted) {
        setState(() {
          _availability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_error != null ||
        _availability == null ||
        _availability!.availablePlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final platforms = _availability!.platforms.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tv_rounded,
              color: widget.textColor.withValues(alpha: 80),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.whereToWatchLabel,
              style: GoogleFonts.lato(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              final platform = platforms[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => launchStreamingSearch(
                    context: context,
                    platform: platform,
                    title: widget.title,
                  ),
                  child: Tooltip(
                    message: 'Open on ${platform.name}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.sepiaBrown,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          platform.name,
                          style: GoogleFonts.lato(
                            color: widget.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
