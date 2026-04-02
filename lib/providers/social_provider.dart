import 'package:flutter/foundation.dart';
import '../models/follow_edge.dart';
import '../models/social_activity.dart';
import '../models/social_privacy_settings.dart';
import '../services/social_service.dart';
import '../utils/firebase_error_message.dart';

class SocialProvider with ChangeNotifier {
  final SocialService _socialService = SocialService.instance;

  bool _isLoading = false;
  String? _error;
  List<FollowEdge> _incomingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<SocialActivity> _friendsFeed = [];
  SocialPrivacySettings _privacy = const SocialPrivacySettings();

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FollowEdge> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<SocialActivity> get friendsFeed => _friendsFeed;
  SocialPrivacySettings get privacy => _privacy;

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
    _searchResults = _searchResults.map((user) {
      if ((user['uid']?.toString() ?? '') != targetUid) return user;
      return {
        ...user,
        'followStatus': 'pending',
      };
    }).toList();
    notifyListeners();
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
}
