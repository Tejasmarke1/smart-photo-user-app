import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/models.dart';
import '../providers/auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  /// Initialize Firebase Push Notifications
  Future<void> initialize() async {
    try {
      // 1. Request permissions (especially required on iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // 2. Initialize Local Notifications for Foreground alerts
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationClick(details.payload);
        },
      );

      // 3. Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _uploadToken(token);
      });

      // 4. Register current token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _uploadToken(token);
      }

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 6. Handle background/terminated clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(jsonEncode(message.data));
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Notification initialization failed: $e');
      }
    }
  }

  /// Sends device token to backend registry if authenticated
  Future<void> _uploadToken(String token) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.accessToken == null) return;

    try {
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      
      await client.registerDeviceToken(DeviceTokenRegisterRequest(
        token: token,
        deviceType: Platform.isAndroid ? 'android' : 'ios',
        deviceName: Platform.isAndroid ? 'Android Device' : 'iOS Device',
      ));
    } catch (_) {
      // Fail silently in background
    }
  }

  /// Revokes device token on logout
  Future<void> revokeToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated || authState.accessToken == null) return;

      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      await client.unregisterDeviceToken(token);
    } catch (_) {
      // Fail silently
    }
  }

  /// Display a local notification banner when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'lumina_notifications',
      'Lumina Notifications',
      channelDescription: 'Notifications from Lumina platform',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle tap action on notifications (for deep navigation / marketing)
  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    // Parse navigation details and navigate using GoRouter
    // example payload: {"screen": "/album/abc-123"}
  }
}

// Simple JSON encoder/decoder helper
String jsonEncode(Map<String, dynamic> data) {
  var sb = StringBuffer();
  sb.write('{');
  var entries = data.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    sb.write('"${entries[i].key}":"${entries[i].value}"');
    if (i < entries.length - 1) sb.write(',');
  }
  sb.write('}');
  return sb.toString();
}
