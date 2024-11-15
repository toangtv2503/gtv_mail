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
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.matchedLocation == '/';

    if (isLoggedIn && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      name: 'home',
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData && FirebaseAuth.instance.currentUser!.photoURL != null) {
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
        if (draftParam == 'new') {
          return ComposeMail(isDraft: false);
        } else if (draftParam != null) {
          return ComposeMail(draftId: draftParam);
        } else {
          return ComposeMail(isDraft: false);
        }
      },
    ),
  ],
);