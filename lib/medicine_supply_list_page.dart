import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/medicine_supply_page.dart';
import 'package:oruma_app/medicine_list_page.dart';
import 'package:oruma_app/models/medicine_supply.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/medicine.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/feature_permissions.dart';
import 'package:oruma_app/services/medicine_supply_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/medicine_service.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:oruma_app/widgets/app_bottom_nav_router.dart';
import 'package:oruma_app/widgets/feature_permission_gate.dart';
import 'package:oruma_app/widgets/module_switch_tabs.dart';
import 'package:oruma_app/widgets/reveal_action_fab.dart';

const _medicineGreen = Color(0xFF0F6E56);
const _cardBg = Color(0xFFE1F5EE);
const _iconBg = Color(0xFF9FE1CB);

class MedicineSupplyListPage extends StatefulWidget {
  const MedicineSupplyListPage({super.key});

  @override
  State<MedicineSupplyListPage> createState() => _MedicineSupplyListPageState();
}

class _MedicineSupplyListPageState extends State<MedicineSupplyListPage> {
  List<MedicineSupply> _supplies = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Given', 'Returned', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _searchQuery = query);
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final list = await MedicineSupplyService.getAllMedicineSupplies();
      if (!mounted) return;
      setState(() {
        _supplies = list;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _navigateToCreateSupply() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicineSupplyPage()),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  bool _matchesSearch(MedicineSupply supply) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return supply.patientName.toLowerCase().contains(q) ||
        supply.medicineName.toLowerCase().contains(q) ||
        supply.medicineSummary.toLowerCase().contains(q);
  }

