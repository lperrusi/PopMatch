import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mood.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../home/home_screen.dart';

/// Mood selection screen for personalized movie recommendations
class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  Mood? _selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'What\'s your mood today?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We\'ll recommend movies that match your current vibe',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              
              // Mood grid with scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: Mood.availableMoods.length,
                    itemBuilder: (context, index) {
                      final mood = Mood.availableMoods[index];
                      final isSelected = _selectedMood?.id == mood.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = mood;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryRed : Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryRed : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.primaryRed.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mood emoji
                                Text(
                                  mood.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                
                                // Mood name
                                Text(
                                  mood.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                
                                // Mood description
                                Text(
                                  mood.description,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected 
                                        ? Colors.white.withOpacity(0.9)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Continue button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood != null ? _continueWithMood : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _selectedMood != null 
                        ? 'Find ${_selectedMood!.name} Movies'
                        : 'Select Your Mood',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Bottom padding to prevent overflow
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Continues with selected mood
  Future<void> _continueWithMood() async {
    if (_selectedMood == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);

    // Save selected mood to user preferences
    await authProvider.updatePreferences({
      'currentMood': _selectedMood!.id,
      'lastMoodUpdate': DateTime.now().toIso8601String(),
    });

    // Load movies based on mood
    await _loadMoodBasedMovies();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  /// Loads movies based on selected mood
  Future<void> _loadMoodBasedMovies() async {
    if (_selectedMood == null) return;

    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    
    try {
      // Load movies based on mood's preferred genres
      await movieProvider.loadMoviesByMood(_selectedMood!);
    } catch (e) {
      // Fallback to popular movies if mood-based loading fails
      await movieProvider.loadPopularMovies(refresh: true);
    }
  }
} 