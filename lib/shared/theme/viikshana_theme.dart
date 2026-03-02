import 'package:flutter/material.dart';
import '../../tokens/viikshana_colors.dart'; // Fix import paths
import '../../tokens/viikshana_spacing.dart'; // Fix import paths

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
      ),
    );
  }
}
