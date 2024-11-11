import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class NotFoundScreen extends StatelessWidget {
  NotFoundScreen({super.key, this.url = ""});
  String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(),
          SizedBox(
            width: 400,
            child: Lottie.asset(
              'assets/lottiefiles/404.json',
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Your requested URL $url was not found",
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 250,
            child: ElevatedButton(
                onPressed: () {
                  GoRouter.of(context).go('/');
                },
                child: const Text("Home")),
          )
        ],
      ),
    );
  }
}
