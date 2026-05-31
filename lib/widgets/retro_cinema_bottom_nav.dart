import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import '../utils/theme.dart';
import '../utils/l10n_extension.dart';
import 'transparent_button_image.dart';

/// Custom bottom navigation bar with Retro Cinema aesthetic and custom button assets
class RetroCinemaBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RetroCinemaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cinemaRed,
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 6,
            bottom: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home (Discover)
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/home_button.png',
                  label: l10n.navDiscover,
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              // 2. Search — badge count comes from SocialProvider
              Consumer<SocialProvider>(
                builder: (ctx, social, _) => Expanded(
                  child: _NavItem(
                    assetPath: 'assets/buttons/search_button.png',
                    label: l10n.navSearch,
                    icon: Icons.search_rounded,
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                    badgeCount: social.incomingRequests.length,
                  ),
                ),
              ),
              // 3. Watchlist
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/watchlist_button.png',
                  label: l10n.navWatchlist,
                  icon: Icons.list_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              // 4. Favorites/Likes
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/like_button.png',
                  label: l10n.navFavorites,
                  icon: Icons.favorite_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              // 5. Profile
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/settings_button.png',
                  label: l10n.navProfile,
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item with custom asset and optional badge
class _NavItem extends StatelessWidget {
  final String? assetPath;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    this.assetPath,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected
        ? AppTheme.warmCream
        : AppTheme.warmCream.withValues(alpha: 60);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: assetPath != null
                    ? TransparentButtonImage(
                        assetPath: assetPath!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorWidget: Icon(icon, color: iconColor, size: 28),
                      )
                    : Icon(icon, color: iconColor, size: 28),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.popcornGold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppTheme.filmStripBlack,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: iconColor,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
