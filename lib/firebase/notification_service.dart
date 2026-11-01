import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm;
  final List<RemoteMessage> _messages = [];

  NotificationService({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  List<RemoteMessage> get messages => List.unmodifiable(_messages);

  Future<void> initialize() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _messages.insert(0, message);
          if (kDebugMode) {
            print('FCM Foreground: ${message.notification?.title}');
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _messages.insert(0, message);
        });
      }
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}
