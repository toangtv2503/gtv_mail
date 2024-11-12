import 'package:flutter/material.dart';
import 'package:gtv_mail/components/login_form.dart';
import 'package:gtv_mail/components/register_form.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _handleSignIn(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: const LoginForm(),
      ),
    );
  }

  void _handleSignUp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: const RegisterForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          const SizedBox(
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  "assets/images/logo.png",
                  height: 42,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                "GTV Mail",
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          SizedBox(
            width: 400,
            child: Lottie.asset(
              'assets/lottiefiles/welcome.json',
              fit: BoxFit.fill,
            ),
          ),
          Text("Send and manage your mails effortlessly.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          SizedBox(
            width: 300,
            child: ElevatedButton(
              onPressed: () => _handleSignIn(context),
              child: const Text("Login"),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            child: ElevatedButton(
              onPressed: () => _handleSignUp(context),
              child: const Text("Register"),
            ),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      )),
    );
  }
}
