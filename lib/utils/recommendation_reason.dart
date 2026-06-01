/// The "why" behind a recommended title, shown as a badge on swipe cards.
///
/// Pure / dependency-free so it can be unit-tested. The widget layer maps the
/// [RecommendationReasonKind] to a localized string (see `_reasonLabel` in the
/// retro cinema cards).
enum RecommendationReasonKind {
  /// Title's genres intersect the user's selected genres — carries [genreName].
  becauseYouLikeGenre,
  similarToLiked,
  genreMatch,
  trending,
  topRated,
  personalized,
  curated,
  actorDiscovery,
  directorDiscovery,

  /// No meaningful reason — the card should hide the badge.
  none,
}

class RecommendationReason {
  final RecommendationReasonKind kind;

  /// Resolved genre name for [RecommendationReasonKind.becauseYouLikeGenre].
  final String? genreName;

  const RecommendationReason(this.kind, {this.genreName});

  static const none = RecommendationReason(RecommendationReasonKind.none);
}

/// Builds the most specific reason available for a recommended title.
///
/// Prefers a concrete "Because you like {Genre}" when the title's genres
/// intersect the user's [userGenreIds] and we can name that genre; otherwise
/// falls back to a generic reason derived from [strategy].
///
/// Matches on [genreIds] (present on TMDB list/discover data) first, then on
/// [genreNames] (present on TMDB *detail* data, which carries no `genre_ids`) —
/// so the specific badge survives a card enriching itself to detail data.
RecommendationReason buildRecommendationReason({
  required String? strategy,
  required List<int>? genreIds,
  required Set<int> userGenreIds,
  required Map<int, String> genres,
  List<String>? genreNames,
}) {
  // Specific (by id): first of the title's genres that the user picked and we
  // can name. Wins when list/discover data is available (pre-enrichment).
  if (genreIds != null && userGenreIds.isNotEmpty) {
    for (final id in genreIds) {
      if (userGenreIds.contains(id)) {
        final name = genres[id];
        if (name != null && name.isNotEmpty) {
          return RecommendationReason(
            RecommendationReasonKind.becauseYouLikeGenre,
            genreName: name,
          );
        }
      }
    }
  }

  // Specific (by name): detail data drops `genre_ids` but keeps genre names, so
  // match the title's genre names against the names of the user's picked ids.
  if (genreNames != null && genreNames.isNotEmpty && userGenreIds.isNotEmpty) {
    final userGenreNames = <String>{
      for (final id in userGenreIds)
        if (genres[id] != null) genres[id]!,
    };
    if (userGenreNames.isNotEmpty) {
      for (final name in genreNames) {
        if (name.isNotEmpty && userGenreNames.contains(name)) {
          return RecommendationReason(
            RecommendationReasonKind.becauseYouLikeGenre,
            genreName: name,
          );
        }
      }
    }
  }

  // Generic fallback by discovery strategy.
  switch (strategy) {
    case 'similar_to_liked':
      return const RecommendationReason(RecommendationReasonKind.similarToLiked);
    case 'genre_match':
      return const RecommendationReason(RecommendationReasonKind.genreMatch);
    case 'trending':
    case 'popular':
      return const RecommendationReason(RecommendationReasonKind.trending);
    case 'top_rated':
      return const RecommendationReason(RecommendationReasonKind.topRated);
    case 'personalized':
    case 'embedding':
    case 'contentBased':
      return const RecommendationReason(RecommendationReasonKind.personalized);
    case 'curated':
      return const RecommendationReason(RecommendationReasonKind.curated);
    case 'actor_discovery':
      return const RecommendationReason(RecommendationReasonKind.actorDiscovery);
    case 'director_discovery':
      return const RecommendationReason(
          RecommendationReasonKind.directorDiscovery);
    default:
      return RecommendationReason.none;
  }
}
