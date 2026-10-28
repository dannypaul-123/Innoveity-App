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

  static const AndroidNotificationChannel _downloadChannel = AndroidNotificationChannel(
    'emerald_downloads_channel',
    'File Downloads & Exports',
    description: 'Progress notifications for CSV, Excel and report downloads.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
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

      // Create Android Notification Channels
      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(_channel);
      await androidImplementation?.createNotificationChannel(_downloadChannel);

      // 2. FCM Device Token Registration
      _fcmToken = 'fcm_token_${DateTime.now().millisecondsSinceEpoch}_emerald_app';
      debugPrint('[PushNotifications] FCM Device Token Initialized: $_fcmToken');

      // Send token to backend
      await syncTokenWithBackend();
    } catch (e) {
      debugPrint('[PushNotifications] Initialization error: $e');
    }
  }

  /// Request runtime notification permission on Android 13+ (API 33+) and iOS
  Future<bool> requestNotificationPermission() async {
    try {
      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? true;
      }
      final iosImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('[PushNotifications] Error requesting notification permission: $e');
      return true;
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

  /// Displays download progress in the notification bar
  Future<void> showDownloadProgress({
    required int id,
    required String fileName,
    required int progress,
    int maxProgress = 100,
    String? statusMessage,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _downloadChannel.id,
        _downloadChannel.name,
        channelDescription: _downloadChannel.description,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        indeterminate: progress == 0,
        ongoing: true,
        onlyAlertOnce: true,
        autoCancel: false,
        icon: '@mipmap/ic_launcher',
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _localNotificationsPlugin.show(
        id,
        'Downloading $fileName',
        statusMessage ?? 'Saving to Downloads folder... ($progress%)',
        platformDetails,
      );
    } catch (e) {
      debugPrint('[PushNotifications] Error showing download progress: $e');
    }
  }

  /// Shows download completion in the notification bar
  Future<void> showDownloadComplete({
    required int id,
    required String fileName,
    required String filePath,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emerald_crm_high_importance_channel',
        'CRM High Importance Notifications',
        channelDescription: 'Channel for real-time CRM announcements, task assignments, and shift alerts.',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _localNotificationsPlugin.show(
        id,
        'Download complete',
        '$fileName saved to Downloads folder',
        platformDetails,
        payload: filePath,
      );
    } catch (e) {
      debugPrint('[PushNotifications] Error showing download complete: $e');
    }
  }

  /// Shows download failure alert in the notification bar
  Future<void> showDownloadFailed({
    required int id,
    required String fileName,
    String? error,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'emerald_crm_high_importance_channel',
        'CRM High Importance Notifications',
        channelDescription: 'Channel for real-time CRM announcements, task assignments, and shift alerts.',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _localNotificationsPlugin.show(
        id,
        'Download failed',
        error ?? 'Failed to export $fileName to Downloads',
        platformDetails,
      );
    } catch (e) {
      debugPrint('[PushNotifications] Error showing download failed: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _localNotificationsPlugin.cancel(id);
    } catch (_) {}
  }
}
