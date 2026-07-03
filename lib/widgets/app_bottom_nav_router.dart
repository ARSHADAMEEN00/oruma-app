import 'package:flutter/material.dart';
import 'package:oruma_app/patient_list_page.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_visit_picker_screen.dart';
import 'package:oruma_app/home_visit_list_page.dart';
import 'package:oruma_app/homscreen.dart';
import 'package:oruma_app/medicine_supply_list_page.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:oruma_app/widgets/module_theme.dart';
import 'package:provider/provider.dart';

class AppBottomNavRouter {
  AppBottomNavRouter._();

  static bool _transitionInProgress = false;
  static const _transitionDuration = Duration(milliseconds: 360);

  static void handle(
    BuildContext context, {
    required AppBottomSection current,
    required AppBottomSection target,
  }) {
    if (current == target || _transitionInProgress) return;
    final auth = context.read<AuthService>();
    if (target == AppBottomSection.medicine && !auth.canAccessMedicine) {
      return;
    }
    if (target == AppBottomSection.nhc && !auth.canAccessNHC) {
      return;
    }

    final page = switch (target) {
      AppBottomSection.home => const Homescreen(),
      AppBottomSection.medicine => const ModuleTheme(
        palette: ModulePalettes.medicineSupply,
        child: MedicineSupplyListPage(),
      ),
      AppBottomSection.patients => const ModuleTheme(
        palette: ModulePalettes.patients,
        child: PatientListPage(),
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
    _transitionInProgress = true;
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: _transitionDuration,
      reverseTransitionDuration: _transitionDuration,
      pageBuilder: (_, _, _) => ColoredBox(color: Colors.white, child: page),
      transitionsBuilder: (_, animation, _, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: Offset(forward ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );
        return ClipRect(
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );

    Navigator.of(context).pushReplacement(route);

    Future<void>.delayed(_transitionDuration, () {
      _transitionInProgress = false;
    });
  }
}
