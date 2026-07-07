import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/social_support.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/social_support_service.dart';
import 'package:oruma_app/social_support_page.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/reveal_action_fab.dart';
import 'package:provider/provider.dart';

const _supportPrimary = Color(0xFF8A2454);
const _supportDark = Color(0xFF64143A);
const _supportCard = Color(0xFFF7E5EE);
const _supportIcon = Color(0xFFE8AEC9);
const double _filterControlHeight = 56;

class SocialSupportListPage extends StatefulWidget {
  const SocialSupportListPage({super.key});

  @override
  State<SocialSupportListPage> createState() => _SocialSupportListPageState();
}

class _SocialSupportListPageState extends State<SocialSupportListPage> {
  final _searchController = TextEditingController();
  List<SocialSupport> _records = [];
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  DateTimeRange? _dateRange;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        SocialSupportService.getAllSocialSupports(),
        PatientService.getAllPatients(),
      ]);
      if (!mounted) return;
      setState(() {
        _records = results[0] as List<SocialSupport>;
        _patients = results[1] as List<Patient>;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SocialSupport> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((record) {
      if (_selectedPatient != null) {
        final selectedId = _selectedPatient!.id;
        final selectedName = _selectedPatient!.name.toLowerCase();
        final matchesPatient =
            (selectedId != null && record.patientObjectId == selectedId) ||
            record.patientName.toLowerCase() == selectedName;
        if (!matchesPatient) return false;
      }

      if (_dateRange != null) {
        final date = _dateOnly(record.givenAt);
        final start = _dateOnly(_dateRange!.start);
        final end = _dateOnly(_dateRange!.end);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      if (query.isEmpty) return true;
      final haystack = [
        record.patientName,
        record.patientRegisterId,
        record.patientPlace,
        record.patientPhone,
        record.supportTypesLabel,
        record.note,
        record.volunteerName,
        record.volunteerContact,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SocialSupportPage()),
    );
    if (result == true) _loadData();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _supportPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _deleteRecord(SocialSupport record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text(
          'Delete social support record for ${record.patientName}?',
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

    if (confirm != true || record.id == null) return;

    try {
      await SocialSupportService.deleteSocialSupport(record.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Social support record deleted'),
          backgroundColor: _supportPrimary,
        ),
      );
      _loadData(showLoading: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AdaptiveAppScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _supportCard,
        surfaceTintColor: _supportCard,
        foregroundColor: _supportPrimary,
        elevation: 1,
        title: const Text('Social Support', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: auth.canCreate
          ? RevealActionFab(
              onPressed: _openCreate,
              backgroundColor: _supportPrimary,
              foregroundColor: Colors.white,
              icon: Icons.add,
              label: 'New Support',
            )
          : null,
      contentMaxWidth: 820,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody(auth)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: _searchDecoration(),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _dateFilterField()),
              const SizedBox(width: 10),
              Expanded(child: _patientFilter()),
            ],
          ),
          if (_selectedPatient != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_patientLabel(_selectedPatient!)),
                avatar: const Icon(Icons.person_outline, size: 18),
                onDeleted: () => setState(() => _selectedPatient = null),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateFilterField() {
    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: _filterControlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _supportPrimary.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.date_range_outlined,
              size: 20,
              color: _supportPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _dateRangeLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _supportPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_dateRange != null)
              IconButton(
                tooltip: 'Clear date filter',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _dateRange = null),
                icon: const Icon(Icons.close, size: 18),
                color: _supportPrimary,
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      hintText: 'Search patient, type, note or volunteer',
      prefixIcon: const Icon(Icons.search, size: 20),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
            )
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _supportPrimary, width: 1.5),
      ),
    );
  }

  Widget _patientFilter() {
    return SizedBox(
      height: _filterControlHeight,
      child: Autocomplete<Patient>(
        displayStringForOption: _patientLabel,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) return const Iterable<Patient>.empty();
          return _patients.where(
            (patient) =>
                patient.name.toLowerCase().contains(query) ||
                (patient.registerId?.toLowerCase().contains(query) ?? false) ||
                patient.place.toLowerCase().contains(query),
          );
        },
        onSelected: (patient) => setState(() => _selectedPatient = patient),
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return Container(
            height: _filterControlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 20,
                  color: Color(0xFF5A4A51),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Filter by patient',
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AuthService auth) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _supportPrimary),
      );
    }
    if (_error != null) {
      return _errorState();
    }

    final records = _filteredRecords;
    if (records.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      color: _supportPrimary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _recordCard(records[index], auth),
      ),
    );
  }

  Widget _recordCard(SocialSupport record, AuthService auth) {
    return InkWell(
      onTap: () => _showDetails(record),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _supportCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _supportPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _supportIcon,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: _supportDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_patientMeta(record).isNotEmpty) ...[
                        Text(
                          _patientMeta(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _supportPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        DateFormat('dd MMM yyyy').format(record.givenAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.canDelete)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _deleteRecord(record);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _supportChips(record),
            const SizedBox(height: 12),
            _detailLine(
              Icons.person_outline,
              'Volunteer',
              record.volunteerName,
            ),
            const SizedBox(height: 8),
            _detailLine(
              Icons.call_outlined,
              'Contact',
              record.volunteerContact,
            ),
            if (record.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _detailLine(Icons.notes_outlined, 'Note', record.note!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _supportChips(SocialSupport record) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: record.supportTypes.map((type) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_supportTypeIcon(type), color: _supportPrimary, size: 14),
              const SizedBox(width: 5),
              Text(
                socialSupportTypeLabels[type] ?? type,
                style: const TextStyle(
                  color: _supportPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _patientMeta(SocialSupport record) {
    return [
      if (record.patientRegisterId?.trim().isNotEmpty == true)
        'Reg No: ${record.patientRegisterId!.trim()}',
      if (record.patientPlace?.trim().isNotEmpty == true)
        record.patientPlace!.trim(),
    ].join(' • ');
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _supportPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF343849), fontSize: 13),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDetails(SocialSupport record) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _supportIcon,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: _supportDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_patientMeta(record).isNotEmpty)
                        Text(
                          _patientMeta(record),
                          style: const TextStyle(
                            color: _supportPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        DateFormat('dd MMM yyyy').format(record.givenAt),
                        style: const TextStyle(color: _supportPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _supportChips(record),
            const SizedBox(height: 18),
            _detailLine(
              Icons.person_outline,
              'Volunteer',
              record.volunteerName,
            ),
            const SizedBox(height: 10),
            _detailLine(
              Icons.call_outlined,
              'Contact',
              record.volunteerContact,
            ),
            if (record.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _detailLine(Icons.notes_outlined, 'Note', record.note!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final hasFilters =
        _searchController.text.isNotEmpty ||
        _selectedPatient != null ||
        _dateRange != null;
    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      color: _supportPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasFilters
                        ? Icons.search_off_outlined
                        : Icons.volunteer_activism_outlined,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hasFilters
                        ? 'No matching records'
                        : 'No social support records',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel() {
    if (_dateRange == null) return 'All dates';
    final formatter = DateFormat('dd MMM');
    return '${formatter.format(_dateRange!.start)} - ${formatter.format(_dateRange!.end)}';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  IconData _supportTypeIcon(String type) {
    return switch (type) {
      'vegetables' => Icons.eco_outlined,
      'medicine' => Icons.medication_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }

  String _patientLabel(Patient patient) {
    final details = [
      if (patient.registerId?.isNotEmpty == true) patient.registerId,
      if (patient.place.isNotEmpty) patient.place,
    ].whereType<String>().join(' • ');
    return details.isEmpty ? patient.name : '${patient.name} - $details';
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
