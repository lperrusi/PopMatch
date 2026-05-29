import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';

/// Help & Support screen - FAQ, contact, about
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaqIndex;

  List<Map<String, String>> _faqs(BuildContext context) {
    final l10n = context.l10n;
    return [
      {'q': l10n.faq1Question, 'a': l10n.faq1Answer},
      {'q': l10n.faq2Question, 'a': l10n.faq2Answer},
      {'q': l10n.faq3Question, 'a': l10n.faq3Answer},
      {'q': l10n.faq4Question, 'a': l10n.faq4Answer},
    ];
  }

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
          SnackBar(
            content: Text(context.l10n.emailErrorSnackbar),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final faqs = _faqs(context);
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.helpSupportPageTitle,
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
              l10n.faqSection,
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
                itemCount: faqs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
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
              l10n.contactSection,
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
                  title: Text(l10n.emailSupportLabel),
                  subtitle: Text(l10n.emailSupportAddress),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _launchEmail,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // About
            Text(
              l10n.aboutSection,
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
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.vintagePaper,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.aboutDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.fadedCurtain.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aboutVersion,
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
