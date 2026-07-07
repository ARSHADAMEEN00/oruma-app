import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/care_plan_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/clinical_notes_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/medicines_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/physical_exam_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/review_submit_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/visit_header_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/steps/vitals_step.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_theme.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/app_bottom_nav_router.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';

class VisitAssessmentFlowScreen extends StatelessWidget {
  const VisitAssessmentFlowScreen({super.key, required this.controller});

  final VisitAssessmentController controller;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: visitAssessmentLightTheme(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) controller.saveDraft(silent: true);
            },
            child: AdaptiveAppScaffold(
              backgroundColor: Colors.white,
              currentSection: AppBottomSection.nhc,
              onNavigationSelected: (section) =>
                  _handleBottomNavigation(context, section),
              contentMaxWidth: 900,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 230),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.025, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(controller.currentStep),
                          child: _step(),
                        ),
                      ),
                    ),
                    _footer(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              Text(
                'Step ${controller.currentStep + 1} of 7',
                style: const TextStyle(
                  color: assessmentText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (controller.syncState == AssessmentSyncState.saving)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: assessmentGreen,
                  ),
                )
              else if (controller.syncState == AssessmentSyncState.offline)
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: assessmentMuted,
                ),
              const SizedBox(width: 8),
              _languageToggle(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                value: (controller.currentStep + 1) / 7,
                backgroundColor: assessmentBorder,
                valueColor: const AlwaysStoppedAnimation(assessmentGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step() {
    return switch (controller.currentStep) {
      0 => VisitHeaderStep(controller: controller),
      1 => PhysicalExamStep(controller: controller),
      2 => VitalsStep(controller: controller),
      3 => MedicinesStep(controller: controller),
      4 => ClinicalNotesStep(controller: controller),
      5 => CarePlanStep(controller: controller),
      _ => ReviewSubmitStep(controller: controller),
    };
  }

  Widget _languageToggle() {
    return Container(
      height: 27,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F4),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: assessmentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_languageOption('EN', 'en'), _languageOption('ML', 'ml')],
      ),
    );
  }

  Widget _languageOption(String label, String value) {
    final selected = controller.language == value;
    return InkWell(
      onTap: () => controller.setLanguage(value),
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? assessmentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : assessmentMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final isLast = controller.currentStep == 6;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: isLast
                ? OutlinedButton(
                    onPressed: controller.isSubmitting
                        ? null
                        : () async {
                            final saved = await controller.saveDraft();
                            if (!context.mounted) return;
                            _message(
                              context,
                              saved
                                  ? 'Draft saved'
                                  : 'Draft saved offline and will sync later',
                            );
                          },
                    style: _secondaryStyle(),
                    child: const Text('Save Draft'),
                  )
                : FilledButton(
                    onPressed: controller.currentStep == 0
                        ? () => Navigator.maybePop(context)
                        : () => controller.setStep(controller.currentStep - 1),
                    style: _backStyle(),
                    child: const Text('Back'),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: controller.isSubmitting
                  ? null
                  : () => isLast ? _submit(context) : _next(context),
              style: FilledButton.styleFrom(
                backgroundColor: assessmentGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(43),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isLast ? 'Submit Assessment' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _secondaryStyle() => OutlinedButton.styleFrom(
    foregroundColor: assessmentGreenDark,
    minimumSize: const Size.fromHeight(43),
    side: const BorderSide(color: Color(0xFFBBDDCF)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  ButtonStyle _backStyle() => FilledButton.styleFrom(
    backgroundColor: const Color(0xFFF5F6F7),
    foregroundColor: assessmentText,
    minimumSize: const Size.fromHeight(43),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );

  void _next(BuildContext context) {
    final error = controller.validateStep(controller.currentStep);
    if (error != null) {
      _message(context, error, error: true);
      return;
    }
    controller.saveDraft(silent: true);
    controller.setStep(controller.currentStep + 1);
  }

  Future<void> _submit(BuildContext context) async {
    final error = controller.validateStep(6);
    if (error != null) {
      _message(context, error, error: true);
      return;
    }
    final submitted = await controller.submit();
    if (!context.mounted) return;
    if (submitted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: assessmentGreen,
            size: 42,
          ),
          title: const Text('Assessment submitted'),
          content: const Text(
            'The visit assessment has been securely saved.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: assessmentGreen),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (context.mounted) Navigator.pop(context, true);
    } else {
      _message(
        context,
        controller.syncMessage ?? 'Unable to submit assessment',
        error: true,
      );
    }
  }

  void _message(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? assessmentDanger : assessmentGreenDark,
        ),
      );
  }

  void _handleBottomNavigation(BuildContext context, AppBottomSection section) {
    controller.saveDraft(silent: true);
    AppBottomNavRouter.handle(
      context,
      current: AppBottomSection.nhc,
      target: section,
    );
  }
}
