import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/retro_cinema_bottom_nav.dart';
import 'swipe_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
import 'recommendations_screen.dart';
import 'favorites_screen.dart';

/// Static reference to HomeScreen state for updating tabs from anywhere
/// This allows us to update the tab index without recreating the widget
_HomeScreenState? _homeScreenStateInstance;

/// Static method to update HomeScreen tab from anywhere in the app
void updateHomeScreenTab(int index) {
  _homeScreenStateInstance?.updateTabIndex(index);
}

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  final int? initialIndex;
  
  const HomeScreen({
    super.key, 
    this.initialIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    
    // Create screens once to preserve state across tab switches
    // Using IndexedStack keeps all screens alive in memory
    _screens = [
    const SwipeScreen(),
    const RecommendationsScreen(),
    const WatchlistScreen(),
      const FavoritesScreen(),
    const ProfileScreen(),
  ];
    
    // Register this instance globally so it can be updated from anywhere
    _homeScreenStateInstance = this;
  }
  
  @override
  void dispose() {
    // Clear the global reference when this screen is disposed
    if (_homeScreenStateInstance == this) {
      _homeScreenStateInstance = null;
    }
    super.dispose();
  }
  
  /// Updates the current tab index without recreating the screen
  void updateTabIndex(int index) {
    if (mounted && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepMidnightBrown,
      // Use IndexedStack to preserve state of all screens
      // Only the screen at _currentIndex is visible, but all remain in memory
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: RetroCinemaBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
} 