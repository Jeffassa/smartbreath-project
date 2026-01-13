import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification cliquée : ${details.payload}");
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showCriticalAlert(String status, String recommendation) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_alerts',
      'Alertes Critiques',
      channelDescription: 'Notifications IA prédictives pour urgences',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF0000),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      " ALERTE IA: $status",
      recommendation,
      platformDetails,
      payload: 'critical_alert',
    );
  }

  static Future<void> showPreventiveAlert(String recommendation) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'preventive_alerts',
      'Alertes Préventives',
      channelDescription: 'Alertes basées sur les tendances détectées',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFA500),
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      "PRÉVENTION IA",
      recommendation,
      platformDetails,
      payload: 'preventive_alert',
    );
  }
}