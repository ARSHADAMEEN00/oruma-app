import 'package:flutter/material.dart';
import 'package:oruma_app/eq_supply.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:oruma_app/services/equipment_supply_service.dart';

class EquipmentSupplyListPage extends StatefulWidget {
  const EquipmentSupplyListPage({super.key});

  @override
  State<EquipmentSupplyListPage> createState() =>
      _EquipmentSupplyListPageState();
}

class _EquipmentSupplyListPageState extends State<EquipmentSupplyListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active supplies (currently distributed)
  List<EquipmentSupply> _activeSupplies = [];
  bool _loadingActive = true;
  String? _errorActive;

  // All supplies (history)
  List<EquipmentSupply> _allSupplies = [];
  bool _loadingAll = true;
  String? _errorAll;

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  void _loadData() {
    _fetchActiveSupplies();
    _fetchAllSupplies();
  }

  Future<void> _fetchActiveSupplies() async {
    setState(() {
      _loadingActive = true;
      _errorActive = null;
    });

    try {
      final list = await EquipmentSupplyService.getActiveSupplies();
      if (mounted) setState(() => _activeSupplies = list);
    } catch (e) {
      if (mounted) setState(() => _errorActive = e.toString());
    } finally {
      if (mounted) setState(() => _loadingActive = false);
    }
  }

  Future<void> _fetchAllSupplies() async {
    setState(() {
      _loadingAll = true;
      _errorAll = null;
    });

    try {
      final list = await EquipmentSupplyService.getAllSupplies();
      if (mounted) setState(() => _allSupplies = list);
    } catch (e) {
      if (mounted) setState(() => _errorAll = e.toString());
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  void _navigateToCreateSupply() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EqSupply()),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _returnSupply(EquipmentSupply supply) async {
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.assignment_return, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirm Return'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark "${supply.equipmentUniqueId}" as returned from ${supply.patientName}?',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // Date Picker Field
                const Text(
                  'Return Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: supply.supplyDate,
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note Field
                TextField(
                  controller: noteController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Return Note (Optional)',
                    labelStyle: const TextStyle(fontSize: 13),
                    hintText: 'Condition of equipment, etc.',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'confirmed': true,
                'date': selectedDate,
                'note': noteController.text.trim(),
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Returned'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['confirmed'] == true && supply.id != null) {
      try {
        await EquipmentSupplyService.returnSupply(
          supply.id!,
          date: result['date'],
          note: result['note'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Equipment marked as returned'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search supplies...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : const Text(
                'Equipment Supplies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.indigo,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions, size: 18),
                      const SizedBox(width: 6),
                      const Text('Active'),
                      if (_activeSupplies.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_activeSupplies.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 6),
                      Text('History'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateSupply,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Supply'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveList(), _buildHistoryList()],
      ),
    );
  }

  // --- Active Supplies Tab ---
  Widget _buildActiveList() {
    if (_loadingActive) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorActive != null) {
      return _buildErrorWidget(_errorActive!, _fetchActiveSupplies);
    }
    final filteredList = _activeSupplies.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.patientName.toLowerCase().contains(q) ||
          s.equipmentName.toLowerCase().contains(q) ||
          s.equipmentUniqueId.toLowerCase().contains(q) ||
          s.patientPhone.toLowerCase().contains(q);
    }).toList();

    if (filteredList.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _buildEmptyWidget(
          icon: Icons.search_off,
          title: 'No results found',
          subtitle: 'Try a different search term',
        );
      }
      return _buildEmptyWidget(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No Active Supplies',
        subtitle: 'All equipment has been returned',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveSupplies,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final supply = filteredList[index];
          return _buildSupplyCard(supply, isActive: true);
        },
      ),
    );
  }

  // --- History Tab (All Supplies) ---
  Widget _buildHistoryList() {
    if (_loadingAll) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorAll != null) {
      return _buildErrorWidget(_errorAll!, _fetchAllSupplies);
    }
    final filteredList = _allSupplies.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.patientName.toLowerCase().contains(q) ||
          s.equipmentName.toLowerCase().contains(q) ||
          s.equipmentUniqueId.toLowerCase().contains(q) ||
          s.patientPhone.toLowerCase().contains(q);
    }).toList();

    if (filteredList.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _buildEmptyWidget(
          icon: Icons.search_off,
          title: 'No results found',
          subtitle: 'Try a different search term',
        );
      }
      return _buildEmptyWidget(
        icon: Icons.history,
        title: 'No Supply History',
        subtitle: 'Start by distributing equipment',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllSupplies,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final supply = filteredList[index];
          return _buildSupplyCard(supply, isActive: supply.status == 'active');
        },
      ),
    );
  }

  Widget _buildSupplyCard(EquipmentSupply supply, {required bool isActive}) {
    final statusColor = _getStatusColor(supply.status);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSupplyDetails(supply),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Patient Avatar
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.person, color: Colors.orange.shade400),
                  ),
                  const SizedBox(width: 12),
                  // Patient Name & Equipment
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supply.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${supply.equipmentUniqueId} • ${supply.equipmentName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      supply.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Details Row
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.phone,
                    label: supply.patientPhone,
                  ),
                  const SizedBox(width: 16),
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: _formatDate(supply.supplyDate),
                  ),
                ],
              ),
              // Actions for active supplies
              if (isActive) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _returnSupply(supply),
                      icon: const Icon(Icons.assignment_return, size: 18),
                      label: const Text('Mark Returned'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyWidget({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSupplyDetails(EquipmentSupply supply) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange.shade50,
                  child: Icon(
                    Icons.medical_services,
                    color: Colors.orange.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supply.equipmentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        supply.equipmentUniqueId,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(supply.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    supply.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(supply.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Patient Details
            _buildDetailRow(Icons.person, 'Patient', supply.patientName),
            _buildDetailRow(Icons.phone, 'Phone', supply.patientPhone),
            if (supply.patientAddress != null &&
                supply.patientAddress!.isNotEmpty)
              _buildDetailRow(
                Icons.location_on,
                'Address',
                supply.patientAddress!,
              ),
            _buildDetailRow(
              Icons.calendar_today,
              'Supply Date',
              _formatDate(supply.supplyDate),
            ),
            if (supply.returnDate != null)
              _buildDetailRow(
                Icons.event_available,
                'Expected Return',
                _formatDate(supply.returnDate!),
              ),
            if (supply.actualReturnDate != null)
              _buildDetailRow(
                Icons.check_circle_outlined,
                'Returned On',
                _formatDate(supply.actualReturnDate!),
              ),
            if (supply.notes != null && supply.notes!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notes', supply.notes!),
            if (supply.returnNote != null && supply.returnNote!.isNotEmpty)
              _buildDetailRow(
                Icons.assignment_return_outlined,
                'Return Notes',
                supply.returnNote!,
              ),
            if (supply.createdBy != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created by: ${supply.createdBy}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                    if (supply.createdAt != null)
                      Text(
                        'Created on: ${_formatDate(supply.createdAt!)}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'returned':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
