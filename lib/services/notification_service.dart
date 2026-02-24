import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';  // ← AJOUTE ÇA
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, 
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
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_alerts_v1', 
      'Alertes Urgentes SmartBreath',
      channelDescription: 'Notifications IA prioritaires pour détresse respiratoire',
      importance: Importance.max,
      priority: Priority.max,
      color: Colors.red,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),  
      fullScreenIntent: true, 
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical, 
      sound: 'default',
    );

     NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      "ALERTE CRITIQUE : $status",
      recommendation,
      platformDetails,
      payload: 'critical_alert',
    );
  }

  static Future<void> showPreventiveAlert(String recommendation) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'preventive_alerts_v1',
      'Alertes Préventives',
      channelDescription: 'Conseils basés sur l\'analyse prédictive IA',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.orange,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      "SmartBreath : Prévention IA",
      recommendation,
      platformDetails,
      payload: 'preventive_alert',
    );
  }
}