import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/social_service.dart';
import '../../models/social_privacy_settings.dart';
import '../../utils/theme.dart';

/// Privacy settings screen - data usage and account options
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _usageDataEnabled = true;
  bool _allowFollowers = true;
  bool _shareLikes = true;
  bool _shareWatchlist = true;
  bool _shareWatching = true;
  bool _saving = false;
  final SocialService _socialService = SocialService.instance;

  @override
  void initState() {
    super.initState();
    _loadFromUser();
  }

  void _loadFromUser() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userData;
    if (user != null) {
      setState(() {
        _usageDataEnabled =
            user.preferences['privacyUsageData'] as bool? ?? true;
      });
    }
    _loadSocialPrivacy();
  }

  Future<void> _loadSocialPrivacy() async {
    final social = await _socialService.getSocialPrivacy();
    if (!mounted) return;
    setState(() {
      _allowFollowers = social.allowFollowers;
      _shareLikes = social.shareLikes;
      _shareWatchlist = social.shareWatchlist;
      _shareWatching = social.shareWatchingActivity;
    });
  }

  Future<void> _saveUsageData(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updatePreferences({'privacyUsageData': value});
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveSocialPrivacy() async {
    await _socialService.updateSocialPrivacy(
      SocialPrivacySettings(
        allowFollowers: _allowFollowers,
        shareLikes: _shareLikes,
        shareWatchlist: _shareWatchlist,
        shareWatchingActivity: _shareWatching,
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete my data'),
        content: const Text(
          'This will remove your account and all associated data (watchlist, likes, preferences) from our servers. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.vintagePaper),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.vintagePaper),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Account deletion currently requires support. Please use Help & Support > Contact Us.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Contact support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'PRIVACY',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: AppTheme.warmCream,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.warmCream),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control how your data is used to personalize your experience.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Use data for recommendations'),
                    subtitle: const Text(
                      'Allow us to use your likes, watchlist and activity to improve your recommendations.',
                    ),
                    value: _usageDataEnabled,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) {
                      setState(() => _usageDataEnabled = v);
                      _saveUsageData(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Social privacy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.filmStripBlack,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Allow followers'),
                    subtitle: const Text('Let other users send follow requests'),
                    value: _allowFollowers,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _allowFollowers = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Share likes'),
                    subtitle: const Text('Followers can see what you like'),
                    value: _shareLikes,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _shareLikes = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Share watchlist'),
                    subtitle: const Text('Followers can see your watchlist activity'),
                    value: _shareWatchlist,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _shareWatchlist = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Share watching activity'),
                    subtitle: const Text('Followers can see what you are currently watching'),
                    value: _shareWatching,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _shareWatching = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.filmStripBlack,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('What we store'),
                    subtitle: Text(
                      'We store your email, watchlist, likes and dislikes, and preferences to provide the service.',
                    ),
                    isThreeLine: true,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete my data'),
                    subtitle: const Text('Request account and data deletion'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showDeleteDataDialog,
                  ),
                ],
              ),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
