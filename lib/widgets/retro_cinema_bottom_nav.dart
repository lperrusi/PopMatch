import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cinemaRed,
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 4,
            bottom: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home (Discover) - house icon
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/home_button.png',
                  label: 'Discover',
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              // 2. Search
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/search_button.png',
                  label: 'Search',
                  icon: Icons.search_rounded,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              // 3. Watchlist - document/list icon
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/watchlist_button.png',
                  label: 'Watchlist',
                  icon: Icons.list_rounded,
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              // 4. Favorites/Likes - heart icon
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/like_button.png',
                  label: 'Favorites',
                  icon: Icons.favorite_rounded,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              // 5. Profile - gear/settings icon
              Expanded(
                child: _NavItem(
                  assetPath: 'assets/buttons/settings_button.png',
                  label: 'Profile',
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

/// Individual navigation item with custom asset
class _NavItem extends StatelessWidget {
  final String? assetPath;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    this.assetPath,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: assetPath != null
                ? Center(
                    child: TransparentButtonImage(
                      assetPath: assetPath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorWidget: Icon(
                        icon,
                        color: isSelected
                            ? AppTheme.warmCream
                            : AppTheme.warmCream.withValues(alpha: 60),
                        size: 36,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected
                        ? AppTheme.warmCream
                        : AppTheme.warmCream.withValues(alpha: 60),
                    size: 36,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.warmCream
                  : AppTheme.warmCream.withValues(alpha: 60),
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

