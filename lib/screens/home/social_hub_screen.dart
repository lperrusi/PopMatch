import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import 'friends_watching_screen.dart';
import 'friend_profile_screen.dart';
import 'shared_with_me_screen.dart';
import 'matches_screen.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.socialPageTitle,
          style: GoogleFonts.bebasNeue(
            fontSize: 30,
            color: AppTheme.warmCream,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
      ),
      body: Consumer<SocialProvider>(
        builder: (context, social, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.live_tv_rounded),
                    title: Text(l10n.friendsWatchingCard),
                    subtitle: Text(l10n.friendsWatchingCardSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        NavigationUtils.fastSlideRoute(
                          const FriendsWatchingScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_rounded,
                        color: AppTheme.cinemaRed),
                    title: Text(l10n.matchesCard),
                    subtitle: Text(l10n.matchesCardSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        NavigationUtils.fastSlideRoute(const MatchesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_shared_rounded,
                        color: AppTheme.cinemaRed),
                    title: Text(l10n.sharedWithYouCard),
                    subtitle: Text(l10n.sharedWithYouCardSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        NavigationUtils.fastSlideRoute(
                          const SharedWithMeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.findUsersSection,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.socialSearchHint,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => social.searchUsers(_searchController.text),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (social.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if ((social.error ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              social.error!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: social.isLoading
                                  ? null
                                  : () => social.initialize(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(l10n.retryButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ...social.searchResults.map((user) {
                  final uid = user['uid']?.toString() ?? '';
                  final followStatus =
                      user['followStatus']?.toString() ?? 'notFollowing';
                  final isFollowActionEnabled =
                      uid.isNotEmpty && followStatus == 'notFollowing';
                  final followActionLabel = switch (followStatus) {
                    'accepted' => l10n.followingStatus,
                    'pending' => l10n.pendingStatus,
                    'declined' => l10n.followButton,
                    _ => l10n.followButton,
                  };
                  return Card(
                    child: ListTile(
                      onTap: uid.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                NavigationUtils.fastSlideRoute(
                                  FriendProfileScreen(
                                    uid: uid,
                                    displayName:
                                        user['displayName']?.toString(),
                                    photoURL: user['photoURL']?.toString(),
                                  ),
                                ),
                              ),
                      leading: CircleAvatar(
                        child: Text(
                          (user['displayName']?.toString().isNotEmpty ?? false)
                              ? user['displayName'].toString()[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(user['displayName']?.toString() ?? 'Unknown'),
                      subtitle: Text(user['email']?.toString() ?? ''),
                      trailing: TextButton(
                        onPressed: !isFollowActionEnabled
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await social.sendFollowRequest(uid);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.followRequestSentSnackbar),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        child: Text(followActionLabel),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  l10n.followRequestsSection,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (social.incomingRequests.isEmpty)
                  Text(l10n.noFollowRequests)
                else
                  ...social.incomingRequests.map((req) => Card(
                        child: ListTile(
                          title: Text(
                            social.nameFor(req.followerUid) ??
                                (req.followerUid.length > 6
                                    ? 'User ${req.followerUid.substring(0, 6)}'
                                    : 'User ${req.followerUid}'),
                          ),
                          subtitle: Text(l10n.wantsToFollowYou),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => social.respondToFollowRequest(
                                  requesterUid: req.followerUid,
                                  accept: false,
                                ),
                                child: Text(l10n.declineButton),
                              ),
                              FilledButton(
                                onPressed: () => social.respondToFollowRequest(
                                  requesterUid: req.followerUid,
                                  accept: true,
                                ),
                                child: Text(l10n.acceptButton),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}
