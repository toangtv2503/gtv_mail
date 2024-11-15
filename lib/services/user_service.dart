import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:http/http.dart' as http;

final UserService userService = UserService();

class UserService {
  User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  Future<bool> checkPhoneNumberExists(String phone) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> checkEmailExisted(String email) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> registerAccount(MyUser newUser, User user) async {
    await user.updateProfile(
        photoURL:
        'https://firebasestorage.googleapis.com/v0/b/gtv-mail.firebasestorage.app/o/default_assets%2Fuser_avatar_default.png?alt=media&token=7c5f76fb-ce9f-465f-ac75-1e2212c58913',
        displayName: newUser.name);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(newUser.toJson());

    await user.reload();
  }

  Future<MyUser?> checkLogin(String email,String password) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data() as Map<String, dynamic>;
      if (BCrypt.checkpw(password, user['password'])) {
        return MyUser.fromJson(user);
      }
      return null;
    } else {
      return null;
    }
  }

  Future<void> signInWithCustomToken(String uid) async {
    try {
      // final response = await http.get(Uri.parse('https://us-central1-gtv-mail.cloudfunctions.net/generateCustomToken?uid=$uid'));
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:5001/gtv-mail/us-central1/generateCustomToken?uid=$uid'));

      if (response.statusCode == 200) {
        final customToken = json.decode(response.body)['customToken'];

        UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCustomToken(customToken);

        print("Successfully signed in with UID: ${userCredential.user?.uid}");
      } else {
        print("Failed to get custom token from server: ${response.body}");
      }
    } catch (e) {
      print("Error during sign-in: $e");
    }
  }
}