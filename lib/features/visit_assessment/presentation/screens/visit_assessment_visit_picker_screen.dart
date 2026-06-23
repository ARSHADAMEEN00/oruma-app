import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_list_screen.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_theme.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/services/home_visit_service.dart';
import 'package:oruma_app/widgets/app_bottom_nav_router.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';

class VisitAssessmentVisitPickerScreen extends StatefulWidget {
  const VisitAssessmentVisitPickerScreen({super.key});

  @override
  State<VisitAssessmentVisitPickerScreen> createState() =>
      _VisitAssessmentVisitPickerScreenState();
}

class _VisitAssessmentVisitPickerScreenState
    extends State<VisitAssessmentVisitPickerScreen> {
  final _searchController = TextEditingController();
  List<HomeVisit> _visits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilter);
    _loadVisits();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  List<HomeVisit> get _filteredVisits {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _visits;
    return _visits.where((visit) {
      final patient = visit.patientDetails;
      return visit.patientName.toLowerCase().contains(query) ||
          visit.address.toLowerCase().contains(query) ||
          (patient?.registerId?.toLowerCase().contains(query) ?? false) ||
          (visit.team?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _loadVisits() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final visits = await HomeVisitService.getAllHomeVisits();
      visits.sort((a, b) {
        final aDate = DateTime.tryParse(a.visitDate);
        final bDate = DateTime.tryParse(b.visitDate);
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _refreshFilter() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: visitAssessmentLightTheme(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Select Home Visit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search patient, register no. or team',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 19),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close, size: 17),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF6F8F9),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
        bottomNavigationBar: CompactAppBottomBar(
          current: AppBottomSection.nhc,
          onSelected: _handleBottomNavigation,
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF14865D)),
      );
    }
    if (_error != null) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load home visits',
        message: _error!,
        action: TextButton.icon(
          onPressed: _loadVisits,
          icon: const Icon(Icons.refresh, size: 17),
          label: const Text('Retry'),
        ),
      );
    }
    final visits = _filteredVisits;
    if (visits.isEmpty) {
      return _messageState(
        icon: Icons.home_work_outlined,
        title: 'No home visits found',
        message: _searchController.text.isEmpty
            ? 'Schedule a home visit before starting an NHC assessment.'
            : 'Try another patient name or register number.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVisits,
      color: const Color(0xFF14865D),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
        itemCount: visits.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _visitCard(visits[index]),
      ),
    );
  }

  Widget _visitCard(HomeVisit visit) {
    final patient = visit.patientDetails;
    final date = DateTime.tryParse(visit.visitDate);
    final hasPatientLink =
        (visit.patientId?.isNotEmpty ?? false) || patient?.id != null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E8EA)),
      ),
      child: InkWell(
        onTap: () => _selectVisit(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasPatientLink
                      ? const Color(0xFFE7F5EF)
                      : const Color(0xFFFFF3E2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  hasPatientLink
                      ? Icons.home_work_outlined
                      : Icons.link_off_outlined,
                  color: hasPatientLink
                      ? const Color(0xFF0F7A55)
                      : const Color(0xFFC87912),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172027),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (date != null)
                          DateFormat('dd MMM yyyy').format(date),
                        if (patient?.registerId?.isNotEmpty == true)
                          'Reg ${patient!.registerId}',
                        if (visit.team?.isNotEmpty == true) visit.team!,
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7680),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 19,
                color: Color(0xFF7B858E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF14865D)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7680),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  void _selectVisit(HomeVisit visit) {
    if (visit.id == null ||
        ((visit.patientId?.isEmpty ?? true) &&
            visit.patientDetails?.id == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This home visit is not linked to a patient record.'),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VisitAssessmentModuleScreen(
          visit: visit,
          patient: visit.patientDetails,
        ),
      ),
    );
  }

  void _handleBottomNavigation(AppBottomSection section) {
    AppBottomNavRouter.handle(
      context,
      section,
      onNhc: () {
        _searchController.clear();
        _loadVisits();
      },
    );
  }
}
