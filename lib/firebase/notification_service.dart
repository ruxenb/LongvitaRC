import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm;
  final List<RemoteMessage> _messages = [];
  bool _initialized = false;

  NotificationService({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  List<RemoteMessage> get messages => List.unmodifiable(_messages);

  /// Requests permission and attaches listeners once per app process.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
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

  /// Drops the in-app history of the previous user on sign-out.
  void clearHistory() => _messages.clear();

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}
