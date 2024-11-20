import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/utils/image_default.dart';
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
        photoURL: DEFAULT_AVATAR, displayName: newUser.name);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(newUser.toJson());

    await user.reload();
  }

  Future<MyUser?> checkLogin(String email, String password) async {
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
      final response = await http.get(Uri.parse('https://us-central1-gtv-mail.cloudfunctions.net/generateCustomToken?uid=$uid'));
      // final response = await http.get(Uri.parse(
      //     'http://10.0.2.2:5001/gtv-mail/us-central1/generateCustomToken?uid=$uid'));

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

  Future<List<MyUser>> fetchUsers() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    return querySnapshot.docs.map((doc) {
      return MyUser.fromJson(doc.data());
    }).toList();
  }

  Future<Map<String, MyUser>> fetchSenderCached() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    return Map.fromIterable(querySnapshot.docs,
        key: (doc) => doc['email'] as String,
        value: (doc) => MyUser.fromJson(doc.data()));
  }

  Future<MyUser> getUserByID(String id) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .get();

    if (docSnapshot.exists) {
      return MyUser.fromJson(docSnapshot.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  Future<void> updateUser(MyUser user) async {
    await getCurrentUser()!.updateProfile(displayName: user.name, photoURL: user.imageUrl);
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update(user.toJson());
  }
}
