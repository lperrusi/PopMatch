import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';

/// Help & Support screen - FAQ, contact, about
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaqIndex;

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How does swiping work?',
      'a':
          'Swipe right to like a movie or show, left to dislike, up for a match (save to watch later), and down to skip. Your choices help us recommend better content.',
    },
    {
      'q': 'How do I add something to my watchlist?',
      'a':
          'Swipe up on a card to open the match screen, then choose to add to watchlist. You can also open the title and tap the watchlist button on the detail screen.',
    },
    {
      'q': 'Can I change my streaming platforms?',
      'a':
          'Yes. Go to Profile → Edit Preferences and select your streaming services. We use this to tailor recommendations.',
    },
    {
      'q': 'How do I reset my password?',
      'a':
          'On the login screen, tap "Forgot Password?" and enter your email. We\'ll send you a link to reset it.',
    },
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@popmatch.app',
      query: 'subject=PopMatch Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not open email app. Contact: support@popmatch.app'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'HELP & SUPPORT',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: AppTheme.warmCream,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.warmCream),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ
            Text(
              'Frequently asked questions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vintagePaper,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedFaqIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _expandedFaqIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['q']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppTheme.vintagePaper,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppTheme.vintagePaper,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 8),
                            Text(
                              faq['a']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.fadedCurtain
                                        .withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Contact
            Text(
              'Contact us',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vintagePaper,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Theme(
                data: Theme.of(context).copyWith(
                  listTileTheme: const ListTileThemeData(
                    textColor: AppTheme.vintagePaper,
                    iconColor: AppTheme.vintagePaper,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email support'),
                  subtitle: const Text('support@popmatch.app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _launchEmail,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // About
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vintagePaper,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PopMatch',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.vintagePaper,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe-based movie and show discovery. Find what to watch next.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.fadedCurtain.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.fadedCurtain.withValues(alpha: 0.7),
                          ),
                    ),
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
