import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration with Retro Cinema Romance aesthetic
class AppTheme {
  // Retro Cinema Romance Color Palette (from guide)
  // Fixed cinema red color extracted from splash screen (ff2e1403)
  static const Color _defaultCinemaRed = Color(0xFF2E1403);
  
  // cinemaRed is now fixed to improve performance (no dynamic extraction needed)
  static const Color cinemaRed = _defaultCinemaRed; // Primary red (fixed)
  
  static const Color popcornGold = Color(0xFFF6C344); // Accent gold
  static const Color filmStripBlack = Color(0xFF1A1A1A); // Primary black
  static const Color creamyWhite = Color(0xFFF7F3E8); // Primary cream
  static const Color sepiaBrown = Color(0xFF8B6914); // Accent brown
  static const Color vintagePaper = Color(0xFFF2E8D9); // Light background
  static const Color fadedCurtain = Color(0xFFC4A484); // Medium background
  
  // Backward compatibility aliases
  static Color get brickRed => cinemaRed;
  static const Color warmCream = creamyWhite;
  static const Color darkerBrickRed = Color(0xFF8B1519); // Darker shade of cinema red
  static const Color lighterCreamHighlight = vintagePaper;
  static const Color deepMidnightBrown = filmStripBlack;

  // Backward compatibility - map old color names to new ones
  static Color get primaryRed => brickRed;
  static const Color darkRed = darkerBrickRed;
  static Color get lightRed => brickRed;
  static const Color pureBlack = deepMidnightBrown;
  static const Color darkGray = deepMidnightBrown;
  static const Color mediumGray = deepMidnightBrown;
  static const Color lightGray = warmCream;
  static const Color pureWhite = warmCream;
  static const Color offWhite = warmCream;
  static const Color backgroundColor = deepMidnightBrown;
  static const Color lightBackgroundColor = lighterCreamHighlight;

  // Font families
  static String get headerFont => 'Bebas Neue'; // For headers/titles
  static String get bodyFont => 'Lato'; // For body text

  /// Main theme configuration (Dark theme with Retro Cinema aesthetic)
  static ThemeData get retroCinemaTheme => ThemeData(
    useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deepMidnightBrown,
        colorScheme: ColorScheme.dark(
          primary: brickRed,
          secondary: darkerBrickRed,
          surface: deepMidnightBrown,
          background: deepMidnightBrown,
          onPrimary: warmCream,
          onSecondary: warmCream,
          onSurface: warmCream,
          onBackground: warmCream,
          error: brickRed,
          onError: warmCream,
    ),
        appBarTheme: AppBarTheme(
          backgroundColor: deepMidnightBrown,
          foregroundColor: warmCream,
      elevation: 0,
      centerTitle: true,
          titleTextStyle: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: warmCream,
            letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
          color: deepMidnightBrown,
          elevation: 8,
          shadowColor: brickRed.withValues(alpha: 30),
      shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: brickRed.withValues(alpha: 50),
              width: 1,
            ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
            backgroundColor: brickRed,
            foregroundColor: warmCream,
            elevation: 4,
            shadowColor: brickRed.withValues(alpha: 50),
        shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
        ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
            foregroundColor: brickRed,
        shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
          fillColor: deepMidnightBrown,
      border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: brickRed.withValues(alpha: 50),
              width: 1,
            ),
      ),
      enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: brickRed.withValues(alpha: 50),
              width: 1,
            ),
      ),
      focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: brickRed,
              width: 2,
            ),
      ),
      errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: brickRed,
              width: 1,
      ),
    ),
          labelStyle: GoogleFonts.lato(
            color: warmCream.withValues(alpha: 70),
          ),
          hintStyle: GoogleFonts.lato(
            color: warmCream.withValues(alpha: 50),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.bebasNeue(
            fontSize: 48,
            color: warmCream,
            letterSpacing: 2,
          ),
          displayMedium: GoogleFonts.bebasNeue(
            fontSize: 40,
            color: warmCream,
            letterSpacing: 1.5,
          ),
          displaySmall: GoogleFonts.bebasNeue(
        fontSize: 32,
            color: warmCream,
            letterSpacing: 1.2,
      ),
          headlineLarge: GoogleFonts.bebasNeue(
        fontSize: 28,
            color: warmCream,
            letterSpacing: 1,
      ),
          headlineMedium: GoogleFonts.bebasNeue(
        fontSize: 24,
            color: warmCream,
            letterSpacing: 0.8,
      ),
          headlineSmall: GoogleFonts.bebasNeue(
        fontSize: 20,
            color: warmCream,
            letterSpacing: 0.5,
      ),
          titleLarge: GoogleFonts.lato(
        fontSize: 18,
            fontWeight: FontWeight.w700,
            color: warmCream,
            letterSpacing: 0.3,
      ),
          titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
            color: warmCream,
            letterSpacing: 0.2,
      ),
          titleSmall: GoogleFonts.lato(
        fontSize: 14,
            fontWeight: FontWeight.w600,
            color: warmCream.withValues(alpha: 80),
            letterSpacing: 0.1,
      ),
          bodyLarge: GoogleFonts.lato(
        fontSize: 16,
            color: warmCream,
            height: 1.5,
      ),
          bodyMedium: GoogleFonts.lato(
        fontSize: 14,
            color: warmCream.withValues(alpha: 90),
            height: 1.5,
      ),
          bodySmall: GoogleFonts.lato(
        fontSize: 12,
            color: warmCream.withValues(alpha: 70),
            height: 1.4,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: deepMidnightBrown,
          selectedItemColor: brickRed,
          unselectedItemColor: warmCream.withValues(alpha: 50),
          selectedLabelStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
    ),
        iconTheme: const IconThemeData(
          color: warmCream,
          size: 24,
        ),
        dividerTheme: DividerThemeData(
          color: brickRed.withValues(alpha: 30),
          thickness: 1,
      ),
      );

  /// Light theme variant (if needed for specific screens)
  static ThemeData get retroCinemaLightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lighterCreamHighlight,
        colorScheme: ColorScheme.light(
          primary: brickRed,
          secondary: darkerBrickRed,
          surface: lighterCreamHighlight,
          background: lighterCreamHighlight,
          onPrimary: warmCream,
          onSecondary: warmCream,
          onSurface: deepMidnightBrown,
          onBackground: deepMidnightBrown,
          error: brickRed,
          onError: warmCream,
    ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.bebasNeue(
            fontSize: 48,
            color: deepMidnightBrown,
            letterSpacing: 2,
      ),
          displayMedium: GoogleFonts.bebasNeue(
            fontSize: 40,
            color: deepMidnightBrown,
            letterSpacing: 1.5,
      ),
          bodyLarge: GoogleFonts.lato(
        fontSize: 16,
            color: deepMidnightBrown,
            height: 1.5,
      ),
          bodyMedium: GoogleFonts.lato(
        fontSize: 14,
            color: deepMidnightBrown.withValues(alpha: 90),
            height: 1.5,
      ),
    ),
  );

  // Legacy theme methods for backward compatibility
  static ThemeData get lightTheme => retroCinemaLightTheme;
  static ThemeData get darkTheme => retroCinemaTheme;

  /// Gets the appropriate theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? retroCinemaTheme : retroCinemaLightTheme;
  }
} 
