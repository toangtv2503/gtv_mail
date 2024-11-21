import 'dart:convert';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SharedPreferences prefs;

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      currentSettingTheme = prefs.getString('setting_theme') ?? 'Default';
      selectedSettingTheme =
          _settingTheme[currentSettingTheme] ?? DevicePlatform.device;

      currentDialogTheme = prefs.getString('dialog_theme') ?? 'Default';
      selectedDialogTheme =
          _dialogTheme[currentDialogTheme] ?? AdaptiveStyle.adaptive;

      currentLightTheme = jsonDecode(prefs.getString(AdaptiveTheme.prefKey)!)['theme_mode'] ?? 2;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  final _settingTheme = <String, DevicePlatform>{
    'Default': DevicePlatform.device,
    'Android': DevicePlatform.android,
    'iOS': DevicePlatform.iOS,
    'Web': DevicePlatform.web,
  };
  DevicePlatform selectedSettingTheme = DevicePlatform.device;
  String currentSettingTheme = 'Default';

  final _dialogTheme = <String, AdaptiveStyle>{
    'Default': AdaptiveStyle.adaptive,
    'Android': AdaptiveStyle.material,
    'iOS': AdaptiveStyle.iOS,
    'macOS': AdaptiveStyle.macOS,
  };
  AdaptiveStyle selectedDialogTheme = AdaptiveStyle.adaptive;
  String currentDialogTheme = 'Default';

  int currentLightTheme = 2;

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
                      selectedSettingTheme = _settingTheme[result]!;
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
                      selectedDialogTheme = _dialogTheme[result]!;

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
                value: Text(["Light mode", "Dark mode", "System"][currentLightTheme]),
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
                      case 0: AdaptiveTheme.of(context).setLight();
                      case 1: AdaptiveTheme.of(context).setDark();
                      case 2: AdaptiveTheme.of(context).setSystem();
                    }
                    setState(() => currentLightTheme = i);
                  },
                  iconBuilder: (value, foreground) {
                    return Icon(
                      [Icons.light_mode, Icons.dark_mode, Icons.brightness_auto][value],
                      color: Theme.of(context).primaryIconTheme.color,
                    );
                  },
                  loading: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

