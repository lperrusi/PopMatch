import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

/// Intro onboarding (Figma): 3 screens — Swipe to Match, AI Picks, Curate Watchlist
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<Map<String, String>> _screens = [
    {
      'title': 'SWIPE TO MATCH',
      'description': 'Swipe right to like, left to pass.\nFind your perfect movie match.',
      'background': 'assets/screens/figma/onboarding1_base.png',
      'overlay': 'assets/screens/figma/onboarding1_overlay.png',
    },
    {
      'title': 'AI Powered Picks',
      'description': 'Our AI learns your taste to suggest movies you will love.',
      'background': 'assets/screens/figma/onboarding2.png',
    },
    {
      'title': 'Curate Your Watchlist',
      'description': 'Save your matches and never wonder what to watch again.',
      'background': 'assets/screens/figma/onboarding3.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: List.generate(_screens.length, (i) => _buildPage(i)),
          ),
          // Content at bottom
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        _screens[_currentPage]['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 42,
                          height: 0.9,
                          color: AppTheme.authCream,
                          letterSpacing: 0.02,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _screens[_currentPage]['description']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          height: 1.4,
                          color: AppTheme.authCreamMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Get Started (last) or spacer
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: _currentPage == _screens.length - 1
                            ? ElevatedButton(
                                onPressed: _complete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.authRed,
                                  foregroundColor: AppTheme.authCream,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Get Started',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 18,
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(height: 24),
                      // Dots + prev/next
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: Icon(
                              Icons.chevron_left,
                              size: 32,
                              color: _currentPage > 0 ? AppTheme.authCream : Colors.transparent,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_screens.length, (i) {
                              final isActive = i == _currentPage;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isActive ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.authRed
                                      : AppTheme.authCream.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          IconButton(
                            onPressed: _currentPage < _screens.length - 1
                                ? () => _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: Icon(
                              Icons.chevron_right,
                              size: 32,
                              color: _currentPage < _screens.length - 1
                                  ? AppTheme.authCream
                                  : Colors.transparent,
                            ),
                          ),
                        ],
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

  Widget _buildPage(int index) {
    final data = _screens[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          data['background']!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppTheme.authBackground),
        ),
        if (data['overlay'] != null)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.08,
            top: MediaQuery.of(context).size.height * 0.46,
            width: MediaQuery.of(context).size.width * 0.115,
            child: Image.asset(
              data['overlay']!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        // Gradient for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
                AppTheme.authBackground,
              ],
              stops: const [0.0, 0.4, 0.85],
            ),
          ),
        ),
      ],
    );
  }
}
