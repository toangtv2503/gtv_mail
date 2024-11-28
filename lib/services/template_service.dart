import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtv_mail/models/answer_template.dart';

final TemplateService templateService = TemplateService();

class TemplateService {
  Future<void> addTemplate(AnswerTemplate template) async {
    await FirebaseFirestore.instance
        .collection("templates")
        .doc(template.id)
        .set(template.toJson());
  }

  Future<void> updateTemplate(AnswerTemplate template) async {
    await FirebaseFirestore.instance
        .collection("templates")
        .doc(template.id)
        .update(template.toJson());
  }

  Future<AnswerTemplate?> getTemplateByEmail(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("templates")
        .where('mail', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docSnapshot = querySnapshot.docs.first;
      return AnswerTemplate.fromJson(docSnapshot.data());
    } else {
      return null;
    }
  }


}
