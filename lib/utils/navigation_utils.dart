import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Utility class for fast navigation transitions
class NavigationUtils {
  /// Premium Material "shared axis (scaled)" transition — the destination fades
  /// in while scaling up (zoom / fade-through), with no shared-element distortion.
  /// Used for opening detail screens: fast (~300 ms) and the fully-laid-out
  /// screen is interactive/scrollable the moment the transition settles.
  static PageRouteBuilder<T> premiumScaleRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      // Solid fill so there is no flash behind the fade-through.
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: AppTheme.vintagePaper,
          child: child,
        );
      },
    );
  }

  /// Creates a smooth slide transition route optimized for loading screens
  static PageRouteBuilder<T> fastSlideRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 280),
    Duration? reverseDuration,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration ?? const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        final offsetAnimation = animation.drive(tween);
        
        // Combine fade and slide for smoother transition
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Creates a fast fade transition route (200ms)
  static PageRouteBuilder<T> fastFadeRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

