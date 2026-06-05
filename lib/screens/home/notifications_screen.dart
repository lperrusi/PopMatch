import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../services/feature_flags.dart';
import '../../services/notification_service.dart';
import '../../providers/social_provider.dart';
import 'social_hub_screen.dart';

/// Notifications settings screen - toggles stored in user preferences
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _matchReminders = true;
  bool _newRecommendations = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFromUser();
  }

  void _loadFromUser() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userData;
    if (user != null) {
      final prefs = user.preferences;
      setState(() {
        _pushEnabled = prefs['notificationsPush'] as bool? ?? true;
        _matchReminders = prefs['notificationsMatchReminders'] as bool? ?? true;
        _newRecommendations =
            prefs['notificationsRecommendations'] as bool? ?? true;
      });
    }
  }

  Future<void> _save(String key, bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updatePreferences({key: value});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.notificationsPageTitle,
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
              l10n.notificationsIntro,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  if (FeatureFlags.socialUiEnabled) ...[
                    ListTile(
                      leading: const Icon(Icons.group_add_rounded),
                      title: Text(l10n.followRequestsToggle),
                      subtitle: Text(l10n.followRequestsToggleSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          NavigationUtils.fastSlideRoute(const SocialHubScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  SwitchListTile(
                    title: Text(l10n.pushNotificationsToggle),
                    subtitle: Text(l10n.pushNotificationsToggleSubtitle),
                    value: _pushEnabled,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) {
                      setState(() => _pushEnabled = v);
                      _save('notificationsPush', v);
                      // Reflect the choice in the live social listeners and
                      // prompt for the OS permission when enabling.
                      context
                          .read<SocialProvider>()
                          .setNotificationsEnabled(v);
                      if (v) NotificationService.instance.requestPermissions();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.matchRemindersToggle),
                    subtitle: Text(l10n.matchRemindersToggleSubtitle),
                    value: _matchReminders,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) {
                      setState(() => _matchReminders = v);
                      _save('notificationsMatchReminders', v);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.newRecommendationsToggle),
                    subtitle: Text(l10n.newRecommendationsToggleSubtitle),
                    value: _newRecommendations,
                    activeThumbColor: AppTheme.vintagePaper,
                    onChanged: (v) {
                      setState(() => _newRecommendations = v);
                      _save('notificationsRecommendations', v);
                    },
                  ),
                  if (FeatureFlags.socialUiEnabled) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l10n.friendRequestsToggle),
                      subtitle: Text(l10n.friendRequestsToggleSubtitle),
                      value: (Provider.of<AuthProvider>(context, listen: false)
                                  .userData
                                  ?.preferences['notificationsFriendRequests']
                              as bool?) ??
                          true,
                      activeThumbColor: AppTheme.vintagePaper,
                      onChanged: (v) {
                        _save('notificationsFriendRequests', v);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l10n.followAcceptedToggle),
                      subtitle: Text(l10n.followAcceptedToggleSubtitle),
                      value: (Provider.of<AuthProvider>(context, listen: false)
                                  .userData
                                  ?.preferences['notificationsFollowAccepted']
                              as bool?) ??
                          true,
                      activeThumbColor: AppTheme.vintagePaper,
                      onChanged: (v) {
                        _save('notificationsFollowAccepted', v);
                      },
                    ),
                  ],
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
