import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/video.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';
import '../video_player_widget.dart';

/// Shared "Trailers & Videos" section for the movie and show detail screens.
///
/// Uses [initialVideos] when the model already carries them (cached data, no
/// network), otherwise calls [fetchVideos] after the first frame. Renders
/// nothing while loading or when there are no videos.
class DetailVideosSection extends StatefulWidget {
  final List<Video>? initialVideos;
  final Future<List<Video>> Function() fetchVideos;

  const DetailVideosSection({
    super.key,
    required this.initialVideos,
    required this.fetchVideos,
  });

  @override
  State<DetailVideosSection> createState() => _DetailVideosSectionState();
}

class _DetailVideosSectionState extends State<DetailVideosSection> {
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVideos;
    if (initial != null && initial.isNotEmpty) {
      _videos = initial;
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadVideos();
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final videos = await widget.fetchVideos();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.trailersVideosLabel,
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return RetroVideoCard(video: _videos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single trailer/video card in the retro-cinema framed style.
class RetroVideoCard extends StatelessWidget {
  final Video video;

  const RetroVideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cinemaRed,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(video: video),
      ),
    );
  }
}
