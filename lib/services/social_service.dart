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

  /// Ensures Auth has propagated an ID token before Firestore reads (avoids permission-denied races).
  Future<void> ensureAuthReadyBeforeFirestore() async {
    if (!FirebaseConfig.isEnabled) return;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken();
    } catch (_) {
      // Token fetch failed; Firestore will still run — caller may see permission-denied.
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
    final callable = _functions.httpsCallable('getFriendsFeed');
    final result = await callable.call({'limit': limit});
    final list = (result.data as List?) ?? [];
    return list
        .cast<Map>()
        .map((m) => SocialActivity.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
