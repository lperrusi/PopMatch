import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/user_preferences_session_cache.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/recommendation_reason.dart';
import '../../utils/recommendation_reason_label.dart';
import '../../utils/theme.dart';

/// Subtle "why you're seeing this" line under a detail header (e.g. "Because you
/// like {Actor}"). Shared by the movie and show detail screens — reuses the same
/// reason engine as the swipe-card badge and renders nothing when there's no
/// meaningful reason. The caller passes the title's fields + the relevant
/// provider's [genres] map ([directorNames] is null for shows).
class DetailWhyLine extends StatelessWidget {
  final String? strategy;
  final List<int>? genreIds;
  final List<String>? genreNames;
  final Map<int, String> genres;
  final List<String>? castNames;
  final List<String>? directorNames;
  final Color textColor;

  const DetailWhyLine({
    super.key,
    required this.strategy,
    required this.genreIds,
    required this.genreNames,
    required this.genres,
    required this.castNames,
    required this.textColor,
    this.directorNames,
  });

  @override
  Widget build(BuildContext context) {
    final userGenreIds = <int>{};
    final raw =
        context.read<AuthProvider>().userData?.preferences['selectedGenres'];
    if (raw is List) {
      for (final g in raw) {
        final id = g is int ? g : int.tryParse(g.toString());
        if (id != null) userGenreIds.add(id);
      }
    }
    final prefs = UserPreferencesSessionCache().cachedPreferences;
    final reason = buildRecommendationReason(
      strategy: strategy,
      genreIds: genreIds,
      genreNames: genreNames,
      userGenreIds: userGenreIds,
      genres: genres,
      castNames: castNames,
      directorNames: directorNames,
      userActors: prefs?.preferredActors.toSet() ?? const {},
      userDirectors: prefs?.preferredDirectors.toSet() ?? const {},
    );
    final label = recommendationReasonLabel(context.l10n, reason);
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: AppTheme.popcornGold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.lato(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
