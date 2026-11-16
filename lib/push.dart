import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';

class PushNotifications {
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      // Google masih menerima targeting token; API pengganti (FID) belum
      // didukung jalur kirim HTTP v1 yang dipakai server.
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((token) {
        api.registerDeviceToken(token).catchError((Object error) {
          debugPrint('Failed to refresh push token: $error');
        });
      });

      _ready = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to initialise push notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> sync() async {
    await init();
    if (!_ready) return;

    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await api.registerDeviceToken(token);
    } catch (error, stackTrace) {
      debugPrint('Failed to register push token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> logout() async {
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete push token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
