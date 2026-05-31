import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/social_service.dart';
import '../../models/social_privacy_settings.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';

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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDataDialogTitle),
        content: Text(l10n.deleteDataDialogContent),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.vintagePaper),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.vintagePaper),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.deleteDataSnackbar),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(l10n.deleteDataLearnMore),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.privacyPageTitle,
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
              l10n.privacyIntro,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.useDataRecommendations),
                    subtitle: Text(l10n.useDataRecommendationsSubtitle),
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
              l10n.socialPrivacySection,
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
                    title: Text(l10n.allowFollowers),
                    subtitle: Text(l10n.allowFollowersSubtitle),
                    value: _allowFollowers,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _allowFollowers = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.shareLikes),
                    subtitle: Text(l10n.shareLikesSubtitle),
                    value: _shareLikes,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _shareLikes = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.shareWatchlist),
                    subtitle: Text(l10n.shareWatchlistSubtitle),
                    value: _shareWatchlist,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) async {
                      setState(() => _shareWatchlist = v);
                      await _saveSocialPrivacy();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.shareWatchingActivity),
                    subtitle: Text(l10n.shareWatchingActivitySubtitle),
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
              l10n.yourDataSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.filmStripBlack,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.whatWeStore),
                    subtitle: Text(l10n.whatWeStoreSubtitle),
                    isThreeLine: true,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.deleteMyData),
                    subtitle: Text(l10n.deleteMyDataSubtitle),
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
