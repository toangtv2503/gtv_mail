import 'package:flutter_quill/flutter_quill.dart';

import 'attachment.dart';

class Mail {
  String? uid;
  String? from;
  List<String>? to;
  List<String>? cc;
  List<String>? bcc;
  String? subject;
  Document? body;
  DateTime? sentDate;
  bool isRead;
  bool isDelete;
  bool isStarred;
  bool isHidden;
  bool isSpam;
  bool isReplyMail;
  bool isImportant;
  List<String>? labels;
  bool isDraft;
  List<Attachment>? attachments;
  List<Mail>? replies;

  Mail({
    this.uid,
    this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject,
    this.body,
    this.sentDate,
    this.isRead = false,
    this.isDelete = false,
    this.isStarred = false,
    this.isHidden = false,
    this.isSpam = false,
    this.isImportant = false,
    this.labels = const [],
    this.isDraft = false,
    this.attachments,
    this.replies,
    this.isReplyMail = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'from': from,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'body': body?.toDelta().toJson(),
      'sentDate': sentDate?.toIso8601String(),
      'isRead': isRead,
      'isDelete': isDelete,
      'isStarred': isStarred,
      'isHidden': isHidden,
      'isSpam': isSpam,
      'isImportant': isImportant,
      'labels': labels,
      'isDraft': isDraft,
      'attachments': attachments?.map((att) => att.toJson()).toList(),
      'replies': replies?.map((rep) => rep.toJson()).toList(),
      'isReplyMail': isReplyMail
    };
  }

  factory Mail.fromJson(Map<String, dynamic> json) {
    return Mail(
      uid: json['uid'] ?? 'Default Mail UID',
      from: json['from'] ?? 'Unknown Sender',
      to: List<String>.from(json['to'] ?? []),
      cc: List<String>.from(json['cc'] ?? []),
      bcc: List<String>.from(json['bcc'] ?? []),
      subject: json['subject'] ?? 'No Subject',
      body: json['body'] != null
          ? Document.fromJson(json['body'])
          : Document(),
      sentDate: json['sentDate'] != null
          ? DateTime.parse(json['sentDate'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isDelete: json['isDelete'] ?? false,
      isStarred: json['isStarred'] ?? false,
      isHidden: json['isHidden'] ?? false,
      isSpam: json['isSpam'] ?? false,
      isImportant: json['isImportant'] ?? false,
      labels: List<String>.from(json['labels'] ?? []),
      isDraft: json['isDraft'] ?? false,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((att) => Attachment.fromJson(att as Map<String, dynamic>))
          .toList(),
      replies: (json['replies'] as List<dynamic>?)
        ?.map((mail) => Mail.fromJson(mail as Map<String, dynamic>))
        .toList(),
      isReplyMail: json['isReplyMail'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Mail && uid != null && uid == other.uid;
  }

  @override
  int get hashCode => uid?.hashCode ?? super.hashCode;
}
