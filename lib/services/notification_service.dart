import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gtv_mail/services/mail_service.dart';

final NotificationService notificationService = NotificationService();

class NotificationService {
  Future<void> updateBadge(String email) async {
    final toQuery = FirebaseFirestore.instance
        .collection("mails")
        .where('to', arrayContains: email)
        .where('isRead', isEqualTo: false)
        .get();

    final ccQuery = FirebaseFirestore.instance
        .collection("mails")
        .where('cc', arrayContains: email)
        .where('isRead', isEqualTo: false)
        .get();

    final bccQuery = FirebaseFirestore.instance
        .collection("mails")
        .where('bcc', arrayContains: email)
        .where('isRead', isEqualTo: false)
        .get();

    final results = await Future.wait([toQuery, ccQuery, bccQuery]);

    final uniqueEmails = <String>{};
    for (var querySnapshot in results) {
      for (var doc in querySnapshot.docs) {
        uniqueEmails.add(doc.id);
      }
    }

    await FlutterAppBadgeControl.updateBadgeCount(uniqueEmails.length);
  }

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(
      NotificationResponse notificationResponse) async {}

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/launcher_icon");

    const DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: androidInitializationSettings,
            iOS: iOSInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();


  }

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails("channelId", "channel_Name",
            importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails()
    );

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }


}