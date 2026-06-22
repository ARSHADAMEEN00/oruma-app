import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/patient_details.dart';
import 'package:oruma_app/pt_registration.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/patient_details_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/widgets/deceased_icon.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum _PatientAction { markDeceased, delete }

class PatientDetailsPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailsPage({super.key, required this.patient});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage>
    with SingleTickerProviderStateMixin {
  late Patient _currentPatient;
  late PatientDetails _details;
  late final TabController _tabController;

  bool _detailsLoading = true;
  bool _isMutating = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _details = PatientDetails(patient: widget.patient);
    _tabController = TabController(length: 4, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails({bool showLoader = true}) async {
    final patientId = _currentPatient.id;
    if (patientId == null || patientId.isEmpty) {
      if (mounted) {
        setState(() {
          _detailsLoading = false;
          _detailsError = 'Patient ID is not available';
        });
      }
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _detailsLoading = true;
        _detailsError = null;
      });
    }

    try {
      final details = await PatientDetailsService.getPatientDetails(patientId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _currentPatient = details.patient;
        _detailsLoading = false;
        _detailsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailsLoading = false;
        _detailsError = _friendlyError(error);
      });
    }
  }

  Future<void> _editPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => patientrigister(patient: _currentPatient),
      ),
    );

    if (!mounted) return;
    if (result is Patient) {
      setState(() => _currentPatient = result);
      await _loadDetails();
    } else if (result == true) {
      await _loadDetails();
    }
  }

  Future<void> _deletePatient() async {
    final patientId = _currentPatient.id;
    if (patientId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text(
          'Delete ${_displayName(_currentPatient.name)} permanently? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isMutating = true);
    try {
      await PatientService.deletePatient(patientId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient deleted successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      setState(() => _isMutating = false);
    }
  }

  Future<void> _markAsDeceased() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select date of death',
    );
    if (selectedDate == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as passed away?'),
        content: Text(
          '${_displayName(_currentPatient.name)} will be marked as passed '
          'away on ${DateFormat('dd MMM yyyy').format(selectedDate)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted || _currentPatient.id == null) return;

    setState(() => _isMutating = true);
    try {
      final updatedPatient = await PatientService.updatePatient(
        _currentPatient.id!,
        _currentPatient.copyWith(isDead: true, dateOfDeath: selectedDate),
      );
      if (!mounted) return;
      setState(() {
        _currentPatient = updatedPatient;
        _isMutating = false;
      });
      await _loadDetails(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient marked as passed away')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isMutating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _launchMap(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open map');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _callPhone(String phone) async {
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      if (!await launchUrl(uri)) {
        throw Exception('Calling is not available on this device');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  void _handlePatientAction(_PatientAction action) {
    switch (action) {
      case _PatientAction.markDeceased:
        _markAsDeceased();
        return;
      case _PatientAction.delete:
        _deletePatient();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final canShowMenu =
        auth.canDelete || (auth.canEdit && !_currentPatient.isDead);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildCollapsibleAppBar(auth, canShowMenu),
              if (_detailsLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF6E63DF),
                    backgroundColor: Color(0xFFE7E5FA),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PatientTabsHeaderDelegate(child: _buildTabs()),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMedicalTab(),
                _buildHomeVisitsTab(),
                _buildEquipmentTab(),
              ],
            ),
          ),
          if (_isMutating)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.72),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildCollapsibleAppBar(AuthService auth, bool canShowMenu) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final collapsedHeight = topPadding + kToolbarHeight;
    const expandedHeight = 300.0;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      toolbarHeight: kToolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF7167E8),
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: _buildHeaderActions(auth, canShowMenu),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final availableRange = expandedHeight - collapsedHeight;
          final expandedProgress =
              ((constraints.maxHeight - collapsedHeight) / availableRange)
                  .clamp(0.0, 1.0);
          final compactProgress = (1 - expandedProgress * 1.8).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7167E8), Color(0xFF917CF3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: topPadding + 17,
                left: 110,
                right: 110,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: expandedProgress,
                    child: const Text(
                      'Patient Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: collapsedHeight + 12,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: expandedProgress,
                    child: _buildPatientSummary(),
                  ),
                ),
              ),
              Positioned(
                top: topPadding + 7,
                left: 56,
                right: _headerActionWidth(auth, canShowMenu),
                height: 46,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: compactProgress,
                    child: _buildCompactPatientSummary(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildHeaderActions(AuthService auth, bool canShowMenu) {
    return [
      if (auth.canEdit)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            tooltip: 'Edit patient',
            onPressed: _isMutating ? null : _editPatient,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ),
      if (canShowMenu)
        PopupMenuButton<_PatientAction>(
          tooltip: 'More actions',
          enabled: !_isMutating,
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onSelected: _handlePatientAction,
          itemBuilder: (context) => [
            if (auth.canEdit && !_currentPatient.isDead)
              const PopupMenuItem(
                value: _PatientAction.markDeceased,
                child: Row(
                  children: [
                    DeceasedIcon(size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Mark as passed away'),
                  ],
                ),
              ),
            if (auth.canDelete)
              const PopupMenuItem(
                value: _PatientAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete patient', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
    ];
  }

  double _headerActionWidth(AuthService auth, bool canShowMenu) {
    var width = 16.0;
    if (auth.canEdit) width += 52;
    if (canShowMenu) width += 48;
    return width;
  }

  Widget _buildPatientSummary() {
    final name = _displayName(_currentPatient.name);
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final visibleConditions = _currentPatient.disease.take(3).toList();
    final hiddenConditionCount =
        _currentPatient.disease.length - visibleConditions.length;
    final secondary = <String>[
      if (_currentPatient.registerId?.isNotEmpty == true)
        'ID ${_currentPatient.registerId}',
      if (_currentPatient.gender.isNotEmpty) _currentPatient.gender,
      '${_currentPatient.age} years',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7167E8), Color(0xFF917CF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: _currentPatient.isDead
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _currentPatient.isDead
                ? const Icon(
                    Icons.person_off_outlined,
                    color: Colors.white,
                    size: 32,
                  )
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF6B5FE1),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 13),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            secondary.join('  •  '),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_currentPatient.isDead) ...[
            const SizedBox(height: 10),
            _lightHeaderPill('Passed away', icon: Icons.favorite_border),
          ] else if (_currentPatient.disease.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: visibleConditions
                  .map((disease) => _lightHeaderPill(disease))
                  .followedBy([
                    if (hiddenConditionCount > 0)
                      _lightHeaderPill('+$hiddenConditionCount'),
                  ])
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactPatientSummary() {
    final name = _displayName(_currentPatient.name);
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final registerId = _currentPatient.registerId?.trim();

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: _currentPatient.isDead
              ? const Icon(
                  Icons.person_off_outlined,
                  color: Colors.white,
                  size: 18,
                )
              : Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (registerId?.isNotEmpty == true)
                Text(
                  'ID $registerId',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final visitCount = _details.homeVisits.length;
    final equipmentCount = _details.equipmentSupplies.length;

    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF524D85).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFF6E63DF),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF77778A),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        tabs: [
          const Tab(text: 'Overview'),
          const Tab(text: 'Medical'),
          Tab(text: 'Home Visits ($visitCount)'),
          Tab(text: 'Equipment ($equipmentCount)'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadDetails(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_detailsError != null) ...[
            _buildSyncError(),
            const SizedBox(height: 12),
          ],
          _sectionCard(
            icon: Icons.person_outline,
            title: 'Personal information',
            children: _withSpacing([
              _infoRow(
                Icons.badge_outlined,
                'Register ID',
                _value(_currentPatient.registerId),
              ),
              _infoRow(
                Icons.person_outline,
                'Full name',
                _displayName(_currentPatient.name),
              ),
              _infoRow(
                Icons.call_outlined,
                'Phone',
                _value(_currentPatient.phone),
                trailing: _phoneButton(_currentPatient.phone),
              ),
              _infoRow(
                Icons.family_restroom_outlined,
                'Caregiver / relation',
                _value(_currentPatient.relation),
              ),
              _infoRow(
                Icons.phone_android_outlined,
                'Caregiver phone',
                _value(_currentPatient.phone2),
                trailing: _phoneButton(_currentPatient.phone2),
              ),
              _infoRow(
                Icons.wc_outlined,
                'Gender',
                _value(_currentPatient.gender),
              ),
              _infoRow(
                Icons.cake_outlined,
                'Age',
                '${_currentPatient.age} years',
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            icon: Icons.location_on_outlined,
            title: 'Location & address',
            children: _withSpacing([
              _infoRow(
                Icons.home_outlined,
                'Address',
                _value(_currentPatient.address),
              ),
              _infoRow(
                Icons.place_outlined,
                'Place',
                _value(_currentPatient.place),
              ),
              _infoRow(
                Icons.holiday_village_outlined,
                'Village',
                _value(_currentPatient.village),
              ),
              _infoRow(
                Icons.apartment_outlined,
                'Ward number',
                _value(_currentPatient.ward),
              ),
              if (_currentPatient.locationLink?.trim().isNotEmpty == true)
                _mapButton(_currentPatient.locationLink!),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return RefreshIndicator(
      onRefresh: () => _loadDetails(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_detailsError != null) ...[
            _buildSyncError(),
            const SizedBox(height: 12),
          ],
          _sectionCard(
            icon: Icons.medical_services_outlined,
            title: 'Medical details',
            children: [
              const Text(
                'Conditions',
                style: TextStyle(
                  color: Color(0xFF74798B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              if (_currentPatient.disease.isEmpty)
                const Text(
                  'No conditions recorded',
                  style: TextStyle(
                    color: Color(0xFF202333),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentPatient.disease
                      .map(
                        (disease) => _statusPill(
                          disease,
                          Theme.of(context).colorScheme.primary,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 22),
              _infoRow(
                Icons.assignment_outlined,
                'Care plan',
                _value(_currentPatient.plan),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            icon: Icons.event_note_outlined,
            title: 'Record information',
            children: _withSpacing([
              _infoRow(
                Icons.event_available_outlined,
                'Registration date',
                _formatDate(_currentPatient.registrationDate),
              ),
              if (_currentPatient.isDead)
                _infoRow(
                  Icons.event_busy_outlined,
                  'Date of death',
                  _formatDate(_currentPatient.dateOfDeath),
                ),
              _infoRow(
                Icons.person_outline,
                _creatorSubtitle(),
                _creatorName(),
              ),
              _infoRow(
                Icons.update_outlined,
                'Last updated',
                _formatDateTime(_currentPatient.updatedAt),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeVisitsTab() {
    if (_detailsLoading && _details.homeVisits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_detailsError != null && _details.homeVisits.isEmpty) {
      return _recordsError('Could not load home visits');
    }
    if (_details.homeVisits.isEmpty) {
      return _emptyState(
        icon: Icons.home_outlined,
        title: 'No home visits yet',
        message: 'Home visit history for this patient will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDetails(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _details.homeVisits.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _homeVisitCard(_details.homeVisits[index], index);
        },
      ),
    );
  }

  Widget _buildEquipmentTab() {
    if (_detailsLoading && _details.equipmentSupplies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_detailsError != null && _details.equipmentSupplies.isEmpty) {
      return _recordsError('Could not load equipment history');
    }
    if (_details.equipmentSupplies.isEmpty) {
      return _emptyState(
        icon: Icons.medical_information_outlined,
        title: 'No equipment distributed',
        message: 'Equipment issued to this patient will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDetails(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _details.equipmentSupplies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _equipmentCard(_details.equipmentSupplies[index]);
        },
      ),
    );
  }

  Widget _homeVisitCard(HomeVisit visit, int index) {
    final modeColor = _visitModeColor(visit.visitMode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.home_outlined, color: modeColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatVisitDate(visit.visitDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visit ${_details.homeVisits.length - index}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(_visitModeLabel(visit.visitMode), modeColor),
            ],
          ),
          const SizedBox(height: 15),
          _detailLine(Icons.groups_outlined, 'Team', _value(visit.team)),
          const SizedBox(height: 10),
          _detailLine(
            Icons.location_on_outlined,
            'Address',
            _value(visit.address),
          ),
          if (visit.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(Icons.notes_outlined, 'Notes', visit.notes!),
          ],
          if (visit.createdBy?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(Icons.person_outline, 'Recorded by', visit.createdBy!),
          ],
        ],
      ),
    );
  }

  Widget _equipmentCard(EquipmentSupply supply) {
    final statusColor = _equipmentStatusColor(supply.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.medical_information_outlined,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _value(supply.equipmentName),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _value(supply.equipmentUniqueId),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(_equipmentStatusLabel(supply.status), statusColor),
            ],
          ),
          const SizedBox(height: 15),
          _detailLine(
            Icons.calendar_today_outlined,
            'Distributed',
            _formatDate(supply.supplyDate),
          ),
          if (supply.returnDate != null) ...[
            const SizedBox(height: 10),
            _detailLine(
              Icons.event_outlined,
              'Expected return',
              _formatDate(supply.returnDate),
            ),
          ],
          if (supply.actualReturnDate != null) ...[
            const SizedBox(height: 10),
            _detailLine(
              Icons.assignment_turned_in_outlined,
              'Returned',
              _formatDate(supply.actualReturnDate),
            ),
          ],
          if (supply.careOf?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(Icons.people_outline, 'Care of', supply.careOf!),
          ],
          if (supply.receiverName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(
              Icons.person_outline,
              'Receiver',
              [
                supply.receiverName,
                supply.receiverPhone,
              ].where((value) => value?.trim().isNotEmpty == true).join(' • '),
            ),
          ],
          if (supply.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(Icons.notes_outlined, 'Notes', supply.notes!),
          ],
          if (supply.returnNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _detailLine(
              Icons.assignment_return_outlined,
              'Return note',
              supply.returnNote!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF242533), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF242533),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF6E63DF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF6E63DF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF242533),
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9999A4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing],
      ],
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F1F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF6E63DF)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF343849),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9A9AA5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapButton(String url) {
    return InkWell(
      onTap: () => _launchMap(url),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF6E63DF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 20, color: Color(0xFF6E63DF)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'View location on map',
                style: TextStyle(
                  color: Color(0xFF5F55CF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF6E63DF),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _phoneButton(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    return IconButton(
      tooltip: 'Call $phone',
      onPressed: () => _callPhone(phone),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF6E63DF),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.call_outlined, size: 17),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _lightHeaderPill(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
    String label,
    Color color, {
    IconData? icon,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Extra history could not be refreshed. Patient information is '
              'still available.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          TextButton(
            onPressed: _detailsLoading ? null : () => _loadDetails(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _recordsError(String title) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _detailsError ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _loadDetails(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return RefreshIndicator(
      onRefresh: () => _loadDetails(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, size: 30, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF565276).withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      result.add(children[index]);
      if (index < children.length - 1) {
        result.add(const SizedBox(height: 18));
      }
    }
    return result;
  }

  String _value(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not recorded';
    return value.trim();
  }

  String _creatorName() {
    final creatorName = _details.creator?.name.trim();
    if (creatorName?.isNotEmpty == true) {
      return _displayName(creatorName!);
    }

    final fallback = _currentPatient.createdBy?.trim();
    if (fallback == null ||
        fallback.isEmpty ||
        RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(fallback)) {
      return 'Not recorded';
    }
    return _displayName(fallback);
  }

  String _creatorSubtitle() {
    final details = <String>['Created by'];
    final role = _details.creator?.role?.trim();
    final email = _details.creator?.email?.trim();

    if (role?.isNotEmpty == true) {
      details.add(_displayName(role!));
    }
    if (email?.isNotEmpty == true) {
      details.add(email!);
    }

    return details.join(' • ');
  }

  String _displayName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s*,\s*'), ', ');
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not recorded';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not recorded';
    return DateFormat('dd MMM yyyy, h:mm a').format(date.toLocal());
  }

  String _formatVisitDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? _value(value) : _formatDate(date);
  }

  String _visitModeLabel(String mode) {
    switch (mode) {
      case 'new':
        return 'New';
      case 'monthly':
        return 'Monthly';
      case 'emergency':
        return 'Emergency';
      case 'dhc_visit':
        return 'DHC';
      case 'vhc_visit':
        return 'VHC';
      default:
        return mode.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _visitModeColor(String mode) {
    switch (mode) {
      case 'emergency':
        return Colors.red;
      case 'monthly':
        return Colors.blue;
      case 'dhc_visit':
        return Colors.orange;
      case 'vhc_visit':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  String _equipmentStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'returned':
        return 'Returned';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }

  Color _equipmentStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'returned':
        return Colors.blueGrey;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _PatientTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PatientTabsHeaderDelegate({required this.child});

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FA),
        borderRadius: shrinkOffset == 0
            ? const BorderRadius.vertical(top: Radius.circular(30))
            : BorderRadius.zero,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PatientTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
