import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/follow_edge.dart';
import '../models/social_activity.dart';
import '../models/social_privacy_settings.dart';
import '../services/social_service.dart';
import '../services/notification_service.dart';
import '../utils/firebase_error_message.dart';

class SocialProvider with ChangeNotifier {
  final SocialService _socialService = SocialService.instance;

  bool _isLoading = false;
  String? _error;
  List<FollowEdge> _incomingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<SocialActivity> _friendsFeed = [];
  List<Map<String, dynamic>> _suggestedUsers = [];
  SocialPrivacySettings _privacy = const SocialPrivacySettings();

  /// uid -> resolved display name, populated lazily from user profile docs.
  final Map<String, String> _displayNames = {};

  // ---- Realtime (in-app local notifications while the app is alive).
  StreamSubscription? _incomingSub;
  StreamSubscription? _edgesSub;
  bool _incomingSeeded = false;
  bool _edgesSeeded = false;
  final Set<String> _acceptedEdgeIds = {};
  bool _notificationsEnabled = true;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FollowEdge> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<SocialActivity> get friendsFeed => _friendsFeed;
  List<Map<String, dynamic>> get suggestedUsers => _suggestedUsers;
  SocialPrivacySettings get privacy => _privacy;

  /// Resolved display name for a uid, or null if not yet known. UI should fall
  /// back to a short uid label when this is null.
  String? nameFor(String uid) => _displayNames[uid];

