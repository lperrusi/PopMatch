import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../home/home_screen.dart';

/// Onboarding setup (Figma): Step 1 Welcome, Step 2 Genres, Step 3 Streaming. Gold buttons, auth styling.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<int> _selectedGenres = {};
  final Set<String> _selectedPlatforms = {};

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userData == null) return;
    await authProvider.updatePreferences({
      'selectedGenres': _selectedGenres.toList(),
      'selectedPlatforms': _selectedPlatforms.toList(),
      'selectedYears': <int>[],
      'onboardingCompleted': true,
    });
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _toggleGenre(int genreId) {
    setState(() {
      if (_selectedGenres.contains(genreId)) {
        _selectedGenres.remove(genreId);
      } else {
        _selectedGenres.add(genreId);
      }
    });
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/screens/figma/background_auth.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.authBackground),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.chevron_left,
                              color: AppTheme.authCream, size: 24),
                          label: Text('Back',
                              style: GoogleFonts.lato(
                                  color: AppTheme.authCream,
                                  fontWeight: FontWeight.w600)),
                        )
                      else
                        const SizedBox(width: 80),
                      Text(
                        '${_currentPage + 1} of 3',
                        style: GoogleFonts.lato(
                            color: AppTheme.authCream.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _currentPage == 2
                              ? _completeOnboarding
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.authGoldStart,
                                  AppTheme.authGoldEnd
                                ],
                              ),
                            ),
                            child: Text(
                              _currentPage == 2 ? 'Get Started' : 'Next',
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 18,
                                  letterSpacing: 0.05,
                                  color: AppTheme.authBackground),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: [
                      _buildWelcomePage(),
                      _buildGenreSelectionPage(),
                      _buildPlatformSelectionPage(),
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

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/screens/figma/popcorn.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.movie_rounded,
                size: 80, color: AppTheme.authCream),
          ),
          const SizedBox(height: 32),
          Text(
            'WELCOME TO POPMATCH!',
            style: GoogleFonts.bebasNeue(
                fontSize: 32, color: AppTheme.authCream, letterSpacing: 0.05),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Let's personalize your movie discovery. Pick what you love and we'll find the best matches.",
            style:
                GoogleFonts.lato(color: AppTheme.authCreamMuted, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
              Icons.swipe, 'Swipe to discover movies you\'ll love'),
          _buildFeatureItem(Icons.bookmark, 'Save to your watchlist'),
          _buildFeatureItem(
              Icons.filter_list, 'Filter by genres and preferences'),
          _buildFeatureItem(Icons.share, 'Share with friends'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.authGoldStart, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(color: AppTheme.authCream, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelectionPage() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        final genres = movieProvider.genres;
        if (genres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.authCream),
                const SizedBox(height: 16),
                Text('Loading genres...',
                    style: GoogleFonts.lato(color: AppTheme.authCreamMuted)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHAT GENRES DO YOU LOVE?',
                style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    color: AppTheme.authCream,
                    letterSpacing: 0.05),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your favorite genres for better recommendations.',
                style: GoogleFonts.lato(
                    color: AppTheme.authCreamMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: genres.entries.map((e) {
                      final isSelected = _selectedGenres.contains(e.key);
                      return SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleGenre(e.key),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.authRed.withValues(alpha: 0.4)
                                    : AppTheme.authInputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.authRed
                                      : AppTheme.authBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.lato(
                                    color: isSelected
                                        ? AppTheme.authCream
                                        : AppTheme.authCreamMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHERE DO YOU WATCH MOVIES?',
            style: GoogleFonts.bebasNeue(
                fontSize: 28, color: AppTheme.authCream, letterSpacing: 0.05),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the streaming services you have access to.',
            style:
                GoogleFonts.lato(color: AppTheme.authCreamMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._streamingPlatforms.map((platform) {
            final isSelected = _selectedPlatforms.contains(platform);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _togglePlatform(platform),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.authRed.withValues(alpha: 0.2)
                          : AppTheme.authInputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.authRed : AppTheme.authBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppTheme.authRed
                              : AppTheme.authCream.withValues(alpha: 0.5),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          platform,
                          style: GoogleFonts.lato(
                            color: isSelected
                                ? AppTheme.authCream
                                : AppTheme.authCreamMuted,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
