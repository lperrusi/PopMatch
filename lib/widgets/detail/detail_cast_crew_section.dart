import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/movie.dart' show CastMember, CrewMember;
import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';

/// Shared "Cast & Crew" section for the movie and show detail screens.
///
/// The caller passes the already-resolved [crew] (directors for movies,
/// creators/EPs for shows) and [cast]; crew is listed first, then the top
/// actors, in a horizontal scroll of [DetailCastCrewCard]s.
class DetailCastCrewSection extends StatelessWidget {
  final List<CrewMember> crew;
  final List<CastMember> cast;

  const DetailCastCrewSection({
    super.key,
    required this.crew,
    required this.cast,
  });

  @override
  Widget build(BuildContext context) {
    final topActors = cast.take(10).toList();

    final List<Widget> cards = [
      for (final member in crew)
        DetailCastCrewCard(
          profileUrl: member.profileUrl,
          name: member.name,
          info: member.job,
          isCrew: true,
        ),
      for (final actor in topActors)
        DetailCastCrewCard(
          profileUrl: actor.profileUrl,
          name: actor.name,
          info: actor.character != null ? 'as ${actor.character!}' : null,
          isCrew: false,
        ),
    ];

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.castCrewLabel,
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: AppTheme.filmStripBlack,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200, // Fixed height for horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }
}

/// Individual cast/crew card with a profile image and a gradient text overlay.
/// [isCrew] renders the info line upright (job title); actors get italic
/// ("as Character").
class DetailCastCrewCard extends StatelessWidget {
  final String? profileUrl;
  final String name;
  final String? info;
  final bool isCrew;

  const DetailCastCrewCard({
    super.key,
    required this.profileUrl,
    required this.name,
    this.info,
    required this.isCrew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            profileUrl != null
                ? CachedNetworkImage(
                    imageUrl: profileUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brickRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.filmStripBlack.withValues(alpha: 50),
                        size: 48,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.filmStripBlack.withValues(alpha: 20),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.filmStripBlack.withValues(alpha: 50),
                      size: 48,
                    ),
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.filmStripBlack.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.lato(
                        color: AppTheme.warmCream,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        info!,
                        style: GoogleFonts.lato(
                          color: AppTheme.warmCream.withValues(alpha: 85),
                          fontSize: 11,
                          fontStyle:
                              isCrew ? FontStyle.normal : FontStyle.italic,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
