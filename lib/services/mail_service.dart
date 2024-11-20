import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../models/mail.dart';

final MailService mailService = MailService();

class MailService {

  Future<void> sendEmail(Mail newMail) async{
    await FirebaseFirestore.instance
        .collection("mails")
        .doc(newMail.uid)
        .set(newMail.toJson());
  }

  Future<List<Mail>> fetchMails() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("mails")
        .orderBy("sentDate", descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      return Mail.fromJson(doc.data());
    }).toList();
  }

  Stream<List<Mail>> streamMailsByUser(String userEmail) {
    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .snapshots();

    return Rx.combineLatest3(
      toStream,
      ccStream,
      bccStream,
          (QuerySnapshot toSnapshot, QuerySnapshot ccSnapshot, QuerySnapshot bccSnapshot) {
        final uniqueMails = <Mail>{};

        void addMails(QuerySnapshot snapshot) {
          for (final doc in snapshot.docs) {
            final mail = Mail.fromJson(doc.data() as Map<String, dynamic>);
            if (!uniqueMails.any((m) => m.uid == mail.uid)) {
              uniqueMails.add(mail);
            }
          }
        }

        addMails(toSnapshot);
        addMails(ccSnapshot);
        addMails(bccSnapshot);

        return uniqueMails.toList()..sort((a, b) => b.sentDate!.compareTo(a.sentDate!));
      },
    );
  }

  bool isPrimaryMail(Mail mail) {
    return !mail.isSpam && !mail.isDelete && !mail.isHidden;
  }

  bool isSentMail(Mail mail) {
    return mail.sentDate != null && !mail.isDraft && !mail.isDelete;
  }

  bool isPromotionalMail(Mail mail) {
    return mail.labels?.contains('Promotion') ?? false;
  }

  bool isSocialMail(Mail mail) {
    return mail.labels?.contains('Social') ?? false;
  }

  bool isUpdateMail(Mail mail) {
    return mail.labels?.contains('Update') ?? false;
  }

}