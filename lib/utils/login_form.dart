import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_flags/country_flags.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'country_codes.dart';
import 'otp_dialog.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _loginKey = GlobalKey<FormState>();
  String? phoneNumber;
  String? password;
  bool _isShowPassword = false;
  String? email;

  String isoCode = "VN";
  String dialCode = "+84";
  int? currentIndex;


  @override
  void initState() {
    currentIndex = MyCountry.countries.indexWhere((country) => country.isoCode == isoCode);
    super.initState();
  }

  Future<dynamic> _checkLogin() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data() as Map<String, dynamic>;
      if (BCrypt.checkpw(password!, user['password'])) {
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
      final response = await http.get(Uri.parse('http://10.0.2.2:5001/gtv-mail/us-central1/generateCustomToken?uid=$uid'));

      if (response.statusCode == 200) {
        final customToken = json.decode(response.body)['customToken'];

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);

        print("Successfully signed in with UID: ${userCredential.user?.uid}");
      } else {
        print("Failed to get custom token from server: ${response.body}");
      }
    } catch (e) {
      print("Error during sign-in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _loginKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Login', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            autofocus: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your email';
              } else if (value!.length > 256) {
                return 'Your email so long';
              } else if (!EmailValidator.validate(value)) {
                return "Your email is invalid";
              }
              return null;
            },
            onSaved: (value) => email = value,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isShowPassword = !_isShowPassword;
                    });
                  },
                  icon: !_isShowPassword
                      ? const Icon(Icons.visibility)
                      : const Icon(Icons.visibility_off)),
            ),
            obscureText: !_isShowPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your password';
              }
              return null;
            },
            onSaved: (value) => password = value,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_loginKey.currentState!.validate()) {
                _loginKey.currentState!.save();
                MyUser? user = await _checkLogin();

                if (user != null) {
                  if (user.isEnable2FA) {
                    await FirebaseAuth.instance.verifyPhoneNumber(
                      phoneNumber: user.phone,
                      timeout: const Duration(seconds: 120),
                      verificationCompleted: (_) {},
                      verificationFailed: (FirebaseAuthException e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Verification Failed"),
                            content: const Text("An error occurred. Please try again."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      },
                      codeSent: (String verificationId, int? resendToken) async {
                        var credential = await showDialog(
                          context: context,
                          builder: (context) =>
                              OtpDialog(verificationId: verificationId),
                        );

                        await FirebaseAuth.instance
                            .signInWithCredential(credential);

                        Navigator.pop(context, true);
                      },
                      codeAutoRetrievalTimeout: (_) {},
                    );
                  } else {
                    signInWithCustomToken(user.uid!);
                    Navigator.pop(context);
                  }

                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Wrong email or password"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Sign In'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
