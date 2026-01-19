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
            top: 8,
            bottom: 0, // Remove extra bottom padding - SafeArea already handles safe areas
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home (Discover) - house icon
              _NavItem(
                assetPath: 'assets/buttons/home_button.png',
                label: 'Discover',
                icon: Icons.home_rounded,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              // 2. For You - search icon
              _NavItem(
                assetPath: 'assets/buttons/search_button.png',
                label: 'For You',
                icon: Icons.people_rounded,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // 3. Watchlist - document/list icon
              _NavItem(
                assetPath: 'assets/buttons/watchlist_button.png',
                label: 'Watchlist',
                icon: Icons.list_rounded,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              // 4. Favorites/Likes - heart icon
              _NavItem(
                assetPath: 'assets/buttons/like_button.png',
                label: 'Favorites',
                icon: Icons.favorite_rounded,
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              // 5. Profile - gear/settings icon
              _NavItem(
                assetPath: 'assets/buttons/settings_button.png',
                label: 'Profile',
                icon: Icons.settings_rounded,
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
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
            width: 64, // Increased to make more room for bigger icons
            height: 64, // Increased to make more room for bigger icons
            decoration: BoxDecoration(
              // Removed backgroundColor - no yellow/colored background for selected button
              borderRadius: BorderRadius.circular(12),
            ),
            child: assetPath != null
                ? Center(
                    child: TransparentButtonImage(
                      assetPath: assetPath!,
                      width: 48, // Increased from 36 to 48 for bigger icons
                      height: 48, // Increased from 36 to 48 for bigger icons
                      fit: BoxFit.contain,
                      // Don't apply color tinting - let button images display in original colors
                      errorWidget: Icon(
                        icon,
                        color: isSelected
                            ? AppTheme.warmCream
                            : AppTheme.warmCream.withValues(alpha: 60),
                        size: 44, // Increased from 32 to 44 for bigger icons
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected
                        ? AppTheme.warmCream
                        : AppTheme.warmCream.withValues(alpha: 60),
                    size: 44, // Increased from 32 to 44 for bigger icons
                  ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
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
          ),
        ],
      ),
    );
  }
}

