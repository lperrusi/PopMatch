import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/streaming_platform.dart';
import '../services/streaming_service.dart';
import '../services/watchmode_service.dart';

/// Opens [platform] on the exact [title] (TMDB [tmdbId]).
///
/// Tries a Watchmode **direct-to-title deep link** first — opens the title
/// inside the platform app (or its web title page). If Watchmode has no key /
/// no link for this title+platform, falls back to [launchStreamingSearch] (the
/// in-app title search), so behaviour never regresses.
Future<void> launchStreamingTitle({
  required BuildContext context,
  required StreamingPlatform platform,
  required String title,
  required int tmdbId,
  required bool isMovie,
}) async {
  final deepLink = await WatchmodeService.instance.getDeepLink(
    tmdbId: tmdbId,
    isMovie: isMovie,
    platformId: platform.id,
    region: StreamingService.instance.userCountry,
    preferIos: Platform.isIOS,
  );

  if (deepLink != null) {
    final launched = await launchUrl(
      Uri.parse(deepLink),
      mode: LaunchMode.externalApplication,
    );
    if (launched) return;
  }

  if (!context.mounted) return;
  await launchStreamingSearch(
    context: context,
    platform: platform,
    title: title,
  );
}

/// Opens the given [platform]'s app (or website) searching for [title].
///
/// Most major streaming platforms support universal links (iOS) / App Links
/// (Android): the HTTPS search URL opens inside the platform app when installed,
/// and falls back to the browser automatically. If even the browser launch
/// fails, a SnackBar is shown.
Future<void> launchStreamingSearch({
  required BuildContext context,
  required StreamingPlatform platform,
  required String title,
}) async {
  final searchUrl = platform.searchUrlFor(title);
  final uri = Uri.parse(searchUrl);

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    // Final fallback: open the platform's homepage.
    final fallbackUrl = platform.websiteUrl;
    if (fallbackUrl != null) {
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't open ${platform.name}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
