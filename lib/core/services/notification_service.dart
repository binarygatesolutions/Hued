import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Set the background messaging handler early on, as a named top-level function
    if (!Platform.isWindows) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get the token each time the application loads
      _getAndSaveToken();

      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Set foreground notification presentation options for iOS
      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Create notification channel for Android
      if (Platform.isAndroid) {
        final flutterLocalNotificationsPlugin = NotificationService._localNotificationsPlugin;
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        );
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Handle messages while the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Got a message in the foreground!");
        debugPrint("Message data: ${message.data}");
        if (message.notification != null) {
          debugPrint("Message notification: ${message.notification?.title}");
        }
        _showForegroundNotification(message);
      });
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      if (Platform.isIOS) {
        // On iOS, we need to wait for the APNs token to be available before we can get the FCM token
        String? apnsToken;
        int retryCount = 0;
        while (apnsToken == null && retryCount < 5) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint("Waiting for APNS token (attempt ${retryCount + 1})...");
            await Future<void>.delayed(const Duration(seconds: 2));
            retryCount++;
          }
        }

        if (apnsToken != null) {
          String? token = await _messaging.getToken();
          if (token != null) {
            await _saveTokenToFirestore(token);
          }
        } else {
          debugPrint("Failed to get APNS token after retries. FCM token might not be reliable on iOS.");
        }
      } else {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  void _showForegroundNotification(RemoteMessage message) {}

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (_) {}
  }
}
