import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:gtv_mail/services/mail_service.dart';

final NotificationService notificationService = NotificationService();

class NotificationService {
  Future<void> updateBadge(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("mails")
        .where('to', arrayContains: email)
        .where('isRead', isEqualTo: false)
        .get();

    await FlutterAppBadgeControl.updateBadgeCount(querySnapshot.size);
  }
}