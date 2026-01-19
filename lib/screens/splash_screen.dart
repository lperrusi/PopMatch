import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../providers/recommendations_provider.dart';
import '../providers/streaming_provider.dart';
import '../utils/theme.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'tutorial/tutorial_screen.dart';
import '../utils/navigation_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Retro Cinema styled splash screen with custom image
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    // Initialize providers and navigate after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_initialized) {
        _initializeProviders();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initializes all providers
  Future<void> _initializeProviders() async {
    if (_initialized) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final recommendationsProvider = Provider.of<RecommendationsProvider>(context, listen: false);
      final streamingProvider = Provider.of<StreamingProvider>(context, listen: false);

      // Initialize auth provider first (required for navigation decision)
      await authProvider.initialize().catchError((e) {
        debugPrint('AuthProvider initialization error: $e');
      });

      _initialized = true;
      
      // Navigate immediately after auth check - don't wait for other providers
      if (mounted) {
      _checkAuthState();
      }

      // Initialize other providers in background (non-blocking)
      // These will load in parallel while navigation happens
      movieProvider.initialize().catchError((e) {
        debugPrint('MovieProvider initialization error: $e');
      });
      recommendationsProvider.initialize().catchError((e) {
        debugPrint('RecommendationsProvider initialization error: $e');
      });
      streamingProvider.initialize().catchError((e) {
        debugPrint('StreamingProvider initialization error: $e');
      });
    } catch (e) {
      debugPrint('Splash screen initialization error: $e');
      // If initialization fails, still try to navigate
      _initialized = true;
      if (mounted) {
      _checkAuthState();
      }
    }
  }

  /// Checks authentication state and navigates accordingly
  Future<void> _checkAuthState() async {
    if (!mounted) return;
    
    // Check if tutorial has been completed
    final prefs = await SharedPreferences.getInstance();
    final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;
    
    if (!tutorialCompleted) {
      // Show tutorial for first-time users
      Navigator.of(context).pushReplacement(
        NavigationUtils.fastSlideRoute(const TutorialScreen()),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // IMPORTANT: Only show onboarding AFTER user has logged in
    // Onboarding should NEVER be shown before login
    // Check authentication status - user must be logged in to see onboarding
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      // User is authenticated - check if onboarding is completed
      final onboardingCompleted = authProvider.userData?.preferences['onboardingCompleted'] ?? false;
      
      if (onboardingCompleted) {
        // User has completed onboarding - go to home
        Navigator.of(context).pushReplacement(
          NavigationUtils.fastSlideRoute(const HomeScreen()),
        );
      } else {
        // User is logged in but hasn't completed onboarding - show onboarding
        Navigator.of(context).pushReplacement(
          NavigationUtils.fastSlideRoute(const OnboardingScreen()),
        );
      }
    } else {
      // User is NOT authenticated - show login screen
      // Onboarding should NEVER be shown here
      Navigator.of(context).pushReplacement(
        NavigationUtils.fastSlideRoute(const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cinemaRed,
      body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full screen splash image - fills entire screen edge-to-edge
                Positioned.fill(
                  child: Image.asset(
                    'assets/screens/Splash Screen.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading splash image: $error');
                      // Fallback if image not found
                      return Container(
                        color: AppTheme.deepMidnightBrown,
                        child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                                child: Image.asset(
                                  'assets/icons/app_icon_1024.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/icons/app_icon_circular.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.movie_rounded,
                        size: 60,
                                          color: AppTheme.warmCream,
                                        );
                                      },
                                    );
                                  },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PopMatch',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 48,
                                  color: AppTheme.warmCream,
                                  letterSpacing: 2,
                      ),
                    ),
                  ],
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
      ),
    );
  }
} 
