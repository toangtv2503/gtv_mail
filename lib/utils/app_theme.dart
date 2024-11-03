import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const appTextColorPrimary = Color(0xFF212121);
  static const iconColorPrimary = Color(0xFFFFFFFF);
  static const appTextColorSecondary = Color(0xFF5A5C5E);
  static const iconColorSecondary = Color(0xFFA8ABAD);
  static const appLayoutBackground = Color(0xFFF8F8F8);
  static const appWhite = Color(0xFFFFFFFF);
  static const appShadowColor = Color(0x95E9EBF0);
  static const appColorPrimaryLight = Color(0xFFF9FAFF);
  static const appSecondaryBackgroundColor = Color(0xFF131D25);
  static const appDividerColor = Color(0xFFDADADA);

  // Dark Theme Colors
  static const appBackgroundColorDark = Color(0xFF202124);
  static const cardBackgroundBlackDark = Color(0xFF1D2939);
  static const colorPrimaryBlack = Color(0xFF131D25);
  static const appColorPrimaryDarkLight = Color(0xFFF9FAFF);
  static const iconColorPrimaryDark = Color(0xFF212121);
  static const iconColorSecondaryDark = Color(0xFFA8ABAD);
  static const appShadowColorDark = Color(0x1A3E3942);

  // Additional Colors
  static const floatingTextColor = Color(0xFFF06292);
  static const blackColor = Color(0xFF000000);
  static const whiteColor = Color(0xFFFFFFFF);
  static const greyColor = Color(0xFF808080);
  static const redColor = Color(0xFFD93025);
  static const greenColor = Color(0xFF188038);
  static const yellowColor = Color(0xFFF9AB00);
  static const blueColor = Color(0xFF1A73EB);

  // Light Theme Data
  static ThemeData lightTheme = ThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
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
    primaryColor: appColorPrimaryLight,
    scaffoldBackgroundColor: appLayoutBackground,
    dividerColor: appDividerColor,
    iconTheme: const IconThemeData(color: iconColorPrimary),
    primaryIconTheme: const IconThemeData(color: iconColorPrimary),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: appTextColorPrimary),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: appTextColorPrimary),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: appTextColorPrimary),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: appTextColorPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: appTextColorPrimary),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: appTextColorPrimary),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTextColorPrimary),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: appTextColorSecondary),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appTextColorSecondary),
      bodyLarge: TextStyle(fontSize: 16, color: appTextColorPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: appTextColorSecondary),
      bodySmall: TextStyle(fontSize: 12, color: appTextColorSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTextColorPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appTextColorSecondary),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: appTextColorSecondary),
    ),
    appBarTheme: const AppBarTheme(
      color: appColorPrimaryLight,
      iconTheme: IconThemeData(color: iconColorPrimary),
    ),
    cardColor: appWhite,
    shadowColor: appShadowColor,
    buttonTheme: const ButtonThemeData(
      buttonColor: blueColor,
      textTheme: ButtonTextTheme.primary,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        side: const BorderSide(
          width: 0.8,
          color: greyColor,
        ),
        fixedSize: const Size(128, 32),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        textStyle: const TextStyle(color: blueColor)
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: floatingTextColor,
      foregroundColor: whiteColor,
    ),
  );

  // Dark Theme Data
  static ThemeData darkTheme = ThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
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
    primaryColor: colorPrimaryBlack,
    scaffoldBackgroundColor: appBackgroundColorDark,
    dividerColor: appDividerColor,
    iconTheme: const IconThemeData(color: iconColorPrimaryDark),
    primaryIconTheme: const IconThemeData(color: iconColorPrimaryDark),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: appColorPrimaryDarkLight),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: appColorPrimaryDarkLight),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: appColorPrimaryDarkLight),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: appColorPrimaryDarkLight),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: appColorPrimaryDarkLight),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: appColorPrimaryDarkLight),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColorPrimaryDarkLight),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: iconColorSecondaryDark),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColorSecondaryDark),
      bodyLarge: TextStyle(fontSize: 16, color: appColorPrimaryDarkLight),
      bodyMedium: TextStyle(fontSize: 14, color: iconColorSecondaryDark),
      bodySmall: TextStyle(fontSize: 12, color: iconColorSecondaryDark),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appColorPrimaryDarkLight),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: iconColorSecondaryDark),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: iconColorSecondaryDark),
    ),
    appBarTheme: const AppBarTheme(
      color: colorPrimaryBlack,
      iconTheme: IconThemeData(color: iconColorPrimaryDark),
    ),
    cardColor: cardBackgroundBlackDark,
    shadowColor: appShadowColorDark,
    buttonTheme: const ButtonThemeData(
      buttonColor: greenColor,
      textTheme: ButtonTextTheme.primary,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          side: const BorderSide(
            width: 0.8,
            color: whiteColor,
          ),
          fixedSize: const Size(128, 32),
          // padding: const EdgeInsets.symmetric(horizontal: 20.0),
          textStyle: const TextStyle(color: blueColor)
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: floatingTextColor,
      foregroundColor: whiteColor,
    ),
  );
}
