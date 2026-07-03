import 'package:flutter/material.dart';

class ModulePalette {
  final Color cardBackground;
  final Color iconBackground;
  final Color primary;

  const ModulePalette({
    required this.cardBackground,
    required this.iconBackground,
    required this.primary,
  });
}

class ModulePalettes {
  ModulePalettes._();

  static const patients = ModulePalette(
    cardBackground: Color(0xFFE6F1FB),
    iconBackground: Color(0xFFB5D4F4),
    primary: Color(0xFF185FA5),
  );

  static const homeVisits = ModulePalette(
    cardBackground: Color(0xFFEAF3DE),
    iconBackground: Color(0xFFC0DD97),
    primary: Color(0xFF3B6D11),
  );

  static const equipmentSupply = ModulePalette(
    cardBackground: Color(0xFFFAEEDA),
    iconBackground: Color(0xFFFAC775),
    primary: Color(0xFF854F0B),
  );

  static const medicineSupply = ModulePalette(
    cardBackground: Color(0xFFE1F5EE),
    iconBackground: Color(0xFF9FE1CB),
    primary: Color(0xFF0F6E56),
  );

  static const socialSupport = ModulePalette(
    cardBackground: Color(0xFFF7E5EE),
    iconBackground: Color(0xFFE8AEC9),
    primary: Color(0xFF8A2454),
  );
}

class ModuleTheme extends StatelessWidget {
  final ModulePalette palette;
  final Widget child;

  const ModuleTheme({super.key, required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.primary,
          primary: palette.primary,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: palette.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
        ),
      ),
      child: child,
    );
  }
}
