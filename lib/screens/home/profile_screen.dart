import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../../models/movie.dart';
// import '../../services/iap_service.dart'; // Removed for simplified build
// import '../../services/ads_service.dart'; // Removed for simplified build
import '../auth/login_screen.dart';
import 'edit_preferences_screen.dart';

/// Profile screen showing user information and account management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: AppTheme.warmCream,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = authProvider.userData!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info card - centered
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.primaryRed,
                            child: Text(
                              user.email[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Email
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Display name if available
                          if (user.displayName != null)
                            Text(
                              user.displayName!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Watchlist',
                        value: user.watchlist.length.toString(),
                        icon: Icons.bookmark,
                        color: AppTheme.vintagePaper,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Liked Movies',
                        value: user.likedMovies.length.toString(),
                        icon: Icons.favorite,
                        color: AppTheme.vintagePaper,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Liked movies section
                if (user.likedMovies.isNotEmpty) ...[
                  Text(
                    'Recently Liked Movies',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.vintagePaper,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer<MovieProvider>(
                    builder: (context, movieProvider, child) {
                      final likedMovies = movieProvider.movies
                          .where((movie) => user.likedMovies.contains(movie.id.toString()))
                          .take(5)
                          .toList();
                      
                      return Column(
                        children: likedMovies.map((movie) => _LikedMovieTile(movie: movie)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Account settings
                Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vintagePaper,
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Preferences'),
                        subtitle: const Text('Genres and streaming platforms'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditPreferencesScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement notifications settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications settings coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement privacy settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy settings coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement help and support
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & support coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.remove_circle_outline),
                        title: const Text('Remove Ads'),
                        subtitle: const Text('Remove all ads'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRemoveAdsDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cinemaRed,
              foregroundColor: AppTheme.warmCream,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Handles user logout
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Shows remove ads dialog
  void _showRemoveAdsDialog(BuildContext context) {
    // if (AdsService.instance.adsRemoved) { // Removed for simplified build
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Ads are already removed!')),
    //   );
    //   return;
    // }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Ads'),
        content: const Text(
          'Remove all ads from PopMatch for a one-time purchase. '
          'Enjoy an ad-free movie discovery experience!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _purchaseRemoveAds();
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  /// Purchases remove ads
  Future<void> _purchaseRemoveAds() async {
    try {
      // final success = await IAPService.instance.purchaseRemoveAds(); // Removed for simplified build
      const success = false; // Placeholder for simplified build
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase initiated! Check your email for confirmation.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Statistics card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liked movie tile widget
class _LikedMovieTile extends StatelessWidget {
  final Movie movie;

  const _LikedMovieTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 60,
            child: movie.posterUrl != null
                ? Image.network(
                    movie.posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
          ),
        ),
        title: Text(
          movie.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          movie.year ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: AppTheme.vintagePaper,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              movie.formattedRating,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.vintagePaper,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 