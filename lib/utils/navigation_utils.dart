import 'package:flutter/material.dart';

/// Utility class for fast navigation transitions
class NavigationUtils {
  /// Creates a smooth slide transition route optimized for loading screens
  static PageRouteBuilder<T> fastSlideRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
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

