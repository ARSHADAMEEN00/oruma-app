import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';

ThemeData visitAssessmentLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: assessmentGreen,
      brightness: Brightness.light,
      primary: assessmentGreen,
      surface: Colors.white,
    ),
    fontFamily: 'sans-serif',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: assessmentText,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
  );
}
