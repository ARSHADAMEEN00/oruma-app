import 'package:flutter/material.dart';
import 'package:oruma_app/equipment_supply_list_page.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_visit_picker_screen.dart';
import 'package:oruma_app/home_visit_list_page.dart';
import 'package:oruma_app/homscreen.dart';
import 'package:oruma_app/medicine_supply_list_page.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:oruma_app/widgets/module_theme.dart';

class AppBottomNavRouter {
  AppBottomNavRouter._();

  static void handle(
    BuildContext context, {
    required AppBottomSection current,
    required AppBottomSection target,
  }) {
    if (current == target) return;

    final page = switch (target) {
      AppBottomSection.home => const Homescreen(),
      AppBottomSection.medicine => const ModuleTheme(
        palette: ModulePalettes.medicineSupply,
        child: MedicineSupplyListPage(),
      ),
      AppBottomSection.equipment => const ModuleTheme(
        palette: ModulePalettes.equipmentSupply,
        child: EquipmentSupplyListPage(),
      ),
      AppBottomSection.homeVisit => const ModuleTheme(
        palette: ModulePalettes.homeVisits,
        child: HomeVisitListPage(),
      ),
      AppBottomSection.nhc => const VisitAssessmentVisitPickerScreen(),
    };

    _open(context, page, forward: target.index > current.index);
  }

  static void _open(
    BuildContext context,
    Widget page, {
    required bool forward,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(forward ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.94,
                end: 1,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
      (_) => false,
    );
  }
}
