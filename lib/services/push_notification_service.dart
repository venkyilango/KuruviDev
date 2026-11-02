import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background/terminated message handler.
///
/// Must be a top-level function — the Flutter engine spins up a fresh isolate
/// for it, so nothing from the running app is in scope. Firebase is already
/// initialised by the plugin before this runs.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[push] background message: ${message.messageId}');
}

/// Device-side push setup: permission, token registration, and showing
/// notifications that arrive while the app is in the foreground.
///
/// Sending is done from the Firebase Console (or later, a server) — this class
/// only handles the receiving end.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Android needs an explicit channel or heads-up notifications are silent.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kuruvi_default',
    'General Notifications',
    description: 'Messages, trip updates and requests from Kuruvi.',
    importance: Importance.high,
  );

  static bool _initialised = false;
  static bool _refreshListenerAttached = false;

  /// Call once after `Firebase.initializeApp`.
  static Future<void> initialise() async {
    if (_initialised) return;
    _initialised = true;

    await _setUpLocalNotifications();
    await requestPermission();

    // Foreground messages don't raise a notification by themselves on Android,
    // so mirror them through flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Taps that opened the app from the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Tap that launched the app from terminated.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);

    await _registerToken();

    // `initialise` runs before anyone has signed in, and `_saveToken` is a
    // no-op while signed out — so without this a user who signs up or logs in
    // during this session never gets a token stored, and receives no pushes
    // until the next cold start. Re-register whenever a user appears.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _registerToken();
    });
  }

  /// Asks the OS for notification permission.
  ///
  /// iOS always prompts; Android only from API 33 (Tiramisu) onward, where it
  /// needs POST_NOTIFICATIONS in the manifest.
  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> _setUpLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // handled by FirebaseMessaging above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[push] local notification tapped: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Let iOS show banners while the app is in the foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  static void _handleTap(RemoteMessage message) {
    // Routing hook: inspect message.data here once the payload shape is
    // decided (e.g. {'type': 'chat', 'chatId': '...'}) and navigate.
    debugPrint('[push] opened from notification: ${message.data}');
  }

  /// Saves the FCM token on the signed-in user so a server can target them.
  /// Safe to call when signed out — it simply does nothing.
  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);

      // Tokens rotate; keep Firestore in step. Attached once — this method now
      // runs again on every sign-in, and a second listener would double-write.
      if (!_refreshListenerAttached) {
        _refreshListenerAttached = true;
        _messaging.onTokenRefresh.listen(_saveToken);
      }
    } catch (e) {
      debugPrint('[push] could not get FCM token: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[push] could not save FCM token: $e');
    }
  }

  /// Call this on sign-out so the device stops receiving that user's pushes.
  static Future<void> removeTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[push] could not remove FCM token: $e');
    }
  }

  /// Registers the token after a fresh sign-in.
  static Future<void> onSignedIn() => _registerToken();
}
