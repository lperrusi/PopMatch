import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/social_activity.dart';
import '../../providers/social_provider.dart';
import '../../services/social_service.dart';
import '../../services/tmdb_service.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/theme.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

/// One resolved item in a user's "recently liked" grid.
class _ProfileItem {
  final String posterUrl;
  final String title;
  final VoidCallback onTap;
  const _ProfileItem(
      {required this.posterUrl, required this.title, required this.onTap});
}

/// Read-only profile of another user: their avatar/name, a follow/unfollow
/// action, and a grid of what they've recently liked. All data is read
/// client-side (firestore.rules permit reading users + socialActivities).
class FriendProfileScreen extends StatefulWidget {
  final String uid;
  final String? displayName;
  final String? photoURL;

  const FriendProfileScreen({
    super.key,
    required this.uid,
    this.displayName,
    this.photoURL,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final SocialService _social = SocialService.instance;

  bool _loading = true;
  String _name = '';
  String _email = '';
  String _photoURL = '';
  String _followStatus = 'notFollowing';
  final List<_ProfileItem> _items = [];

  @override
  void initState() {
    super.initState();
    _name = widget.displayName?.trim() ?? '';
    _photoURL = widget.photoURL ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = await _social.getUserProfile(widget.uid);
    final status = await _social.getFollowStatus(widget.uid);
    final activities = await _social.getUserActivities(widget.uid, limit: 30);
    final items = await _resolveItems(activities);
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        final n = (profile['displayName'] as String?)?.trim() ?? '';
        if (n.isNotEmpty) _name = n;
        _email = (profile['email'] as String?) ?? '';
        final p = (profile['photoURL'] as String?) ?? '';
        if (p.isNotEmpty) _photoURL = p;
      }
      _followStatus = status;
      _items
        ..clear()
        ..addAll(items);
      _loading = false;
    });
  }

  Future<List<_ProfileItem>> _resolveItems(
      List<SocialActivity> activities) async {
    final tmdb = TMDBService();
    final out = <_ProfileItem>[];
    final seen = <String>{};
    for (final a in activities) {
      final key = '${a.itemType.name}:${a.itemId}';
      if (!seen.add(key)) continue;
      try {
        if (a.itemType == SocialItemType.movie) {
          final Movie movie = await tmdb.getMovieDetails(int.parse(a.itemId));
          final poster = movie.posterUrl;
          if (poster == null) continue;
          out.add(_ProfileItem(
            posterUrl: poster,
            title: movie.title,
            onTap: () => Navigator.of(context).push(
              NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
            ),
          ));
        } else {
          final TvShow show = await tmdb.getShowDetails(int.parse(a.itemId));
          final poster = show.posterUrl;
          if (poster == null) continue;
          out.add(_ProfileItem(
            posterUrl: poster,
            title: show.name,
            onTap: () => Navigator.of(context).push(
              NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
            ),
          ));
        }
      } catch (e) {
        debugPrint('FriendProfile: failed to resolve $key: $e');
      }
    }
    return out;
  }

  String get _displayName => _name.isNotEmpty
      ? _name
      : 'User ${widget.uid.length > 6 ? widget.uid.substring(0, 6) : widget.uid}';

  Future<void> _onFollowPressed() async {
    final social = context.read<SocialProvider>();
    if (_followStatus == 'accepted') {
      await social.unfollow(widget.uid);
      if (mounted) setState(() => _followStatus = 'notFollowing');
    } else if (_followStatus == 'notFollowing' || _followStatus == 'declined') {
      await social.sendFollowRequest(widget.uid);
      if (mounted) setState(() => _followStatus = 'pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        backgroundColor: AppTheme.cinemaRed,
        iconTheme: const IconThemeData(color: AppTheme.warmCream),
        title: Text(
          _displayName,
          style: GoogleFonts.bebasNeue(
            fontSize: 26,
            color: AppTheme.warmCream,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Text(
                    'RECENTLY LIKED',
                    style: GoogleFonts.bebasNeue(
                      color: AppTheme.filmStripBlack,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nothing to show yet',
                          style: GoogleFonts.lato(
                            color: AppTheme.filmStripBlack
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.popcornGold.withValues(alpha: 0.2),
          backgroundImage:
              _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
          child: _photoURL.isEmpty
              ? Text(
                  _displayName[0].toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    color: AppTheme.cinemaRed,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_email.isNotEmpty)
                Text(
                  _email,
                  style: GoogleFonts.lato(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              _buildFollowButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    final (label, enabled) = switch (_followStatus) {
      'accepted' => ('Following', true),
      'pending' => ('Requested', false),
      _ => ('Follow', true),
    };
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: enabled ? _onFollowPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: _followStatus == 'accepted'
              ? AppTheme.sepiaBrown
              : AppTheme.cinemaRed,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: item.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.posterUrl,
              fit: BoxFit.cover,
              placeholder: (c, _) => Container(
                color: AppTheme.fadedCurtain.withValues(alpha: 0.3),
              ),
              errorWidget: (c, _, __) => Container(
                color: AppTheme.fadedCurtain.withValues(alpha: 0.3),
                child: const Icon(Icons.movie_outlined,
                    color: AppTheme.sepiaBrown),
              ),
            ),
          ),
        );
      },
    );
  }
}
