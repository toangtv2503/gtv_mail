import 'package:flutter_quill/flutter_quill.dart';

class AnswerTemplate {
  String id;
  String mail;
  String? subject;
  Document? body;

  AnswerTemplate({required this.id, required this.mail, this.subject, this.body});

  factory AnswerTemplate.fromJson(Map<String, dynamic> json) {
    return AnswerTemplate(
      id: json['id'] as String,
      mail: json['mail'] as String,
      subject: json['subject'] as String?,
      body: json['body'] != null
          ? Document.fromJson(json['body'])
          : Document(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mail': mail,
      'subject': subject,
      'body': body?.toDelta().toJson(),
    };
  }
}