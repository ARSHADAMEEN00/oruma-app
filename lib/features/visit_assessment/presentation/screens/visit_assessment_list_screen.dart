import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/domain/visit_assessment.dart';
import 'package:oruma_app/features/visit_assessment/presentation/providers/visit_assessment_controller.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_flow_screen.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_widgets.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class VisitAssessmentModuleScreen extends StatefulWidget {
  const VisitAssessmentModuleScreen({
    super.key,
    required this.visit,
    this.patient,
  });

  final HomeVisit visit;
  final Patient? patient;

  @override
  State<VisitAssessmentModuleScreen> createState() =>
      _VisitAssessmentModuleScreenState();
}

class _VisitAssessmentModuleScreenState
    extends State<VisitAssessmentModuleScreen> {
  VisitAssessmentController? _controller;

  Patient? get _patient => widget.patient ?? widget.visit.patientDetails;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final auth = context.read<AuthService>();
    final now = DateTime.now();
    final visitDate =
        DateTime.tryParse(widget.visit.visitDate) ?? DateTime.now();
    final patient = _patient;
    final initial = VisitAssessment(
      homeVisitId: widget.visit.id ?? '',
      patientId: widget.visit.patientId ?? patient?.id ?? '',
      patientName: widget.visit.patientName,
      regNo: patient?.registerId ?? '',
      visitDate: visitDate,
      timeFrom: DateFormat('HH:mm').format(now),
      timeTo: DateFormat('HH:mm').format(now.add(const Duration(minutes: 90))),
      team: widget.visit.team?.trim().isNotEmpty == true
          ? widget.visit.team!
          : 'Team Oruma',
      visitType: _visitTypeFromMode(widget.visit.visitMode),
      nurseName: auth.user?['name']?.toString() ?? '',
      nurseId: auth.user?['_id']?.toString() ?? auth.user?['id']?.toString(),
    );
    _controller = VisitAssessmentController(initialAssessment: initial);
    _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Theme(
      data: _assessmentTheme(context),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => VisitAssessmentListScreen(
          controller: controller,
          patient: _patient,
        ),
      ),
    );
  }

  String _visitTypeFromMode(String mode) {
    switch (mode) {
      case 'dhc_visit':
        return 'DHC';
      case 'vhc_visit':
        return 'GVHC';
      default:
        return 'NHC';
    }
  }
}

class VisitAssessmentListScreen extends StatelessWidget {
  const VisitAssessmentListScreen({
    super.key,
    required this.controller,
    this.patient,
  });

  final VisitAssessmentController controller;
  final Patient? patient;

  @override
  Widget build(BuildContext context) {
    final assessment = controller.assessment;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Visit Assessments'),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: assessmentText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: assessmentGreen),
            )
          : RefreshIndicator(
              color: assessmentGreen,
              onRefresh: controller.initialize,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                children: [
                  _patientCard(assessment),
                  const SizedBox(height: 15),
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (!assessment.isComplete) _draftCard(context),
                  if (!assessment.isComplete) const SizedBox(height: 9),
                  OutlinedButton.icon(
                    onPressed: () => _openFlow(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      assessment.id == null
                          ? 'Start New Assessment'
                          : assessment.isComplete
                          ? 'View Assessment'
                          : 'Open Assessment',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: assessmentGreenDark,
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: assessmentBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Previous Assessments',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (controller.previousAssessments.isEmpty)
                    const AssessmentEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No previous assessments',
                      message:
                          'Completed and draft assessments for this patient will appear here.',
                    )
                  else
                    ...controller.previousAssessments.map(_historyRow),
                ],
              ),
            ),
      bottomNavigationBar: _referenceNavigation(context),
    );
  }

  Widget _patientCard(VisitAssessment assessment) {
    final age = patient?.age;
    final gender = patient?.gender;
    final details = [
      if (age != null) '$age Years',
      if (gender?.isNotEmpty == true) gender!,
    ].join('  •  ');
    final name = assessment.patientName.trim();
    return AssessmentCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE7D6C2),
              shape: BoxShape.circle,
            ),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6E4A2D),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.patientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(
                      color: assessmentMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Reg No.   ${assessment.regNo.isEmpty ? '—' : assessment.regNo}',
                  style: const TextStyle(color: assessmentMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _draftCard(BuildContext context) {
    final stateLabel = switch (controller.syncState) {
      AssessmentSyncState.saving => 'Saving…',
      AssessmentSyncState.offline => 'Saved offline',
      _ => 'Last saved just now',
    };
    return AssessmentCard(
      color: assessmentMint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Draft in Progress',
            style: TextStyle(
              color: assessmentGreenDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stateLabel,
            style: const TextStyle(color: assessmentMuted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _openFlow(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: assessmentGreenDark,
              minimumSize: const Size.fromHeight(42),
              side: const BorderSide(color: assessmentGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue Assessment',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(VisitAssessment item) {
    final statusColor = item.isComplete
        ? assessmentMuted
        : const Color(0xFFE48B16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AssessmentCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(item.visitDate),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              item.isComplete ? 'Completed' : 'Draft',
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 17, color: assessmentMuted),
          ],
        ),
      ),
    );
  }

  Widget _referenceNavigation(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: assessmentBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.home_outlined, 'Home', () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }),
            _navItem(Icons.people_outline, 'Patients', () {}),
            InkWell(
              onTap: () => _openFlow(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: assessmentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3314865D),
                      blurRadius: 9,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
            _navItem(Icons.calendar_today_outlined, 'Visits', () {
              Navigator.maybePop(context);
            }),
            _navItem(Icons.menu, 'More', () {}),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: assessmentMuted),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: assessmentMuted, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFlow(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: VisitAssessmentFlowScreen(controller: controller),
        ),
      ),
    );
  }
}

ThemeData _assessmentTheme(BuildContext context) {
  final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F1412) : Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: assessmentGreen,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: assessmentGreen,
      surface: dark ? const Color(0xFF171D1B) : Colors.white,
    ),
    fontFamily: 'sans-serif',
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: dark ? Colors.white : assessmentText,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
  );
}
