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
import 'package:flutter_native_splash/flutter_native_splash.dart';


import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.initialTheme});

  AdaptiveThemeMode initialTheme;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  void initialization() async {
    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    super.initState();
    initialization();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      debugShowFloatingThemeButton: false,
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: widget.initialTheme,
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
