import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/premium_service.dart';
import '../utils/l10n_extension.dart';
import '../utils/theme.dart';

/// Shows the premium upsell as a modal bottom sheet. [onUnlocked] runs after the
/// user enables premium (today via the dev toggle; later via a real purchase),
/// so the caller can proceed into the gated surface.
Future<void> showPremiumUpsell(
  BuildContext context, {
  required VoidCallback onUnlocked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PremiumUpsellSheet(onUnlocked: onUnlocked),
  );
}

/// Retro Cinema premium pitch: lists the premium perks, an "Upgrade" CTA
/// (real IAP later) and a clearly-labelled dev toggle to unlock for testing.
class PremiumUpsellSheet extends StatelessWidget {
  final VoidCallback onUnlocked;

  const PremiumUpsellSheet({super.key, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vintagePaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppTheme.filmStripBlack.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: AppTheme.popcornGold, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.premiumUpsellTitle,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 30,
                      color: AppTheme.cinemaRed,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _perk(l10n.premiumPerkUnlimitedSwipes),
            _perk(l10n.premiumPerkNoAds),
            _perk(l10n.premiumPerkForYou),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.premiumComingSoon),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cinemaRed,
                foregroundColor: AppTheme.warmCream,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.premiumUpgradeCta,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Dev-only unlock so the gated surface is testable without IAP.
            TextButton(
              onPressed: () async {
                await context.read<PremiumService>().setPremium(true);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                onUnlocked();
              },
              child: Text(
                l10n.premiumDevEnable,
                style: GoogleFonts.lato(
                  color: AppTheme.sepiaBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perk(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.likeGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: AppTheme.filmStripBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
