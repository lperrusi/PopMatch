import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/streaming_platform.dart';

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
