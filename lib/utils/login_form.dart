import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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

  Future<bool> _checkLogin() async {
    var phone = phoneNumber!.length > 12 ? phoneNumber?.replaceFirst("0", '') : phoneNumber;
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return BCrypt.checkpw(
          password.toString(), snapshot.docs.first['password']);
    } else {
      return false;
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
          IntlPhoneField(
            autofocus: true,
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
                var isValidAccount = await _checkLogin();

                if (isValidAccount) {
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: phoneNumber,
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

                      await FirebaseAuth.instance
                          .signInWithCredential(credential);

                      Navigator.pop(context, true);
                    },
                    codeAutoRetrievalTimeout: (_) {},
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Wrong phone number or password"),
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
