import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/utils/otp_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _registerKey = GlobalKey<FormState>();
  String? username;
  String? phoneNumber;
  String? password;
  String? confirmPassword;

  var _verificationId;

  Future<bool> _checkPhoneNumberExists(String phone) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  void _showPhoneExistsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Phone Number Exists'),
          content: const Text(
              'Your phone number already exists. Please use a different phone number.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _registerKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Register', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 20),

          TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your username';
              } else if (value!.length < 0 || value.length > 256) {
                return 'Your username so long';
              }
              return null;
            },
            onSaved: (value) => username = value,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),

          // Phone Number Field
          IntlPhoneField(
            flagsButtonMargin: const EdgeInsets.only(left: 8),
            showDropdownIcon: false,
            disableLengthCheck: true,
            initialCountryCode: "VN",
            decoration: const InputDecoration(
              labelText: 'Phone Number',
            ),
            languageCode: "vn",
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            invalidNumberMessage: 'Invalid phone number',
            validator: (value) {
              if (value?.number.isEmpty ?? true) {
                return 'Please enter your phone number';
              } else if (value!.number.length < 9) {
                return 'Phone number must be at least 9 digits';
              } else if (!value.number.startsWith('0') &&
                  value.number.length == 10) {
                return 'Invalid phone number';
              } else if (value.number.startsWith('0') &&
                  value.number.length == 10) {
                return null;
              } else if (!value.number.startsWith('0') &&
                  value.number.length == 9) {
                return null;
              } else {
                return 'Invalid phone number';
              }
            },
            onSaved: (value) {
              if (value!.number.startsWith('0')) {
                phoneNumber = value.completeNumber;
              } else if (value.number.length == 9) {
                phoneNumber = '+84${value.number}';
              }
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),

          // Password Field
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your password';
              } else if (value!.length < 0 || value.length > 256) {
                return 'Your password so long';
              }
              return null;
            },
            onSaved: (value) => password = value,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),

          // Confirm Password Field
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.check),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              }
              return null;
            },
            onSaved: (value) => confirmPassword = value,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),

          // Register Button
          ElevatedButton(
            onPressed: () async {
              if (_registerKey.currentState!.validate()) {
                _registerKey.currentState!.save();
                bool phoneExists = await _checkPhoneNumberExists(phoneNumber!);
                if (phoneExists) {
                  _showPhoneExistsDialog();
                } else {
                  var phone = phoneNumber!.length > 12 ? phoneNumber?.replaceFirst("0", '') : phoneNumber;
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: phone,
                    verificationCompleted: (_) {},
                    verificationFailed: (FirebaseAuthException e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Verification Failed"),
                          content: Text("An error occurred. Please try again after 60s."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("OK"),
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

                      if (credential != null) {
                        print("$credential neeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");



                          UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                          User? user = userCredential.user;

                          if (user != null) {
                            await user.updatePhotoURL(
                                "https://firebasestorage.googleapis.com/v0/b/gtv-mail.firebasestorage.app/o/default_assets%2Fuser_avatar_default.png?alt=media&token=7c5f76fb-ce9f-465f-ac75-1e2212c58913");
                            await user.updateDisplayName(username);
                            await user.updatePassword(password.toString());
                            await user.reload();

                            User currentUser = FirebaseAuth.instance.currentUser!;

                            MyUser newUser = MyUser(
                              uid: currentUser.uid,
                              name: currentUser.displayName,
                              phone: currentUser.phoneNumber,
                              imageUrl: currentUser.photoURL,
                              password: BCrypt.hashpw(password.toString(), BCrypt.gensalt()),
                            );

                            await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).set(newUser.toJson());
                            Navigator.pop(context, true);
                          }
                        }
                                          },
                    codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
                  );
                }
              }
            },
            child: const Text('Register'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
