import 'dart:convert';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtv_mail/utils/app_fonts.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_theme.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with WidgetsBindingObserver {
  late SharedPreferences prefs;

  void init() async {
    prefs = await SharedPreferences.getInstance();

    WidgetsBinding.instance.addObserver(this);
    var status =
        await NotificationPermissions.getNotificationPermissionStatus();

    setState(() {
      // general
      isTurnOnNotification = status == PermissionStatus.granted;

      // theme
      currentSettingTheme = prefs.getString('setting_theme') ?? 'Default';
      selectedSettingTheme =
          settingTheme[currentSettingTheme] ?? DevicePlatform.device;

      currentDialogTheme = prefs.getString('dialog_theme') ?? 'Default';
      selectedDialogTheme =
          dialogTheme[currentDialogTheme] ?? AdaptiveStyle.adaptive;

      currentLightTheme =
          jsonDecode(prefs.getString(AdaptiveTheme.prefKey)!)['theme_mode'] ??
              2;

      //font
      currentFontSize = prefs.getString('default_font_size') ?? 'Medium';
      currentFontFamily = prefs.getString('default_font_family') ?? 'Arial';
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    isTurnOnNotification =
        await NotificationPermissions.getNotificationPermissionStatus() ==
            PermissionStatus.granted;
    setState(() {});
  }

  // general
  bool isTurnOnNotification = false;

  // theme
  DevicePlatform selectedSettingTheme = DevicePlatform.device;
  String currentSettingTheme = 'Default';

  AdaptiveStyle selectedDialogTheme = AdaptiveStyle.adaptive;
  String currentDialogTheme = 'Default';

  int currentLightTheme = 2;

  //font
  String currentFontSize = "Medium";
  String currentFontFamily = "Arial";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SettingsList(
        applicationType: ApplicationType.both,
        platform: selectedSettingTheme,
        sections: [
          SettingsSection(
            title: const Text('General'),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                leading: Icon(isTurnOnNotification
                    ? Icons.notifications_on
                    : Icons.notifications_off),
                title: const Text('Notifications'),
                initialValue: isTurnOnNotification,
                onToggle: (value) async {
                  var status = await NotificationPermissions
                      .getNotificationPermissionStatus();
                  if (status != PermissionStatus.granted) {
                    var result = await NotificationPermissions
                        .requestNotificationPermissions(
                      iosSettings: const NotificationSettingsIos(
                          alert: true, badge: true, sound: true),
                      openSettings: false,
                    );
                    return;
                  }
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Theme'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.settings_applications),
                title: const Text('Setting theme'),
                value: Text(currentSettingTheme),
                onPressed: (context) async {
                  final result = await showModalActionSheet<String>(
                    context: context,
                    title: 'Setting theme',
                    actions: [
                      const SheetAction(
                        icon: Icons.android,
                        label: 'Android',
                        key: 'Android',
                      ),
                      const SheetAction(
                        icon: Icons.apple,
                        label: 'iOS',
                        key: 'iOS',
                      ),
                      const SheetAction(
                        icon: Icons.web,
                        label: 'Web',
                        key: 'Web',
                      ),
                      const SheetAction(
                        icon: Icons.settings_backup_restore,
                        label: 'Default',
                        key: 'Default',
                      ),
                    ],
                  );

                  if (result != null) {
                    prefs.setString('setting_theme', result);
                    setState(() {
                      currentSettingTheme = result;
                      selectedSettingTheme = settingTheme[result]!;
                    });
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.chat),
                title: const Text('Dialog theme'),
                value: Text(currentDialogTheme),
                onPressed: (context) async {
                  final result = await showModalActionSheet<String>(
                    context: context,
                    title: 'Dialog theme',
                    actions: [
                      const SheetAction(
                        icon: Icons.android,
                        label: 'Android',
                        key: 'Android',
                      ),
                      const SheetAction(
                        icon: Icons.apple,
                        label: 'iOS',
                        key: 'iOS',
                      ),
                      const SheetAction(
                        icon: Icons.laptop_mac,
                        label: 'macOS',
                        key: 'macOS',
                      ),
                      const SheetAction(
                        icon: Icons.settings_backup_restore,
                        label: 'Default',
                        key: 'Default',
                      ),
                    ],
                  );

                  if (result != null) {
                    prefs.setString('dialog_theme', result);
                    setState(() {
                      currentDialogTheme = result;
                      selectedDialogTheme = dialogTheme[result]!;

                      AdaptiveDialog.instance.updateConfiguration(
                          macOS: AdaptiveDialogMacOSConfiguration(
                            applicationIcon: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/logo.png',
                              ),
                            ),
                          ),
                          defaultStyle: selectedDialogTheme);
                    });
                  }
                },
              ),
              SettingsTile(
                title: const Text("Light theme"),
                leading: const Icon(Icons.settings_brightness),
                value: Text(
                    ["Light mode", "Dark mode", "System"][currentLightTheme]),
                trailing: AnimatedToggleSwitch<int>.rolling(
                  borderWidth: 0.4,
                  current: currentLightTheme,
                  height: 50,
                  values: const [0, 1, 2],
                  indicatorIconScale: sqrt2,
                  style: ToggleStyle(
                    indicatorColor: Theme.of(context).disabledColor,
                    borderColor: Colors.black,
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onChanged: (i) {
                    switch (i) {
                      case 0:
                        AdaptiveTheme.of(context).setLight();
                      case 1:
                        AdaptiveTheme.of(context).setDark();
                      case 2:
                        AdaptiveTheme.of(context).setSystem();
                    }
                    setState(() => currentLightTheme = i);
                  },
                  iconBuilder: (value, foreground) {
                    return Icon(
                      [
                        Icons.light_mode,
                        Icons.dark_mode,
                        Icons.brightness_auto
                      ][value],
                      color: Theme.of(context).primaryIconTheme.color,
                    );
                  },
                  loading: false,
                ),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Font'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.text_fields),
                title: const Text('Font size'),
                value: Text(currentFontSize),
                onPressed: (context) async {
                  final result = await showModalActionSheet<String>(
                    context: context,
                    title: 'Font size',
                    actions: [
                      const SheetAction(
                        label: 'Small',
                        key: 'Small',
                      ),
                      const SheetAction(
                        label: 'Normal',
                        key: 'Normal',
                      ),
                      const SheetAction(
                        label: 'Medium',
                        key: 'Medium',
                      ),
                      const SheetAction(
                        label: 'Large',
                        key: 'Large',
                      ),
                      const SheetAction(
                        label: 'Huge',
                        key: 'Huge',
                      ),
                    ],
                  );

                  if (result != null) {
                    prefs.setString('default_font_size', result);
                    setState(() {
                      currentFontSize = result;
                    });
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.type_specimen),
                title: const Text('Font Family'),
                value: Text(currentFontFamily),
                onPressed: (context) async {
                  final result = await showModalActionSheet<String>(
                      context: context,
                      title: 'Font Family',
                      actions: appFonts.values
                          .map((font) => SheetAction(label: font, key: font))
                          .toList());

                  if (result != null) {
                    prefs.setString('default_font_family', result);
                    setState(() {
                      currentFontFamily = result;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
