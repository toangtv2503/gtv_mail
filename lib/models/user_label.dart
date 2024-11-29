class UserLabel {
  String id;
  String mail;
  List<String>? labels;
  Map<String, List<String>>? labelMail;

  UserLabel({
    required this.id,
    required this.mail,
    this.labels,
    this.labelMail,
  });

  factory UserLabel.fromJson(Map<String, dynamic> json) {
    return UserLabel(
      id: json['id'] as String,
      mail: json['mail'] as String,
      labels: json['labels'] != null
          ? List<String>.from(json['labels'].map((item) => item.toString()))
          : null,
      labelMail: json['labelMail'] != null
          ? (json['labelMail'] as Map<String, dynamic>).map(
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
          : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mail': mail,
      'labels': labels,
      'labelMail': labelMail?.map((key, value) => MapEntry(key, value)),
    };
  }
}
