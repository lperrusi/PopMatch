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

/// Splash screen matching Figma Design Intro: popcorn, title, loading indicator (3s)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_initialized) _initializeProviders();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    if (_initialized) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final recommendationsProvider =
          Provider.of<RecommendationsProvider>(context, listen: false);
      final streamingProvider =
          Provider.of<StreamingProvider>(context, listen: false);

      await authProvider.initialize().catchError((e) {
        debugPrint('AuthProvider initialization error: $e');
      });
      _initialized = true;
      if (mounted) _checkAuthState();

      movieProvider
          .initialize()
          .catchError((e) => debugPrint('MovieProvider: $e'));
      recommendationsProvider
          .initialize()
          .catchError((e) => debugPrint('RecommendationsProvider: $e'));
      streamingProvider
          .initialize()
          .catchError((e) => debugPrint('StreamingProvider: $e'));
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      _initialized = true;
      if (mounted) _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

    if (!tutorialCompleted) {
      Navigator.of(context).pushReplacement(
        NavigationUtils.fastSlideRoute(const TutorialScreen()),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      final onboardingCompleted =
          authProvider.userData?.preferences['onboardingCompleted'] ?? false;
      if (onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          NavigationUtils.fastSlideRoute(const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          NavigationUtils.fastSlideRoute(const OnboardingScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        NavigationUtils.fastSlideRoute(const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                // Popcorn with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.authCream.withValues(alpha: 0.2),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset:
                              Offset(0, -8 * (0.5 - (value - 0.5).abs()) * 2),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/screens/figma/popcorn.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.movie_rounded,
                          size: 120,
                          color: AppTheme.authCream,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'PopMatch',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 56,
                    color: AppTheme.authCream,
                    letterSpacing: 0.02,
                    height: 0.9,
                  ),
                ),
                const Spacer(flex: 2),
                // Loading: film icon + spinning gears
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SpinningGear(size: 32, duration: 3, left: true),
                    SizedBox(width: 8),
                    Icon(Icons.movie_creation,
                        size: 32, color: AppTheme.authCream),
                    SizedBox(width: 8),
                    _SpinningGear(size: 24, duration: 2, reverse: true),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    color: AppTheme.authCream,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinningGear extends StatefulWidget {
  final double size;
  final int duration;
  final bool reverse;
  final bool left;

  const _SpinningGear(
      {required this.size,
      required this.duration,
      this.reverse = false,
      this.left = false});

  @override
  State<_SpinningGear> createState() => _SpinningGearState();
}

class _SpinningGearState extends State<_SpinningGear>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * 3.14159 * (widget.reverse ? -1 : 1),
        child:
            Icon(Icons.settings, size: widget.size, color: AppTheme.authCream),
      ),
    );
  }
}
