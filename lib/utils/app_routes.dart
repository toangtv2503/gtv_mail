import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';

final GoRouter appRouter = GoRouter(
  errorBuilder: (BuildContext context, GoRouterState state) {
    return NotFoundScreen(url: state.uri.path,);
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
      // routes: <RouteBase>[
      //   GoRoute(
      //     path: 'login',
      //     builder: (BuildContext context, GoRouterState state) {
      //       return const LoginScreen();
      //     },
      //   ),
      // ],
    ),
  ],
);