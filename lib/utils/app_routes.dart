import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gtv_mail/screens/auto_answer_mail.dart';
import 'package:gtv_mail/screens/compose_mail.dart';
import 'package:gtv_mail/screens/detail_mail.dart';
import 'package:gtv_mail/screens/recover_password_screen.dart';
import 'package:gtv_mail/screens/search_screen.dart';
import 'package:gtv_mail/screens/setting_screen.dart';
import 'package:gtv_mail/screens/user_profile_screen.dart';

import '../models/mail.dart';
import '../models/user.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';

final GoRouter appRouter = GoRouter(
  errorBuilder: (BuildContext context, GoRouterState state) {
    return NotFoundScreen(
      url: state.uri.path,
    );
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
              if (snapshot.hasData) {
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          );
        },
        routes: [
          GoRoute(
            name: 'compose',
            path: '/compose',
            builder: (BuildContext context, GoRouterState state) {
              final type = state.uri.queryParameters['type'];
              final extra = state.extra as Map<String, dynamic>?;

              switch (type) {
                case 'new':
                  return ComposeMail();
                case 'reply':
                  return ComposeMail(isReply: true, id: extra!['id'],);
                case 'forward':
                  return ComposeMail(isForward: true, id: extra!['id'],);
                case 'draft':
                  return ComposeMail(isDraft: true, id: extra!['id'],);
                default:
                  return NotFoundScreen(
                    url: state.uri.path,
                  );

              }

            },
          ),
          GoRoute(
              name: 'detail',
              path: '/detail/:id',
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>?;
                if (extra == null ||
                    !extra.containsKey('mail') ||
                    !extra.containsKey('senderInfo')) {
                  return NotFoundScreen(
                    url: state.uri.path,
                  );
                }
                return DetailMail(
                  id: state.pathParameters['id']!,
                  mail: extra['mail'] as Mail,
                  sender: extra['senderInfo'] as MyUser,
                );
              }),
          GoRoute(
              name: 'profile',
              path: '/profile/:id',
              builder: (BuildContext context, GoRouterState state) {
                return UserProfileScreen(
                  id: state.pathParameters['id']!,
                );
              }),
          GoRoute(
              name: 'recover-password',
              path: '/recover-password',
              builder: (BuildContext context, GoRouterState state) {
                return const RecoverPasswordScreen();
              }),
          GoRoute(
              name: 'setting',
              path: '/setting',
              builder: (BuildContext context, GoRouterState state) {
                return const SettingScreen();
              }),
          GoRoute(
              name: 'auto-answer-mail',
              path: '/auto-answer-mail/:id',
              builder: (BuildContext context, GoRouterState state) {
                return AutoAnswerMail(
                  userId: state.pathParameters['id']!,
                );
              }),
          GoRoute(
              name: 'search',
              path: '/search/:userMail',
              builder: (BuildContext context, GoRouterState state) {
                return SearchScreen(
                  userMail: state.pathParameters['userMail']!,
                );
              }),
        ]),
  ],
);
