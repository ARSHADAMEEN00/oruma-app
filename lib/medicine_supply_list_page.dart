import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/medicine_supply_page.dart';
import 'package:oruma_app/medicine_list_page.dart';
import 'package:oruma_app/models/medicine_supply.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/medicine.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/medicine_supply_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/medicine_service.dart';

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
        supply.medicineName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _cardBg,
        surfaceTintColor: _cardBg,
        foregroundColor: _medicineGreen,
        elevation: 1,
        title: const Text(
          'Medicine Supplies',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicineListPage(),
                ),
              );
            },
            icon: const Icon(Icons.medication_outlined, size: 18),
            label: const Text('Medicines'),
            style: TextButton.styleFrom(
              foregroundColor: _medicineGreen,
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: auth.canCreate
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateSupply,
              backgroundColor: _medicineGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Supply'),
            )
          : null,
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
            borderSide: const BorderSide(
              color: _medicineGreen,
              width: 1.5,
            ),
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
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = _selectedTab == tab;
              return Center(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = tab),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _medicineGreen : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _medicineGreen : Colors.grey.shade300),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
      return const Center(child: CircularProgressIndicator(color: _medicineGreen));
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
      filteredList = filteredList.where((s) => s.status?.toLowerCase() == _selectedTab.toLowerCase()).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.assignment_turned_in_outlined,
              size: 64, color: Colors.grey.shade400
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No results found' : 'No Medicine Supplies',
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final supply = filteredList[index];
          return _buildSupplyCard(supply, auth);
        },
      ),
    );
  }

  Future<void> _deleteSupply(MedicineSupply supply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supply'),
        content: Text('Are you sure you want to delete the supply record for ${supply.medicineName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && supply.id != null) {
      try {
        await MedicineSupplyService.deleteMedicineSupply(supply.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supply deleted successfully'), backgroundColor: Colors.green),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting supply: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _changeStatus(MedicineSupply supply, String newStatus) async {
    if (supply.status == newStatus) return;
    try {
      final updated = MedicineSupply(
        id: supply.id,
        patientId: supply.patientId,
        medicineId: supply.medicineId,
        givenByStaff: supply.givenByStaff,
        givenAt: supply.givenAt,
        qtyGiven: supply.qtyGiven,
        status: newStatus,
        staffNote: supply.staffNote,
        prescribedBy: supply.prescribedBy,
        supplyDays: supply.supplyDays,
        doctorPrescription: supply.doctorPrescription,
      );
      await MedicineSupplyService.updateMedicineSupply(supply.id!, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated'), backgroundColor: Colors.green));
      }
      _loadData(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red));
      }
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
              supply.patientId is String ? PatientService.getPatientById(supply.patientId as String) : Future.value(Patient.fromJson(supply.patientId as Map<String, dynamic>)),
              supply.medicineId is String ? MedicineService.getMedicineById(supply.medicineId as String) : Future.value(Medicine.fromJson(supply.medicineId as Map<String, dynamic>)),
            ]).then((results) {
              if (mounted) {
                setModalState(() {
                  patient = results[0] as Patient;
                  medicine = results[1] as Medicine;
                  loading = false;
                });
              }
            }).catchError((e) {
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
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.medication, color: _medicineGreen),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(supply.medicineName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(supply.patientName, style: const TextStyle(color: _medicineGreen, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _medicineGreen)))
                  else if (error != null)
                    Center(child: Text('Error loading details: $error', style: const TextStyle(color: Colors.red)))
                  else ...[
                    const Text('Supply Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _medicineGreen)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Status', supply.status?.toUpperCase() ?? 'GIVEN'),
                    _buildDetailRow('Quantity', '${supply.qtyGiven}'),
                    _buildDetailRow('Date', '${supply.givenAt.day}/${supply.givenAt.month}/${supply.givenAt.year}'),
                    if (supply.supplyDays != null) _buildDetailRow('Supply Days', '${supply.supplyDays} Days'),
                    if (supply.prescribedBy != null) _buildDetailRow('Prescribed By', supply.prescribedBy!),
                    if (supply.staffNote != null) _buildDetailRow('Staff Note', supply.staffNote!),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                    
                    const Text('Medicine Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _medicineGreen)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Category', medicine!.category.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')),
                    _buildDetailRow('Code', medicine!.code),
                    if (medicine!.formulation != null) _buildDetailRow('Formulation', medicine!.formulation!),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                    
                    const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _medicineGreen)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Phone', patient!.phone),
                    _buildDetailRow('Age/Gender', '${patient!.age} yrs / ${patient!.gender}'),
                    _buildDetailRow('Address', '${patient!.address}, ${patient!.place}'),
                    _buildDetailRow('Diagnosis', patient!.disease.join(', ')),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _medicineGreen),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
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
            color: Colors.black.withOpacity(0.04),
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
                        PopupMenuButton<String>(
                          initialValue: supply.status ?? 'given',
                          onSelected: (value) => _changeStatus(supply, value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  supply.status?.toUpperCase() ?? 'GIVEN',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (auth.canEdit) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade600),
                                ],
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            if (auth.canEdit) ...[
                              const PopupMenuItem(value: 'given', child: Text('Given')),
                              const PopupMenuItem(value: 'returned', child: Text('Returned')),
                              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                            ] else ...[
                              PopupMenuItem(value: supply.status ?? 'given', child: Text(supply.status?.toUpperCase() ?? 'GIVEN')),
                            ],
                          ],
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
                            if (auth.canDelete) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _deleteSupply(supply),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
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
                      supply.medicineName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          'Qty: ${supply.qtyGiven}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (supply.supplyDays != null) ...[
                          Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade400),
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

if (auth.canDelete) {
      return Slidable(
        key: ValueKey(supply.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _deleteSupply(supply),
              backgroundColor: const Color(0xFFFE4A49),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
