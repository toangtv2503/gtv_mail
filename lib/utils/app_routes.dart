import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gtv_mail/screens/compose_mail.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';

final GoRouter appRouter = GoRouter(
  errorBuilder: (BuildContext context, GoRouterState state) {
    return NotFoundScreen(url: state.uri.path,);
  },
  routes: <RouteBase>[
    GoRoute(
      name: 'home',
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
    ),
    GoRoute(
      name: 'compose',
      path: '/compose',
      builder: (BuildContext context, GoRouterState state) {
        final draftParam = state.uri.queryParameters['draft'];
        final email = state.extra as String?;
        if (draftParam == 'new') {
          return ComposeMail(isDraft: false, from: email,);
        } else if (draftParam != null) {
          return ComposeMail(draftId: draftParam, from: email,);
        } else {
          return ComposeMail(isDraft: false, from: email,);
        }
      },
    ),
  ],
);