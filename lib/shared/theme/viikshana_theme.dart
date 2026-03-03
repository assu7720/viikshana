import 'package:flutter/material.dart';
import 'package:viikshana/shared/tokens/viikshana_colors.dart';
import 'package:viikshana/shared/tokens/viikshana_typography.dart';

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
        surface: ViikshanaColors.surfaceDark,
      ),
      scaffoldBackgroundColor: ViikshanaColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: ViikshanaColors.surfaceDark,
        foregroundColor: ViikshanaColors.onSurfaceDark,
      ),
      iconTheme: IconThemeData(
        color: ViikshanaColors.onSurfaceDark,
        size: 24,
      ),
      textTheme: ViikshanaTypography.darkTextTheme(),
    );
  }
}
