import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtv_mail/models/user_label.dart';
import 'package:gtv_mail/services/mail_service.dart';

import '../models/mail.dart';

final LabelService labelService = LabelService();

class LabelService {
  Future<UserLabel?> getLabels(String email) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("labels")
          .where('mail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs[0];

        return UserLabel.fromJson(doc.data());
      }

      return null;
    } catch (e) {
      print("Error getting labels: $e");
      return null;
    }
  }

  Future<void> addLabel(UserLabel userLabel) async {
    await FirebaseFirestore.instance
        .collection("labels")
        .doc(userLabel.id)
        .set(userLabel.toJson());
  }

  Future<void> updateLabel(UserLabel userLabel) async {
    await FirebaseFirestore.instance
        .collection("labels")
        .doc(userLabel.id)
        .update(userLabel.toJson());
  }

  Future<void> removeLabel(String email, String label) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("labels")
          .where('mail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs[0];

        var labelMail = (doc['labelMail'] as Map<String, dynamic>).map(
          (key, value) {
            if (value is List<dynamic>) {
              return MapEntry(
                  key, value.map((item) => item.toString()).toList());
            } else {
              return MapEntry(key, <String>[]);
            }
          },
        );

        var labels = List<String>.from(doc['labels'] ?? []);
        if (labels.contains(label)) {
          labels.remove(label);
        }

        if (labelMail.containsKey(label)) {
          labelMail.remove(label);
        }

        await doc.reference.update({
          'labels': labels,
          'labelMail': labelMail,
        });
      }
    } catch (e) {
      print("Error removing label from mail: $e");
    }
  }

  Future<bool> isExistLabel(String email, String label) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("labels")
          .where('mail', isEqualTo: email)
          .where('labels', arrayContains: label)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> editLabelName(String email, String label, String newName) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection("labels")
        .where('mail', isEqualTo: email)
        .where('labels', arrayContains: label)
        .get();

    for (var doc in querySnapshot.docs) {
      List<dynamic> labels = List.from(doc['labels']);

      int index = labels.indexOf(label);
      if (index != -1) {
        labels[index] = newName;

        await doc.reference.update({'labels': labels});
      }
    }
  }

  Future<void> assignLabelToMail(String email, String label, String mailId) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("labels")
          .where('mail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs[0];

        var labelMail = (doc['labelMail'] as Map<String, dynamic>?)?.map(
              (key, value) {
                if (value is List<dynamic>) {
                  return MapEntry(
                      key, value.map((item) => item.toString()).toList());
                } else {
                  return MapEntry(key, <String>[]);
                }
              },
            ) ??
            {};

        if (!labelMail.containsKey(label)) {
          labelMail[label] = [];
        }
        if (!labelMail[label]!.contains(mailId)) {
          labelMail[label]!.add(mailId);
        }

        await doc.reference.update({'labelMail': labelMail});
      }
    } catch (e) {
      print("Error assigning label to mail: $e");
    }
  }

  Future<void> removeLabelFromMail(String email, String label, String mailId) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("labels")
          .where('mail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs[0];

        var labelMail = (doc['labelMail'] as Map<String, dynamic>).map(
          (key, value) {
            if (value is List<dynamic>) {
              return MapEntry(
                  key, value.map((item) => item.toString()).toList());
            } else {
              return MapEntry(key, <String>[]);
            }
          },
        );

        if (labelMail.containsKey(label)) {
          labelMail.forEach((key, value) {
            if (key == label && value.contains(mailId)) {
              value.remove(mailId);
            }
          });

          if (labelMail[label]!.isEmpty) {
            labelMail.remove(label);
          }

          await doc.reference.update({'labelMail': labelMail});
        }
      }
    } catch (e) {
      print("Error removing label from mail: $e");
    }
  }

  Stream<List<Mail>> getMailByLabel(String email, String label) {
    Stream<List<String>> mailIdStream = FirebaseFirestore.instance
        .collection('labels')
        .where('mail', isEqualTo: email)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs[0];
        print("labelMail: ${doc['labelMail']}");

        var labelMail = doc['labelMail'] != null
            ? (doc['labelMail'] as Map<String, dynamic>).map(
                (key, value) {
                  if (value is List<dynamic>) {
                    return MapEntry(
                      key,
                      value.map((item) => item.toString()).toList(),
                    );
                  } else {
                    return MapEntry(key, <String>[]);
                  }
                },
              )
            : {};

        return labelMail[label] != null
            ? List<String>.from(
                labelMail[label]!.map((item) => item.toString()))
            : [];
      }
      return [];
    });

    return mailIdStream.asyncMap((mailIds) async {
      List<Mail> mails = [];
      for (String id in mailIds) {
        try {
          Mail? mail = await mailService.getMailById(id);
          if (mail != null) {
            mails.add(mail);
          }
        } catch (e) {
          print("Error fetching mail with ID $id: $e");
        }
      }
      return mails;
    });
  }
}
