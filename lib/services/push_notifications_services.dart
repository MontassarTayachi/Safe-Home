import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

import 'package:safehome/services/local_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationsServices {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  static Future init() async {
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    log('Push Notifications Token: $token');
    FirebaseMessaging.onBackgroundMessage(handlerBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationService.showBasicNotification(message);
    });
  }

  static connecte() async {
    messaging.subscribeToTopic('all');
    String? token = await messaging.getToken();
    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }
    log('Push Notifications Token: $token');
  }

  static Future<void> handlerBackgroundMessage(RemoteMessage message) async {
    log(message.notification?.title ?? 'No title');
  }
}
