import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging? _message;
  late AndroidNotificationChannel _channel;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  static final NotificationService _singleton = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => _singleton;

  initialize() async {
    await Firebase.initializeApp();
    getInstance();
    _printFCMToken();
    if (!kIsWeb) {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      _androidNotificationSettings();
      _iOSNoticationSettings();
    }
    FirebaseMessaging.onMessage.listen(_foregroundListner);
    FirebaseMessaging.onMessageOpenedApp.listen(_backgroundListner);
    FirebaseMessaging.onBackgroundMessage(_terminatedAppListner);
  }

  FirebaseMessaging getInstance() {
    _message ??= FirebaseMessaging.instance;
    return _message!;
  }

  _printFCMToken() async {
    String token = await _message!.getToken() ?? "";
    log("DEVICE FCM TOKEN=> $token");
  }

  _androidNotificationSettings() async {
    _channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  _iOSNoticationSettings() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  _foregroundListner(RemoteMessage message) {
    log('Notification in foreground state with id ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: 'launch_background',
          ),
        ),
      );
    }
  }

  _backgroundListner(RemoteMessage message) {
    log('Notification in background state with id ${message.messageId}');
  }
}

Future<void> _terminatedAppListner(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Notification in killed app state with id ${message.messageId}');
}
