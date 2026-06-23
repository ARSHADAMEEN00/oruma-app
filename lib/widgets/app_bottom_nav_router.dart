import 'package:flutter/material.dart';
import 'package:oruma_app/equipment_list_page.dart';
import 'package:oruma_app/home_visit_list_page.dart';
import 'package:oruma_app/medicine_list_page.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:oruma_app/widgets/module_theme.dart';

class AppBottomNavRouter {
  AppBottomNavRouter._();

  static void handle(
    BuildContext context,
    AppBottomSection section, {
    required VoidCallback onNhc,
  }) {
    switch (section) {
      case AppBottomSection.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case AppBottomSection.medicine:
        _open(
          context,
          const ModuleTheme(
            palette: ModulePalettes.medicineSupply,
            child: MedicineListPage(),
          ),
        );
        return;
      case AppBottomSection.equipment:
        _open(
          context,
          const ModuleTheme(
            palette: ModulePalettes.equipmentSupply,
            child: EquipmentListPage(),
          ),
        );
        return;
      case AppBottomSection.homeVisit:
        _open(
          context,
          const ModuleTheme(
            palette: ModulePalettes.homeVisits,
            child: HomeVisitListPage(),
          ),
        );
        return;
      case AppBottomSection.nhc:
        onNhc();
        return;
    }
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => route.isFirst,
    );
  }
}
