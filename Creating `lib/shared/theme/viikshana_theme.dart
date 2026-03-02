// lib/shared/theme/viikshana_theme.dart
import 'package:flutter/material.dart';
import 'viikshana_colors.dart';
import 'viikshana_spacing.dart';

class ViikshanaTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ViikshanaColors.brandOrange,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      textTheme: TextTheme(
        bodyText1: TextStyle(fontSize: 16.0),
        bodyText2: TextStyle(fontSize: 14.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: ViikshanaColors.brandOrange,
          onPrimary: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: ViikshanaSpacing.paddingMedium, vertical: ViikshanaSpacing.paddingSmall),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ViikshanaColors.brandOrange,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: ViikshanaColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: ViikshanaColors.surfaceDark,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        bodyText1: TextStyle(fontSize: 16.0, color: Colors.white),
        bodyText2: TextStyle(fontSize: 14.0, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: ViikshanaColors.brandOrange,
          onPrimary: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: ViikshanaSpacing.paddingMedium, vertical: ViikshanaSpacing.paddingSmall),
        ),
      ),
    );
  }
}
