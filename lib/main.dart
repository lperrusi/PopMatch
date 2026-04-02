import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/show_provider.dart';
import 'providers/recommendations_provider.dart';
import 'providers/streaming_provider.dart';
import 'providers/social_provider.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_config.dart';
import 'services/omdb_service.dart';

/// Main entry point for the PopMatch app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock all screens to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services with individual error handling
  try {
  await FirebaseConfig.initialize();
  } catch (e, stackTrace) {
    debugPrint('Error initializing Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  try {
  await NotificationService.instance.initialize();
  } catch (e, stackTrace) {
    debugPrint('Error initializing NotificationService: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue - notifications are optional
  }
  
  // OMDb (optional): pass at build time, e.g. flutter run --dart-define=OMDB_API_KEY=your_key
  // Do not commit real keys; rotate any key that was previously hardcoded in source.
  try {
    const omdbFromEnv =
        String.fromEnvironment('OMDB_API_KEY', defaultValue: '');
    if (omdbFromEnv.isNotEmpty) {
      await OMDbService.instance.setApiKey(omdbFromEnv);
      debugPrint('OMDb API key configured from build environment');
    } else {
      await OMDbService.instance.loadApiKey();
    }
  } catch (e, stackTrace) {
    debugPrint('Error loading OMDb API key: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  // Run app even if services fail to initialize
  runApp(const PopMatchApp());
}

/// Root widget for the PopMatch application
class PopMatchApp extends StatelessWidget {
  const PopMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => ShowProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider(create: (_) => StreamingProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'PopMatch',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.retroCinemaLightTheme,
            darkTheme: AppTheme.retroCinemaTheme,
            themeMode: ThemeMode.dark, // Use dark theme by default for Retro Cinema aesthetic
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
} 