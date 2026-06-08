import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/follow_edge.dart';
import '../models/social_activity.dart';
import '../models/social_privacy_settings.dart';
import 'firebase_config.dart';

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Matches [functions/index.js] callable region (`us-central1`).
  FirebaseFunctions get _functions {
    if (!FirebaseConfig.isEnabled) {
      return FirebaseFunctions.instance;
    }
    return FirebaseFunctions.instanceFor(
      app: Firebase.app(),
      region: 'us-central1',
    );
  }

  String? get _currentUid {
    if (!FirebaseConfig.isEnabled) return null;
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  /// Forces a token refresh so the Firebase SDK has a valid cached token before any
  /// callable or Firestore request. Using forceRefresh=true prevents stale/expired
  /// tokens from being sent when the session is restored from persistence at startup.
  Future<void> ensureAuthReadyBeforeFirestore() async {
    if (!FirebaseConfig.isEnabled) return;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true);
    } catch (_) {
      // Token refresh failed; Firestore/callables will still run but may get permission errors.
    }
  }

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    if (!FirebaseConfig.isEnabled) return;
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSocialPrivacy(SocialPrivacySettings settings) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('privacy')
        .doc('settings')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Future<SocialPrivacySettings> getSocialPrivacy() async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) {
      return const SocialPrivacySettings();
    }
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('privacy')
        .doc('settings')
        .get();
    return SocialPrivacySettings.fromMap(doc.data());
  }

  Future<void> sendFollowRequest(String targetUid) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null || uid == targetUid) return;
    final callable = _functions.httpsCallable('sendFollowRequest');
    await callable.call({'targetUid': targetUid});
  }

  Future<void> respondToFollowRequest({
    required String requesterUid,
    required bool accept,
  }) async {
    if (!FirebaseConfig.isEnabled || _currentUid == null) return;
    final callable = _functions.httpsCallable('respondToFollowRequest');
    await callable.call({
      'requesterUid': requesterUid,
      'accept': accept,
    });
  }

  Future<void> unfollow(String targetUid) async {
    if (!FirebaseConfig.isEnabled || _currentUid == null) return;
    final callable = _functions.httpsCallable('unfollowUser');
    await callable.call({'targetUid': targetUid});
  }

  Future<List<FollowEdge>> getIncomingRequests() async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('incomingRequests')
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return FollowEdge.fromJson({
        'followerUid': data['followerUid'],
        'followeeUid': uid,
        'status': data['status'],
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null || query.trim().isEmpty) return [];
    final callable = _functions.httpsCallable('searchUsers');
    final result = await callable.call({'query': query.trim()});
    final list = (result.data as List?) ?? [];
    return list.cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Dev-only: seeds demo friends + activity for the signed-in user so the
  /// social surfaces can be tested without recruiting real users. Throws if
  /// Firebase is off; the backend rejects it unless DEV_SEED_ENABLED=true.
  Future<void> devSeedSocial() async {
    if (!FirebaseConfig.isEnabled || _currentUid == null) {
      throw StateError('Firebase is not enabled (dev/local mode).');
    }
    final callable = _functions.httpsCallable('devSeedSocial');
    await callable.call(<String, dynamic>{});
  }

  Future<void> recordActivity({
    required SocialItemType itemType,
    required String itemId,
    required SocialActivityType activityType,
  }) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return;
    try {
      final callable = _functions.httpsCallable('recordSocialActivity');
      await callable.call({
        'itemType': itemType.name,
        'itemId': itemId,
        'activityType': activityType.name,
      });
    } catch (e) {
      debugPrint('recordActivity failed: $e');
    }
  }

  Future<List<SocialActivity>> getFriendsFeed({int limit = 40}) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return [];
    try {
      final callable = _functions.httpsCallable('getFriendsFeed');
      final result = await callable.call({'limit': limit});
      final list = (result.data as List?) ?? [];
      return list
          .cast<Map>()
          .map((m) => SocialActivity.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unauthenticated') return [];
      rethrow;
    }
  }

  // ---- Realtime streams (client-side, for in-app/local notifications while
  // the app is alive). Return null when Firebase is off / not signed in.

  /// Live snapshots of the signed-in user's incoming follow requests
  /// (`users/{uid}/incomingRequests`).
  Stream<QuerySnapshot<Map<String, dynamic>>>? incomingRequestsStream() {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('incomingRequests')
        .snapshots();
  }

  /// Live snapshots of follow edges where the signed-in user is the follower —
  /// used to detect when a request the user sent gets accepted.
  Stream<QuerySnapshot<Map<String, dynamic>>>? outgoingEdgesStream() {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return null;
    return _db
        .collection('followEdges')
        .where('followerUid', isEqualTo: uid)
        .snapshots();
  }

  // ---- User profile lookups (client-side reads; firestore.rules allow any
  // signed-in user to read users/{uid}). Cached in-memory to avoid repeat reads.
  final Map<String, Map<String, dynamic>> _profileCache = {};

  /// Reads a single user profile doc. Returns null if Firebase is off, the uid
  /// is empty, or the doc is missing. Results are cached.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (!FirebaseConfig.isEnabled || uid.isEmpty) return null;
    if (_profileCache.containsKey(uid)) return _profileCache[uid];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      final profile = <String, dynamic>{
        'uid': data['uid'] ?? uid,
        'displayName': data['displayName'] ?? '',
        'email': data['email'] ?? '',
        'photoURL': data['photoURL'] ?? '',
      };
      _profileCache[uid] = profile;
      return profile;
    } catch (e) {
      debugPrint('getUserProfile($uid) failed: $e');
      return null;
    }
  }

  /// Batch-resolves profiles for the given uids (deduped). Missing/failed
  /// lookups are simply omitted from the result map.
  Future<Map<String, Map<String, dynamic>>> getUserProfiles(
      List<String> uids) async {
    final result = <String, Map<String, dynamic>>{};
    for (final uid in uids.toSet()) {
      final p = await getUserProfile(uid);
      if (p != null) result[uid] = p;
    }
    return result;
  }

  /// A specific user's recent public activity (client read; rules allow any
  /// signed-in user to read socialActivities). Deliberately omits `orderBy`
  /// (so no composite index is needed) and sorts client-side. Private items
  /// are filtered out.
  Future<List<SocialActivity>> getUserActivities(String uid,
      {int limit = 30}) async {
    if (!FirebaseConfig.isEnabled || uid.isEmpty) return [];
    try {
      final snap = await _db
          .collection('socialActivities')
          .where('actorUid', isEqualTo: uid)
          .limit(100)
          .get();
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        // createdAt is normally an ISO string; coerce defensively so a stray
        // numeric value can't break SocialActivity.fromJson's String? cast.
        data['createdAt'] = data['createdAt']?.toString();
        return SocialActivity.fromJson(data);
      }).where((a) => a.visibility != ActivityVisibility.private).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    } catch (e) {
      debugPrint('getUserActivities($uid) failed: $e');
      return [];
    }
  }

  /// Follow status of the signed-in user toward [targetUid]: one of
  /// `accepted`, `pending`, `declined`, or `notFollowing`.
  Future<String> getFollowStatus(String targetUid) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null || targetUid.isEmpty) {
      return 'notFollowing';
    }
    try {
      final doc =
          await _db.collection('followEdges').doc('${uid}_$targetUid').get();
      if (!doc.exists) return 'notFollowing';
      return (doc.data()?['status']?.toString()) ?? 'notFollowing';
    } catch (e) {
      debugPrint('getFollowStatus($targetUid) failed: $e');
      return 'notFollowing';
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestedUsers({int limit = 10}) async {
    final uid = _currentUid;
    if (!FirebaseConfig.isEnabled || uid == null) return [];
    try {
      final callable = _functions.httpsCallable('getSuggestedUsers');
      final result = await callable.call({'limit': limit});
      final list = (result.data as List?) ?? [];
      return list.cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unauthenticated') return [];
      rethrow;
    }
  }
}
