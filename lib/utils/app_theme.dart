import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const appBackgroundColorLight = Color(0xFFFFFFFF);
  static const colorPrimaryLight = Color(0xFFFFFFFF);
  static const iconColorPrimaryLight = Color(0xFF3D4043);
  static const textColorLight = Color(0xFF202124);

  // Dark Theme Colors
  static const appBackgroundColorDark = Color(0xFF202124);
  static const colorPrimaryDark = Color(0xFF36373A);
  static const iconColorPrimaryDark = Color(0xFFE8E9EC);
  static const textColorDark = Color(0xFFE8E9EC);

  // Additional Colors
  static const blackColor = Color(0xFF000000);
  static const whiteColor = Color(0xFFFFFFFF);
  static const greyColor = Color(0xFF808080);

  static const redColor = Color(0xFFDB4437);
  static const greenColor = Color(0xFF0F9D58);
  static const yellowColor = Color(0xFFF4B400);
  static const blueColor = Color(0xFF4285F4);

  // Light Theme Data
  static ThemeData lightTheme = ThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      prefixIconColor: iconColorPrimaryLight,
      suffixIconColor: iconColorPrimaryLight,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: blueColor,
        fixedSize: const Size(double.maxFinite, 50),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    ),
    useMaterial3: false,
    brightness: Brightness.light,
    primaryColor: colorPrimaryLight,
    scaffoldBackgroundColor: appBackgroundColorLight,
    primaryIconTheme: const IconThemeData(color: iconColorPrimaryLight),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColorLight),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColorLight),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColorLight),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColorLight),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColorLight),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorLight),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColorLight),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColorLight),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColorLight),
      bodyLarge: TextStyle(fontSize: 16, color: textColorLight),
      bodyMedium: TextStyle(fontSize: 14, color: textColorLight),
      bodySmall: TextStyle(fontSize: 12, color: textColorLight),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColorLight),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColorLight),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColorLight),
    ),
    appBarTheme: const AppBarTheme(
      color: colorPrimaryLight,
      iconTheme: IconThemeData(color: iconColorPrimaryLight),
    ),
    iconTheme: const IconThemeData(color: iconColorPrimaryLight),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        side: const BorderSide(
          width: 0.8,
          color: greyColor,
        ),
        fixedSize: const Size(128, 32),
        textStyle: const TextStyle(color: blueColor)
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: whiteColor,
      foregroundColor: textColorLight,
      elevation: 6.0,
    ),
  );

  // Dark Theme Data
  static ThemeData darkTheme = ThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      prefixIconColor: iconColorPrimaryDark,
      suffixIconColor: iconColorPrimaryDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          fixedSize: const Size(double.maxFinite, 50),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    ),
    useMaterial3: false,
    brightness: Brightness.dark,
    primaryColor: colorPrimaryDark,
    scaffoldBackgroundColor: appBackgroundColorDark,
    primaryIconTheme: const IconThemeData(color: iconColorPrimaryDark),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColorDark),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColorDark),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColorDark),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColorDark),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColorDark),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorDark),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColorDark),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColorDark),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColorDark),
      bodyLarge: TextStyle(fontSize: 16, color: textColorDark),
      bodyMedium: TextStyle(fontSize: 14, color: textColorDark),
      bodySmall: TextStyle(fontSize: 12, color: textColorDark),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColorDark),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColorDark),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColorDark),
    ),
    appBarTheme: const AppBarTheme(
      color: colorPrimaryDark,
      iconTheme: IconThemeData(color: iconColorPrimaryDark),
    ),
    iconTheme: const IconThemeData(color: iconColorPrimaryLight),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          side: const BorderSide(
            width: 0.8,
            color: whiteColor,
          ),
          fixedSize: const Size(128, 32),
          textStyle: const TextStyle(color: blueColor)
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: colorPrimaryDark,
      foregroundColor: textColorDark,
      elevation: 6.0,
    ),
  );
}
