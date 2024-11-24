import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:gtv_mail/services/notification_service.dart';
import 'package:gtv_mail/utils/app_routes.dart';
import 'package:gtv_mail/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  usePathUrlStrategy();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  AdaptiveDialog.instance.updateConfiguration(
    macOS: AdaptiveDialogMacOSConfiguration(
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/logo.png',
        ),
      ),
    ),
    defaultStyle: dialogTheme[prefs.getString('dialog_theme') ?? 'Default'] ??
        AdaptiveStyle.adaptive,
  );

  runApp(MyApp(
    initialTheme: [
      AdaptiveThemeMode.light,
      AdaptiveThemeMode.dark,
      AdaptiveThemeMode.system
    ][jsonDecode(prefs.getString(AdaptiveTheme.prefKey) ?? jsonEncode({'theme_mode': 2}))['theme_mode'] ?? 2],
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.initialTheme});

  AdaptiveThemeMode initialTheme;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      debugShowFloatingThemeButton: true,
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: initialTheme,
      builder: (theme, darkTheme) => MaterialApp.router(
        title: "GTV Mail",
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
