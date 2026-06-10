import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/home/home_screen.dart' show updateHomeScreenTab;

/// Builds the share message for a movie or show detail screen. Pure (testable);
/// [isShow] switches the emoji, the date label, the trailing noun, and whether
/// the seasons/episodes lines are included.
String buildShareText({
  required bool isShow,
  required String title,
  String? overview,
  required String rating,
  String? year,
  List<String>? genres,
  int? seasons,
  int? episodes,
}) {
  final noun = isShow ? 'show' : 'movie';
  final lines = <String>[
    '${isShow ? '📺' : '🎬'} $title',
    '',
    overview?.isNotEmpty == true ? overview! : 'No description available',
    '',
    '⭐ Rating: $rating',
    '📅 ${isShow ? 'First Aired' : 'Year'}: ${year ?? 'Unknown'}',
    if (isShow && seasons != null) '📚 Seasons: $seasons',
    if (isShow && episodes != null) '🎬 Episodes: $episodes',
    '🎭 Genres: ${genres?.join(', ') ?? 'Unknown'}',
    '',
    'Check out this $noun on PopMatch!',
  ];
  return lines.join('\n');
}

/// Shares a movie/show via the platform share sheet, using [buildShareText].
void shareTitleDetails({
  required bool isShow,
  required String title,
  String? overview,
  required String rating,
  String? year,
  List<String>? genres,
  int? seasons,
  int? episodes,
}) {
  final text = buildShareText(
    isShow: isShow,
    title: title,
    overview: overview,
    rating: rating,
    year: year,
    genres: genres,
    seasons: seasons,
    episodes: episodes,
  );
  Share.share(
    text,
    subject: 'Check out this ${isShow ? 'show' : 'movie'}: $title',
  );
}

/// Shared bottom-nav handling for the detail screens: cancel in-flight work via
/// [onCancel], pop, then switch the Home tab after navigation starts.
void handleDetailNavTap(
  BuildContext context,
  int index, {
  required VoidCallback onCancel,
}) {
  onCancel();
  Navigator.of(context).pop();
  Future.microtask(() => updateHomeScreenTab(index));
}
