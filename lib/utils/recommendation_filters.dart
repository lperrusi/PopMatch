import '../models/movie.dart';

/// Quality + relevance filtering for the premium "For You" surface, where a
/// single bad pick hurts more than a generic one. Pure and testable.

/// A title is "premium quality" when it has enough votes, a solid rating, and a
/// poster to show. Tune [minVotes] / [minRating] to widen or tighten the bar.
bool isQualityPick(Movie m, {int minVotes = 150, double minRating = 6.0}) {
  if (m.posterUrl == null) return false;
  if ((m.voteCount ?? 0) < minVotes) return false;
  if ((m.voteAverage ?? 0) < minRating) return false;
  return true;
}

/// Filters a recommendation list for For You:
/// - drops anything in [excludeIds] (the user's liked + disliked ids),
/// - drops sub-quality titles ([isQualityPick]),
/// - when [requireGenreOverlap] is given, keeps only titles whose [Movie.genreIds]
///   intersect it (used to keep the social "Friends" rail on the user's taste),
/// - de-duplicates by id, preserving order.
List<Movie> filterForYou(
  List<Movie> movies, {
  required Set<int> excludeIds,
  Set<int>? requireGenreOverlap,
  int minVotes = 150,
  double minRating = 6.0,
}) {
  final seen = <int>{};
  final result = <Movie>[];
  for (final m in movies) {
    if (excludeIds.contains(m.id)) continue;
    if (!seen.add(m.id)) continue;
    if (!isQualityPick(m, minVotes: minVotes, minRating: minRating)) continue;
    if (requireGenreOverlap != null && requireGenreOverlap.isNotEmpty) {
      final genres = m.genreIds;
      if (genres == null || genres.toSet().intersection(requireGenreOverlap).isEmpty) {
        continue;
      }
    }
    result.add(m);
  }
  return result;
}

/// The most recently liked movie id (likes are appended, so the last valid
/// entry), or null when there are none. Used to seed the "Because you liked…"
/// rail. Skips blank / non-numeric / non-positive ids. Pure and testable.
int? mostRecentLikedMovieId(List<String> likedMovieIds) {
  for (final raw in likedMovieIds.reversed) {
    final id = int.tryParse(raw.trim());
    if (id != null && id > 0) return id;
  }
  return null;
}

/// Parses a user's liked + disliked movie id lists into a single int set for use
/// as [filterForYou]'s `excludeIds`.
Set<int> likedDislikedIds({
  required List<String> liked,
  required List<String> disliked,
}) {
  final ids = <int>{};
  for (final raw in [...liked, ...disliked]) {
    final id = int.tryParse(raw);
    if (id != null) ids.add(id);
  }
  return ids;
}
