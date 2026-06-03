import '../l10n/app_localizations.dart';
import 'recommendation_reason.dart';

/// Maps a [RecommendationReason] to its localized "why" label, shared by the
/// swipe cards and the detail screens. Returns null when the reason is `none`
/// (caller hides the badge/line). Kept out of the pure [buildRecommendationReason]
/// so that helper stays dependency-free and unit-testable.
String? recommendationReasonLabel(AppLocalizations l10n, RecommendationReason r) {
  switch (r.kind) {
    case RecommendationReasonKind.becauseYouLikeActor:
    case RecommendationReasonKind.becauseYouLikeDirector:
      return l10n.reasonBecauseYouLike(r.personName ?? '');
    case RecommendationReasonKind.becauseYouLikeGenre:
      return l10n.reasonBecauseYouLike(r.genreName ?? '');
    case RecommendationReasonKind.similarToLiked:
      return l10n.strategyLikedSimilar;
    case RecommendationReasonKind.genreMatch:
      return l10n.strategyGenreMatch;
    case RecommendationReasonKind.trending:
      return l10n.strategyTrending;
    case RecommendationReasonKind.topRated:
      return l10n.strategyTopRated;
    case RecommendationReasonKind.personalized:
      return l10n.strategyPersonalized;
    case RecommendationReasonKind.curated:
      return l10n.strategyCurated;
    case RecommendationReasonKind.actorDiscovery:
      return l10n.strategyActorDiscovery;
    case RecommendationReasonKind.directorDiscovery:
      return l10n.strategyDirectorDiscovery;
    case RecommendationReasonKind.none:
      return null;
  }
}