  /// Batch-resolves and caches display names for the given uids.
  Future<void> resolveNames(List<String> uids) async {
    final missing = uids
        .where((u) => u.isNotEmpty && !_displayNames.containsKey(u))
        .toList();
    if (missing.isEmpty) return;
    final profiles = await _socialService.getUserProfiles(missing);
    var changed = false;
    profiles.forEach((uid, p) {
      final name = (p['displayName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        _displayNames[uid] = name;
        changed = true;
      }
    });
    if (changed) notifyListeners();
  }

  /// Starts live listeners for incoming follow requests and acceptances so the
  /// app can fire local notifications while it's running. Idempotent: cancels
  /// any existing subscriptions first. No-op when Firebase is off (streams null).
  void startRealtime({bool notificationsEnabled = true}) {
    _notificationsEnabled = notificationsEnabled;
    stopRealtime();
    final incoming = _socialService.incomingRequestsStream();
    if (incoming != null) {
      _incomingSub = incoming.listen(
        _onIncomingSnapshot,
        onError: (e) => debugPrint('incomingRequests stream error: $e'),
      );
    }
    final edges = _socialService.outgoingEdgesStream();
    if (edges != null) {
      _edgesSub = edges.listen(
        _onEdgesSnapshot,
        onError: (e) => debugPrint('outgoingEdges stream error: $e'),
      );
    }
  }

  /// Cancels live listeners and resets seed state (call on sign-out / dispose).
  void stopRealtime() {
    _incomingSub?.cancel();
    _edgesSub?.cancel();
    _incomingSub = null;
    _edgesSub = null;
    _incomingSeeded = false;
    _edgesSeeded = false;
    _acceptedEdgeIds.clear();
  }

  /// Toggle whether new events raise local notifications (mirrors the user's
  /// "push notifications" preference). Listeners keep running either way.
  void setNotificationsEnabled(bool enabled) => _notificationsEnabled = enabled;

  Future<void> _onIncomingSnapshot(
      QuerySnapshot<Map<String, dynamic>> snap) async {
    // Keep the live list in sync.
    _incomingRequests = snap.docs.map((d) {
      final data = d.data();
      return FollowEdge.fromJson({
        'followerUid': data['followerUid'],
        'followeeUid': '',
        'status': data['status'] ?? 'pending',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
    notifyListeners();
    await resolveNames(_incomingRequests.map((r) => r.followerUid).toList());

    // Skip the initial snapshot so existing requests don't fire a burst.
    if (!_incomingSeeded) {
      _incomingSeeded = true;
      return;
    }
    if (!_notificationsEnabled) return;
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      if (change.doc.metadata.hasPendingWrites) continue;
      final followerUid = change.doc.data()?['followerUid']?.toString() ?? '';
      if (followerUid.isEmpty) continue;
      final profile = await _socialService.getUserProfile(followerUid);
      final name = (profile?['displayName'] as String?)?.trim();
      await NotificationService.instance.showFriendRequestNotification(
        fromName: (name != null && name.isNotEmpty) ? name : 'Someone',
        fromUid: followerUid,
      );
    }
  }

  Future<void> _onEdgesSnapshot(
      QuerySnapshot<Map<String, dynamic>> snap) async {
    final newlyAccepted = <String>[]; // followeeUids
    for (final doc in snap.docs) {
      final data = doc.data();
      if ((data['status']?.toString()) != 'accepted') continue;
      if (_acceptedEdgeIds.contains(doc.id)) continue;
      _acceptedEdgeIds.add(doc.id);
      if (_edgesSeeded) {
        final followeeUid = data['followeeUid']?.toString() ?? '';
        if (followeeUid.isNotEmpty) newlyAccepted.add(followeeUid);
      }
    }
    // Skip the initial snapshot (pre-existing accepted edges).
    if (!_edgesSeeded) {
      _edgesSeeded = true;
      return;
    }
    if (!_notificationsEnabled) return;
    for (final followeeUid in newlyAccepted) {
      final profile = await _socialService.getUserProfile(followeeUid);
      final name = (profile?['displayName'] as String?)?.trim();
      await NotificationService.instance.showFollowAcceptedNotification(
        byName: (name != null && name.isNotEmpty) ? name : 'Someone',
        byUid: followeeUid,
      );
    }
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }

  /// Movie IDs liked by followed friends — used to show "friend liked this" badge on swipe cards.
  Set<String> get friendLikedMovieIds => _friendsFeed
      .where((a) =>
          a.itemType == SocialItemType.movie &&
          a.activityType == SocialActivityType.liked)
      .map((a) => a.itemId)
      .toSet();

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _socialService.ensureAuthReadyBeforeFirestore();
      await Future.wait([
        loadIncomingRequests(),
        loadFriendsFeed(),
        loadPrivacy(),
        loadSuggestedUsers(),
      ]);
    } catch (e) {
      debugPrint('SocialProvider.initialize: $e');
      _error = userFacingFirebaseMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    await _socialService.ensureUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  Future<void> loadIncomingRequests() async {
    try {
      _incomingRequests = await _socialService.getIncomingRequests();
      notifyListeners();
      // Resolve follower names so the UI shows real names instead of uids.
      await resolveNames(
          _incomingRequests.map((r) => r.followerUid).toList());
    } catch (e) {
      debugPrint('SocialProvider.loadIncomingRequests: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    try {
      _searchResults = await _socialService.searchUsers(query);
      notifyListeners();
    } catch (e) {
      debugPrint('SocialProvider.searchUsers: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
    }
  }

  Future<void> sendFollowRequest(String targetUid) async {
    try {
      await _socialService.sendFollowRequest(targetUid);
    } catch (e) {
      debugPrint('SocialProvider.sendFollowRequest: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
      return;
    }
    _markFollowSent(targetUid);
    await loadIncomingRequests();
  }

  Future<void> respondToFollowRequest({
    required String requesterUid,
    required bool accept,
  }) async {
    try {
      await _socialService.respondToFollowRequest(
        requesterUid: requesterUid,
        accept: accept,
      );
    } catch (e) {
      debugPrint('SocialProvider.respondToFollowRequest: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
      return;
    }
    await loadIncomingRequests();
  }

  Future<void> unfollow(String targetUid) async {
    await _socialService.unfollow(targetUid);
  }

  Future<void> loadFriendsFeed() async {
    try {
      _friendsFeed = await _socialService.getFriendsFeed(limit: 80);
      notifyListeners();
    } catch (e) {
      debugPrint('SocialProvider.loadFriendsFeed: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
    }
  }

  Future<void> loadPrivacy() async {
    try {
      _privacy = await _socialService.getSocialPrivacy();
      notifyListeners();
    } catch (e) {
      debugPrint('SocialProvider.loadPrivacy: $e');
      _error = userFacingFirebaseMessage(e);
      notifyListeners();
    }
  }

  Future<void> updatePrivacy(SocialPrivacySettings settings) async {
    _privacy = settings;
    notifyListeners();
    await _socialService.updateSocialPrivacy(settings);
  }

  Future<void> recordLikedMovie(String movieId) async {
    await _socialService.recordActivity(
      itemType: SocialItemType.movie,
      itemId: movieId,
      activityType: SocialActivityType.liked,
    );
  }

  Future<void> recordLikedShow(String showId) async {
    await _socialService.recordActivity(
      itemType: SocialItemType.show,
      itemId: showId,
      activityType: SocialActivityType.liked,
    );
  }

  Future<void> loadSuggestedUsers({int limit = 10}) async {
    try {
      _suggestedUsers = await _socialService.getSuggestedUsers(limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('SocialProvider.loadSuggestedUsers: $e');
    }
  }

  /// Updates the follow status in both searchResults and suggestedUsers optimistically.
  void _markFollowSent(String targetUid) {
    _searchResults = _searchResults.map((user) {
      if ((user['uid']?.toString() ?? '') != targetUid) return user;
      return {...user, 'followStatus': 'pending'};
    }).toList();
    _suggestedUsers = _suggestedUsers.map((user) {
      if ((user['uid']?.toString() ?? '') != targetUid) return user;
      return {...user, 'followStatus': 'pending'};
    }).toList();
    notifyListeners();
  }
}
