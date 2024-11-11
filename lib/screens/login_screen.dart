import 'package:flutter/material.dart';
import 'package:gtv_mail/components/login_form.dart';
import 'package:gtv_mail/components/register_form.dart';

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
            height: 156,
          ),
          const Row(),
          ClipOval(
            child: Image.asset(
              "assets/images/logo.png",
              height: 154,
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          Text(
            "GTV Mail",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _handleSignIn(context),
            child: const Text("Đăng nhập"),
          ),
          TextButton(
            onPressed: () => _handleSignUp(context),
            child: const Text("Đăng ký"),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      )),
    );
  }
}
