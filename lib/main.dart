import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safehome/App/App.dart';
import 'package:safehome/firebase_options.dart';
import 'package:safehome/services/local_notifications_service.dart';
import 'package:safehome/services/push_notifications_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Future.wait([
    PushNotificationsServices.init(),
    LocalNotificationService.init(),
  ]);
  runApp(const SafeHome());
}
