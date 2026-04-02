import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import 'friends_watching_screen.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'SOCIAL',
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
                    title: const Text('What your friends are watching'),
                    subtitle: const Text(
                      'Swipe cards based on people you follow',
                    ),
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
                const SizedBox(height: 16),
                Text(
                  'Find users',
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
                        decoration: const InputDecoration(
                          hintText: 'Search by name or email',
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
                              label: const Text('Retry'),
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
                    'accepted' => 'Following',
                    'pending' => 'Pending',
                    'declined' => 'Follow',
                    _ => 'Follow',
                  };
                  return Card(
                    child: ListTile(
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
                                  const SnackBar(
                                    content: Text('Follow request sent'),
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
                  'Follow requests',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (social.incomingRequests.isEmpty)
                  const Text('No pending requests.')
                else
                  ...social.incomingRequests.map((req) => Card(
                        child: ListTile(
                          title: Text(
                            req.followerUid.length > 6
                                ? 'User ${req.followerUid.substring(0, 6)}'
                                : 'User ${req.followerUid}',
                          ),
                          subtitle: const Text('wants to follow you'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => social.respondToFollowRequest(
                                  requesterUid: req.followerUid,
                                  accept: false,
                                ),
                                child: const Text('Decline'),
                              ),
                              FilledButton(
                                onPressed: () => social.respondToFollowRequest(
                                  requesterUid: req.followerUid,
                                  accept: true,
                                ),
                                child: const Text('Accept'),
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
