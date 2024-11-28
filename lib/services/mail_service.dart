import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../models/mail.dart';

final MailService mailService = MailService();

class MailService {
  Future<void> sendEmail(Mail newMail) async {
    await FirebaseFirestore.instance
        .collection("mails")
        .doc(newMail.uid)
        .set(newMail.toJson());
  }

  Future<Mail> getMailById(String id) async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection("mails").doc(id).get();

    if (docSnapshot.exists) {
      return Mail.fromJson(docSnapshot.data()!);
    } else {
      throw Exception('Mail not found');
    }
  }

  Future<void> updateMail(Mail mail) async {
    await FirebaseFirestore.instance
        .collection("mails")
        .doc(mail.uid)
        .update(mail.toJson());
  }

  Future<void> deleteMail(Mail mail) async {
    await FirebaseFirestore.instance.collection("mails").doc(mail.uid).delete();
  }

  Stream<List<Mail>> getAllInboxes(String userEmail) {
    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest3(
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails = {...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getPrimaryMails(String userEmail) {
    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isSpam', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isSpam', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isSpam', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest3(
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails = {...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getSocialPromotionUpdateMails(String userEmail, String category) {
    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isDraft', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isDraft', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isDraft', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest3(
      toStream,
      ccStream,
      bccStream,
      (QuerySnapshot toSnapshot, QuerySnapshot ccSnapshot,
          QuerySnapshot bccSnapshot) {
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails = {...toMails, ...ccMails, ...bccMails}.toList();
        final filteredMails = combinedMails
            .where((mail) =>
                mail.subject?.toLowerCase().contains(category) ?? false)
            .toList();

        return filteredMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getStarredMails(String userEmail) {
    final fromStream = FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isStarred', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isStarred', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isStarred', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isStarred', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest4(
      fromStream,
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot fromSnapshot,
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final fromMails = fromSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails =
            {...fromMails, ...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getHiddenMails(String userEmail) {
    final fromStream = FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: true)
        .snapshots();

    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: true)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: true)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: true)
        .snapshots();

    return Rx.combineLatest4(
      fromStream,
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot fromSnapshot,
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final fromMails = fromSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails =
            {...fromMails, ...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getImportantMails(String userEmail) {
    final fromStream = FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isImportant', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isImportant', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isImportant', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isImportant', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest4(
      fromStream,
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot fromSnapshot,
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final fromMails = fromSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails =
            {...fromMails, ...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getSentMails(String userEmail) {
    return FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isDraft', isEqualTo: false)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final mails =
          snapshot.docs.map((doc) => Mail.fromJson(doc.data())).toList();

      return mails.reversed.toList();
    });
  }

  Stream<List<Mail>> getDraftMails(String userEmail) {
    return FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isDraft', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final mails =
          snapshot.docs.map((doc) => Mail.fromJson(doc.data())).toList();

      return mails.reversed.toList();
    });
  }

  Stream<List<Mail>> getAllMails(String userEmail) {
    final fromStream = FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest4(
      fromStream,
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot fromSnapshot,
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final fromMails = fromSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails =
            {...fromMails, ...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }

  Stream<List<Mail>> getSpamMails(String userEmail) {
    final fromStream = FirebaseFirestore.instance
        .collection("mails")
        .where("from", isEqualTo: userEmail)
        .where('isSpam', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final toStream = FirebaseFirestore.instance
        .collection("mails")
        .where("to", arrayContains: userEmail)
        .where('isSpam', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final ccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("cc", arrayContains: userEmail)
        .where('isSpam', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    final bccStream = FirebaseFirestore.instance
        .collection("mails")
        .where("bcc", arrayContains: userEmail)
        .where('isSpam', isEqualTo: true)
        .where('isDelete', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest4(
      fromStream,
      toStream,
      ccStream,
      bccStream,
      (
        QuerySnapshot fromSnapshot,
        QuerySnapshot toSnapshot,
        QuerySnapshot ccSnapshot,
        QuerySnapshot bccSnapshot,
      ) {
        final fromMails = fromSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final toMails = toSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final ccMails = ccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        final bccMails = bccSnapshot.docs
            .map((doc) => Mail.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        final combinedMails =
            {...fromMails, ...toMails, ...ccMails, ...bccMails}.toList();
        return combinedMails.reversed.toList();
      },
    );
  }
}
