import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as timezone;

/// Service for handling local notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initializes the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /// Initializes local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Don't request immediately to avoid crashes
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );
    } catch (e) {
      print('Error initializing local notifications: $e');
      // Don't rethrow - allow app to continue without notifications
    }
  }

  /// Handles local notification taps
  void _handleLocalNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    
    // Handle notification tap based on payload
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Handle different notification types
        _handleNotificationData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Handles notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'movie_recommendation':
        // Navigate to movie detail
        print('Navigate to movie: ${data['movieId']}');
        break;
      case 'new_release':
        // Navigate to new releases
        print('Navigate to new releases');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Shows a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'popmatch_channel',
      'PopMatch Notifications',
      channelDescription: 'Notifications from PopMatch app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload ?? json.encode(data),
    );
  }

  /// Shows a scheduled notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'popmatch_scheduled_channel',
      'PopMatch Scheduled Notifications',
      channelDescription: 'Scheduled notifications from PopMatch app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime for the current timezone
    final tz = timezone.getLocation('America/New_York'); // Default timezone
    final tzScheduledDate = timezone.TZDateTime.from(scheduledDate, tz);
    
    await _localNotifications.zonedSchedule(
      scheduledDate.millisecondsSinceEpoch ~/ 1000, // This parameter is for the ID, not the date
      title,
      body,
      tzScheduledDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: data != null ? json.encode(data) : null,
    );
  }

  /// Shows a movie recommendation notification
  Future<void> showMovieRecommendation({
    required String movieTitle,
    required String movieId,
    String? reason,
  }) async {
    await showNotification(
      title: 'Movie Recommendation',
      body: reason != null 
          ? 'Check out "$movieTitle" - $reason'
          : 'Check out "$movieTitle"',
      data: {
        'type': 'movie_recommendation',
        'movieId': movieId,
        'movieTitle': movieTitle,
      },
    );
  }

  /// Shows a new release notification
  Future<void> showNewReleaseNotification({
    required String movieTitle,
    required String movieId,
  }) async {
    await showNotification(
      title: 'New Release',
      body: '"$movieTitle" is now available!',
      data: {
        'type': 'new_release',
        'movieId': movieId,
        'movieTitle': movieTitle,
      },
    );
  }

  /// Shows a reminder notification
  Future<void> showReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await scheduleNotification(
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      data: {
        'type': 'reminder',
      },
    );
  }

  /// Cancels all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancels a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Gets notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];
    
    return notifications.map((notification) {
      try {
        return json.decode(notification) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).toList();
  }

  /// Saves notification to history
  Future<void> saveNotificationToHistory(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];
    
    notifications.add(json.encode(notification));
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications.removeRange(0, notifications.length - 50);
    }
    
    await prefs.setStringList('notifications', notifications);
  }

  /// Clears notification history
  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }
} 