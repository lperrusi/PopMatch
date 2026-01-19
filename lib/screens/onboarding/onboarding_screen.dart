import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../home/home_screen.dart';

/// Onboarding screen for new users to set preferences
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Selected preferences
  final Set<int> _selectedGenres = {};
  final Set<String> _selectedPlatforms = {};
  final Set<int> _selectedYears = {};

  // Available options
  final List<String> _streamingPlatforms = [
    'Netflix',
    'Amazon Prime',
    'Disney+',
    'Hulu',
    'HBO Max',
    'Apple TV+',
    'Peacock',
    'Paramount+',
    'Crunchyroll',
    'YouTube Premium',
  ];

  final List<int> _yearRanges = [
    2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015,
    2010, 2005, 2000, 1995, 1990, 1985, 1980, 1975, 1970, 1965,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Saves user preferences and navigates to home
  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Ensure user is logged in before saving preferences
    if (authProvider.userData == null) {
      debugPrint('❌ Cannot complete onboarding: user is not logged in');
      return;
    }
    
    debugPrint('🎯 Completing onboarding for user: ${authProvider.userData!.email}');
    
    // Save preferences to Firebase
    await authProvider.updatePreferences({
      'selectedGenres': _selectedGenres.toList(),
      'selectedPlatforms': _selectedPlatforms.toList(),
      'selectedYears': _selectedYears.toList(),
      'onboardingCompleted': true,
    });
    
    // Verify the data was saved
    final savedData = authProvider.userData;
    if (savedData != null) {
      final onboardingCompleted = savedData.preferences['onboardingCompleted'] ?? false;
      debugPrint('✅ Onboarding completion verified. onboardingCompleted: $onboardingCompleted');
      debugPrint('📋 Full preferences: ${savedData.preferences}');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  /// Toggles genre selection
  void _toggleGenre(int genreId) {
    setState(() {
      if (_selectedGenres.contains(genreId)) {
        _selectedGenres.remove(genreId);
      } else {
        _selectedGenres.add(genreId);
      }
    });
  }

  /// Toggles platform selection
  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  /// Toggles year selection
  void _toggleYear(int year) {
    setState(() {
      if (_selectedYears.contains(year)) {
        _selectedYears.remove(year);
      } else {
        _selectedYears.add(year);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/screens/SignIn Screen.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppTheme.deepMidnightBrown);
              },
            ),
          ),
          // Content overlay
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentPage + 1) / 3,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cinemaRed),
                ),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildGenreSelectionPage(),
                      _buildPlatformSelectionPage(),
                    ],
                  ),
                ),
                
                // Navigation buttons - matching tutorial screen style
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sepiaBrown,
                            foregroundColor: AppTheme.warmCream,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox(width: 80),
                      
                      Text(
                        '${_currentPage + 1} of 3',
                        style: TextStyle(
                          color: AppTheme.vintagePaper,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      ElevatedButton(
                        onPressed: _currentPage == 2 ? _completeOnboarding : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.sepiaBrown,
                          foregroundColor: AppTheme.warmCream,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Welcome page
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon
          Container(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/icons/app_icon_512 Background Removed.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to circular icon if main icon fails
                return Image.asset(
                  'assets/icons/app_icon_circular.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Final fallback to Material icon
                    return Container(
            decoration: BoxDecoration(
                        color: AppTheme.brickRed,
                        borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
                        Icons.movie_rounded,
              size: 60,
                        color: AppTheme.warmCream,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Welcome to PopMatch!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.warmCream,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Let\'s personalize your movie discovery experience by setting up your preferences.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.warmCream.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Feature highlights
          _buildFeatureItem(Icons.swipe, 'Swipe to discover movies'),
          _buildFeatureItem(Icons.bookmark, 'Save to your watchlist'),
          _buildFeatureItem(Icons.filter_list, 'Filter by your preferences'),
          _buildFeatureItem(Icons.share, 'Share with friends'),
        ],
      ),
    );
  }

  /// Genre selection page
  Widget _buildGenreSelectionPage() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What genres do you love?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmCream,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your favorite movie genres to get better recommendations.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warmCream.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: movieProvider.genres.length,
                  itemBuilder: (context, index) {
                    final genre = movieProvider.genres.entries.elementAt(index);
                    final isSelected = _selectedGenres.contains(genre.key);
                    
                    return GestureDetector(
                      onTap: () => _toggleGenre(genre.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.popcornGold : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppTheme.popcornGold : AppTheme.warmCream.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            genre.value,
                            style: TextStyle(
                              color: isSelected ? AppTheme.filmStripBlack : AppTheme.warmCream,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Platform selection page
  Widget _buildPlatformSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you watch movies?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.warmCream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your streaming platforms to find movies available on your services.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.warmCream.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: _streamingPlatforms.length,
              itemBuilder: (context, index) {
                final platform = _streamingPlatforms[index];
                final isSelected = _selectedPlatforms.contains(platform);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.popcornGold.withValues(alpha: 0.3) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.popcornGold : AppTheme.warmCream.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.popcornGold : AppTheme.warmCream.withValues(alpha: 0.7),
                    ),
                    title: Text(
                      platform,
                      style: TextStyle(
                        color: AppTheme.warmCream,
                      ),
                    ),
                    onTap: () => _togglePlatform(platform),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Feature item widget
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.popcornGold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.warmCream,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 