import 'package:gtv_mail/utils/image_default.dart';

class MyUser {
  String? uid;
  String? name;
  String? phone;
  String? email;
  String? imageUrl;
  String? password;
  bool isEnable2FA;

  MyUser({this.uid, this.name, this.phone, this.imageUrl, this.password, this.email, this.isEnable2FA = false});

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'password': password,
      'isEnable2FA': isEnable2FA,
    };
  }

  factory MyUser.fromJson(Map<String, dynamic> json) {
    return MyUser(
      uid: json['uid'] ?? 'Default UID',
      name: json['name'] ?? 'Anonymous',
      phone: json['phone'],
      email: json['email'],
      imageUrl: json['imageUrl'] ?? DEFAULT_AVATAR,
      password: json['password'],
      isEnable2FA : json['isEnable2FA'] ?? false
    );
  }
}