  void _handleBottomNavigation(BuildContext context, AppBottomSection section) {
    AppBottomNavRouter.handle(
      context,
      current: AppBottomSection.medicine,
      target: section,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AdaptiveAppScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _cardBg,
        surfaceTintColor: _cardBg,
        foregroundColor: _medicineGreen,
        elevation: 1,
        title: ModuleSwitchTabs(
          labels: const ['Supplies', 'Medicines'],
          icons: const [
            Icons.assignment_turned_in_outlined,
            Icons.medication_liquid_outlined,
          ],
          selectedIndex: 0,
          color: _medicineGreen,
          onSelected: (index) {
            if (index == 1) {
              if (!FeaturePermissionMiddleware.ensure(
                context,
                AppFeature.medicineMaster,
                moduleName: 'Medicine',
              )) {
                return;
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicineListPage(),
                ),
              );
            }
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: auth.canCreate && auth.canAccessMedicineSupply
          ? RevealActionFab(
              onPressed: _navigateToCreateSupply,
              backgroundColor: _medicineGreen,
              foregroundColor: Colors.white,
              icon: Icons.add,
              label: 'New Supply',
            )
          : null,
      currentSection: AppBottomSection.medicine,
      onNavigationSelected: (section) =>
          _handleBottomNavigation(context, section),
      contentMaxWidth: 820,
      body: Column(
        children: [
          _buildSearchBarAndTabs(),
          Expanded(child: _buildList(auth)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by patient or medicine',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
            borderSide: const BorderSide(color: _medicineGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarAndTabs() {
    return Column(
      children: [
        _buildSearchBar(),
        Container(
          height: 48,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = _selectedTab == tab;
              return Center(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = tab),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _medicineGreen : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _medicineGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(AuthService auth) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _medicineGreen),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    var filteredList = _supplies.where(_matchesSearch).toList();
    if (_selectedTab != 'All') {
      filteredList = filteredList
          .where((s) => s.status?.toLowerCase() == _selectedTab.toLowerCase())
          .toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No Medicine Supplies',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      color: _medicineGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final supply = filteredList[index];
          return _buildSupplyCard(supply, auth);
        },
      ),
    );
  }

  Future<void> _returnSupply(MedicineSupply supply) async {
    if (supply.id == null || supply.status != 'given') return;

    final qtyController = TextEditingController(
      text: supply.qtyGiven.toString(),
    );
    final noteController = TextEditingController();
    var returnDate = DateTime.now();
    var expiryDate = DateTime.now().add(const Duration(days: 365));

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> pickReturnDate() async {
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: returnDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setDialogState(() => returnDate = picked);
                }
              }

              Future<void> pickExpiryDate() async {
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: expiryDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(DateTime.now().year + 30),
                );
                if (picked != null) {
                  setDialogState(() => expiryDate = picked);
                }
              }

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                title: const Text('Return Medicine'),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Returned Quantity',
                            helperText: 'Max: ${supply.qtyGiven}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _dateTile(
                          title: 'Return Date',
                          date: returnDate,
                          onTap: pickReturnDate,
                        ),
                        const SizedBox(height: 8),
                        _dateTile(
                          title: 'Expiry Date',
                          date: expiryDate,
                          onTap: pickExpiryDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            hintText: 'Optional',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final qty = int.tryParse(qtyController.text.trim());
                      if (qty == null || qty <= 0 || qty > supply.qtyGiven) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid quantity'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirm != true) return;

      await MedicineSupplyService.returnMedicineSupply(
        supply.id!,
        qtyReturned: int.parse(qtyController.text.trim()),
        returnedAt: returnDate,
        expiryDate: expiryDate,
        staffNote: noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine returned and batch created'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      qtyController.dispose();
      noteController.dispose();
    }
  }

  Future<void> _cancelSupply(MedicineSupply supply) async {
    if (supply.id == null || supply.status != 'given') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Supply'),
        content: const Text(
          'Cancel this supply and restore the medicines to their original batches?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Supply'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await MedicineSupplyService.cancelMedicineSupply(supply.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supply cancelled'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling supply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSupplyDetails(MedicineSupply supply) {
    Patient? patient;
    Medicine? medicine;
    bool loading = true;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (loading && patient == null && error == null) {
            Future.wait([
                  supply.patientId is String
                      ? PatientService.getPatientById(
                          supply.patientId as String,
                        )
                      : Future.value(
                          Patient.fromJson(
                            supply.patientId as Map<String, dynamic>,
                          ),
                        ),
                  supply.medicineId is String
                      ? MedicineService.getMedicineById(
                          supply.medicineId as String,
                        )
                      : Future.value(
                          Medicine.fromJson(
                            supply.medicineId as Map<String, dynamic>,
                          ),
                        ),
                ])
                .then((results) {
                  if (mounted) {
                    setModalState(() {
                      patient = results[0] as Patient;
                      medicine = results[1] as Medicine;
                      loading = false;
                    });
                  }
                })
                .catchError((e) {
                  if (mounted) {
                    setModalState(() {
                      error = e.toString();
                      loading = false;
                    });
                  }
                });
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: _medicineGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supply.medicineName,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              supply.patientName,
                              style: const TextStyle(color: _medicineGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _medicineGreen),
                      ),
                    )
                  else if (error != null)
                    Center(
                      child: Text(
                        'Error loading details: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else ...[
                    const Text(
                      'Supply Information',
                      style: TextStyle(fontSize: 16, color: _medicineGreen),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Status',
                      supply.status?.toUpperCase() ?? 'GIVEN',
                    ),
                    _buildDetailRow('Quantity', '${supply.qtyGiven}'),
                    if (supply.items.isNotEmpty)
                      _buildDetailRow('Medicines', supply.medicineSummary),
                    _buildDetailRow(
                      'Date',
                      '${supply.givenAt.day}/${supply.givenAt.month}/${supply.givenAt.year}',
                    ),
                    if (supply.supplyDays != null)
                      _buildDetailRow(
                        'Supply Days',
                        '${supply.supplyDays} Days',
                      ),
                    if (supply.prescribedBy != null)
                      _buildDetailRow('Prescribed By', supply.prescribedBy!),
                    if (supply.staffNote != null)
                      _buildDetailRow('Staff Note', supply.staffNote!),
                    if (supply.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Batch Details',
                        style: TextStyle(fontSize: 16, color: _medicineGreen),
                      ),
                      const SizedBox(height: 12),
                      ...supply.items.map(_buildSupplyItemRow),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),

                    const Text(
                      'Medicine Details',
                      style: TextStyle(fontSize: 16, color: _medicineGreen),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Category',
                      medicine!.category
                          .split('_')
                          .map((e) => e[0].toUpperCase() + e.substring(1))
                          .join(' '),
                    ),
                    _buildDetailRow('Code', medicine!.code),
                    if (medicine!.formulation != null)
                      _buildDetailRow('Formulation', medicine!.formulation!),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),

                    const Text(
                      'Patient Details',
                      style: TextStyle(fontSize: 16, color: _medicineGreen),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Phone', patient!.phone),
                    _buildDetailRow(
                      'Age/Gender',
                      [
                        if (patient!.age > 0) '${patient!.age} yrs',
                        if (patient!.gender.isNotEmpty) patient!.gender,
                      ].join(' / '),
                    ),
                    _buildDetailRow(
                      'Address',
                      [
                        patient!.address,
                        patient!.place,
                      ].where((e) => e.trim().isNotEmpty).join(', '),
                    ),
                    _buildDetailRow('Diagnosis', patient!.disease.join(', ')),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _medicineGreen,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.trim().isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyItemRow(MedicineSupplyItem item) {
    final expiry = item.expiryDate;
    final unit = item.qtyUnit.trim();
    final qty = unit.isEmpty ? '${item.qtyGiven}' : '${item.qtyGiven} $unit';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _iconBg.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: _medicineGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _medicineGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.batchNumber} • Exp ${expiry == null ? 'Not recorded' : '${expiry.day}/${expiry.month}/${expiry.year}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _itemSourceText(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            qty,
            style: const TextStyle(
              color: _medicineGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _quantityStatusText(MedicineSupply supply) {
    if (supply.status != 'returned') return 'Qty: ${supply.qtyGiven}';

    final returnedText =
        'Given: ${supply.qtyGiven} • Ret: ${supply.qtyReturned ?? supply.qtyGiven}';
    final returnedAt = supply.returnedAt;
    if (returnedAt == null) return returnedText;

    return '$returnedText (${returnedAt.day}/${returnedAt.month}/${returnedAt.year})';
  }

  String _itemSourceText(MedicineSupplyItem item) {
    final label = item.sourceLabel.trim().isEmpty
        ? 'Main Stock'
        : item.sourceLabel.trim();
    final patientName = item.sourcePatientName?.trim();
    if (label.toLowerCase() == 'return' &&
        patientName != null &&
        patientName.isNotEmpty) {
      return '$label • $patientName';
    }
    return label;
  }

  Widget _dateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey.shade100,
      title: Text(title),
      subtitle: Text('${date.day}/${date.month}/${date.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  String _statusText(MedicineSupply supply) {
    final status = supply.status ?? 'given';
    return switch (status) {
      'returned' => 'Returned',
      'cancelled' => 'Cancelled',
      'partially_given' => 'Partially Given',
      _ => 'Given',
    };
  }

  Widget _buildSupplyCard(MedicineSupply supply, AuthService auth) {
    Color statusColor = _medicineGreen;
    if (supply.status == 'cancelled') statusColor = Colors.red;
    if (supply.status == 'returned') statusColor = Colors.orange;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSupplyDetails(supply),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                _statusText(supply).toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${supply.givenAt.day}/${supply.givenAt.month}/${supply.givenAt.year}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (auth.canEdit &&
                                    supply.status == 'given') ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Return medicine',
                                    onPressed: () => _returnSupply(supply),
                                    icon: const Icon(
                                      Icons.assignment_return_outlined,
                                      size: 18,
                                    ),
                                    style: IconButton.styleFrom(
                                      foregroundColor: _medicineGreen,
                                      backgroundColor: _medicineGreen
                                          .withValues(alpha: 0.08),
                                      minimumSize: const Size(32, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Cancel supply',
                                    onPressed: () => _cancelSupply(supply),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                    ),
                                    style: IconButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      backgroundColor: Colors.red.shade50,
                                      minimumSize: const Size(32, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          supply.patientName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF2D3142),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supply.medicineSummary,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _quantityStatusText(supply),
                              style: TextStyle(
                                color: supply.status == 'returned'
                                    ? Colors.orange.shade800
                                    : Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: supply.status == 'returned'
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (supply.supplyDays != null) ...[
                              Icon(
                                Icons.calendar_month,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${supply.supplyDays} Days',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }
}
