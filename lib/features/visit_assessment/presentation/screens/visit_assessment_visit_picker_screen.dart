import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_list_screen.dart';
import 'package:oruma_app/features/visit_assessment/presentation/widgets/assessment_theme.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
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
  List<Patient> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilter);
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.address.toLowerCase().contains(query) ||
          patient.phone.toLowerCase().contains(query) ||
          (patient.phone2?.toLowerCase().contains(query) ?? false) ||
          (patient.registerId?.toLowerCase().contains(query) ?? false) ||
          patient.place.toLowerCase().contains(query) ||
          patient.village.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadPatients() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final patients = await PatientService.getAllPatients(isDead: false);
      patients.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _patients = patients;
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
            'Select Patient',
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
                  hintText: 'Search patient, register no. or phone',
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
        title: 'Could not load patients',
        message: _error!,
        action: TextButton.icon(
          onPressed: _loadPatients,
          icon: const Icon(Icons.refresh, size: 17),
          label: const Text('Retry'),
        ),
      );
    }
    final patients = _filteredPatients;
    if (patients.isEmpty) {
      return _messageState(
        icon: Icons.people_outline,
        title: 'No patients found',
        message: _searchController.text.isEmpty
            ? 'Add a patient before starting an NHC assessment.'
            : 'Try another patient name or register number.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: const Color(0xFF14865D),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
        itemCount: patients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _patientCard(patients[index]),
      ),
    );
  }

  Widget _patientCard(Patient patient) {
    final details = [
      if (patient.age > 0) '${patient.age} Years',
      if (patient.gender.trim().isNotEmpty) patient.gender,
      if (patient.registerId?.trim().isNotEmpty == true)
        'Reg ${patient.registerId}',
    ].join('  •  ');
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E8EA)),
      ),
      child: InkWell(
        onTap: () => _selectPatient(patient),
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
                  color: const Color(0xFFE7F5EF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  patient.name.trim().isEmpty
                      ? '?'
                      : patient.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0F7A55),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172027),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7680),
                        ),
                      ),
                    if (patient.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        patient.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7680),
                        ),
                      ),
                    ],
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

  void _selectPatient(Patient patient) {
    if (patient.id == null || patient.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This patient is missing a patient record id.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitAssessmentModuleScreen(patient: patient),
      ),
    );
  }

  void _handleBottomNavigation(AppBottomSection section) {
    AppBottomNavRouter.handle(
      context,
      current: AppBottomSection.nhc,
      target: section,
    );
  }
}
