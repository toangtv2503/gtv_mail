import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _isLoading = false;

  late SharedPreferences prefs;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _handleLogin() async {
    if (_loginKey.currentState!.validate()) {
      _loginKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      MyUser? user = await userService.checkLogin(email!, password!);

      if (user != null) {
        if (user.isEnable2FA) {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: user.phone,
            timeout: const Duration(seconds: 120),
            verificationCompleted: (_) {},
            verificationFailed: (FirebaseAuthException e) {
                            showOkAlertDialog(
                context: context,
                title: "Verification Failed",
                message: "An error occurred. Please try again.",
              );
            },
            codeSent:
                (String verificationId, int? resendToken) async {
              var credential = await showDialog(
                context: context,
                builder: (context) =>
                    OtpDialog(verificationId: verificationId),
              );

              await FirebaseAuth.instance
                  .signInWithCredential(credential);

              prefs.setString('email', email!);

              Navigator.pop(context);
            },
            codeAutoRetrievalTimeout: (_) {},
          );
        } else {
          await userService.signInWithCustomToken(user.uid!);

          prefs.setString('email', email!);
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showOkAlertDialog(
          context: context,
          title: "Wrong email or password",
        );
      }
    }
  }

  void _handleForgotPassword() async {

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _handleForgotPassword,
                child: const Text("Forgot password?"),
              )
            ],
          ),
          ElevatedButton(
            onPressed: _handleLogin,
            child: _isLoading
                ? Lottie.asset(
                    'assets/lottiefiles/circle_loading.json',
                    fit: BoxFit.fill,
                  )
                : const Text('Sign In'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
