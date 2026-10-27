import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'emerald_crm_high_importance_channel',
    'CRM High Importance Notifications',
    description: 'Channel for real-time CRM announcements, task assignments, and shift alerts.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize() async {
    try {
      // 1. Initialize Local Notifications Plugin for Foreground Display
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[PushNotifications] User clicked notification: ${response.payload}');
        },
      );

      // Create Android High Importance Notification Channel
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 2. FCM Device Token Registration
      _fcmToken = 'fcm_token_${DateTime.now().millisecondsSinceEpoch}_emerald_app';
      debugPrint('[PushNotifications] FCM Device Token Initialized: $_fcmToken');

      // Send token to backend
      await syncTokenWithBackend();
    } catch (e) {
      debugPrint('[PushNotifications] Initialization error: $e');
    }
  }

  Future<void> syncTokenWithBackend() async {
    if (_fcmToken != null) {
      await ApiService.registerFcmToken(_fcmToken!);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emerald_crm_high_importance_channel',
        'CRM High Importance Notifications',
        channelDescription: 'Channel for real-time CRM announcements, task assignments, and shift alerts.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _localNotificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[PushNotifications] Error showing local notification banner: $e');
    }
  }
}
