import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

/// Tutorial screen showing app features for first-time users
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _tutorialImages = [
    'assets/screens/PopMatch - Tutorial Screen 1 - Editado.png',
    'assets/screens/PopMatch - Tutorial Screen 2 - Editado.png',
    'assets/screens/PopMatch - Tutorial Screen 3 - Editado.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks tutorial as completed and navigates to login
  Future<void> _completeTutorial() async {
    // Mark tutorial as seen
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Page content with images
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: _tutorialImages.map((imagePath) {
              return _buildTutorialPage(imagePath);
            }).toList(),
          ),

            // Progress indicator at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _tutorialImages.length,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cinemaRed),
              ),
            ),

            // Navigation buttons overlaid at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
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
                      '${_currentPage + 1} of ${_tutorialImages.length}',
                      style: TextStyle(
                        color: AppTheme.vintagePaper,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    ElevatedButton(
                      onPressed: _currentPage == _tutorialImages.length - 1
                          ? _completeTutorial
                          : () {
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
                      child: Text(
                        _currentPage == _tutorialImages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  /// Builds a tutorial page with the image
  Widget _buildTutorialPage(String imagePath) {
    return SizedBox.expand(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.warmCream.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tutorial image not found',
                  style: TextStyle(
                    color: AppTheme.warmCream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

