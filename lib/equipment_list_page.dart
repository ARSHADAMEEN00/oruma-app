import 'package:flutter/material.dart';
import 'package:oruma_app/eq_supply.dart'; // Import for Distribute Page
import 'package:oruma_app/models/equipment.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:oruma_app/services/equipment_service.dart';
import 'package:oruma_app/services/equipment_supply_service.dart';

class EquipmentListPage extends StatefulWidget {
  const EquipmentListPage({super.key});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Available list data
  List<Equipment> _availableItems = [];
  bool _loadingAvailable = true;
  String? _errorAvailable;

  // Distributed list data
  List<EquipmentSupply> _distributedItems = [];
  bool _loadingDistributed = true;
  String? _errorDistributed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        _fetchAvailableEquipment();
      } else {
        _fetchDistributedEquipment();
      }
      if (mounted) setState(() {});
    }
  }

  void _loadAllData() {
    _fetchAvailableEquipment();
    _fetchDistributedEquipment();
  }

  Future<void> _fetchAvailableEquipment() async {
    setState(() {
      _loadingAvailable = true;
      _errorAvailable = null;
    });

    try {
      final list = await EquipmentService.getAvailableEquipment();
      if (mounted) setState(() => _availableItems = list);
    } catch (e) {
      if (mounted) setState(() => _errorAvailable = e.toString());
    } finally {
      if (mounted) setState(() => _loadingAvailable = false);
    }
  }

  Future<void> _fetchDistributedEquipment() async {
    setState(() {
      _loadingDistributed = true;
      _errorDistributed = null;
    });

    try {
      final list = await EquipmentSupplyService.getActiveSupplies();
      if (mounted) setState(() => _distributedItems = list);
    } catch (e) {
      if (mounted) setState(() => _errorDistributed = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDistributed = false);
    }
  }

  void _navigateToAdd() {
    if (_tabController.index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EquipmentFormPage()),
      ).then((val) {
        if (val == true) _fetchAvailableEquipment();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EqSupply()),
      ).then((val) {
        if (val == true) _fetchDistributedEquipment();
      });
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
        title: const Text('Equipment List', style: TextStyle(fontWeight: FontWeight.bold)),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'Distributed'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               _fetchAvailableEquipment();
               _fetchDistributedEquipment();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Equipment' : 'Distribute'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableList(),
          _buildDistributedList(),
        ],
      ),
    );
  }

  // --- Available List Tab ---
  Widget _buildAvailableList() {
    if (_loadingAvailable) return const Center(child: CircularProgressIndicator());
    if (_errorAvailable != null) return Center(child: Text('Error: $_errorAvailable'));
    if (_availableItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No available equipment.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _availableItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final eq = _availableItems[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Icon(Icons.medical_services, color: Colors.indigo.shade400),
            ),
            title: Text(
              eq.uniqueId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${eq.name}\n${eq.place}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EquipmentEditPage(equipment: eq),
                    ),
                  ).then((result) {
                    if (result == true) _fetchAvailableEquipment();
                  });
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete?'),
                      content: Text('Delete ${eq.uniqueId}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await EquipmentService.deleteEquipment(eq.id!);
                    _fetchAvailableEquipment();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
            onTap: () {
               Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EquipmentDetailPage(equipment: eq)),
                ).then((_) => _fetchAvailableEquipment());
            }
          ),
        );
      },
    );
  }

  // --- Distributed List Tab ---
  Widget _buildDistributedList() {
    if (_loadingDistributed) return const Center(child: CircularProgressIndicator());
    if (_errorDistributed != null) return Center(child: Text('Error: $_errorDistributed'));
    if (_distributedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No distributed equipment.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _distributedItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final supply = _distributedItems[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Icon(Icons.person, color: Colors.orange.shade400),
            ),
            title: Text(
              supply.patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${supply.equipmentUniqueId} - ${supply.equipmentName}'),
                Text('Supplied: ${_formatDate(supply.supplyDate)}'),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'return') _returnSupply(supply);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'return',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_return, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Mark Returned'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _returnSupply(EquipmentSupply supply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Return'),
        content: Text('Mark ${supply.equipmentUniqueId} as returned from ${supply.patientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true && supply.id != null) {
      try {
        await EquipmentSupplyService.returnSupply(supply.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Equipment returned')),
          );
          _fetchDistributedEquipment();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      }
    }
  }
}

// ============================================
// EQUIPMENT DETAIL PAGE, FORM PAGE, EDIT PAGE
// ============================================

// Detail Page
class EquipmentDetailPage extends StatefulWidget {
  final Equipment equipment;
  const EquipmentDetailPage({super.key, required this.equipment});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  Equipment? _equipment;
  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_equipment?.name ?? 'Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unique ID: ${_equipment?.uniqueId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Name: ${_equipment?.name}'),
            Text('Status: ${_equipment?.status}'),
            Text('Place: ${_equipment?.place}'),
            Text('Purchased From: ${_equipment?.purchasedFrom}'),
            Text('Phone: ${_equipment?.phone}'),
          ],
        ),
      ),
    );
  }
}

// Form Page (Create Bulk) - Same as previous logic
class EquipmentFormPage extends StatefulWidget {
  const EquipmentFormPage({super.key});

  @override
  State<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _purchasedFromController = TextEditingController();
  final _placeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await EquipmentService.createEquipment(
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        purchasedFrom: _purchasedFromController.text.trim(),
        place: _placeController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Created ${response.count} items")));
         Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchasedFromController.dispose();
    _placeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Equipment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade400,
                          Colors.indigo.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'New Equipment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details to add new equipment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment Details Card
                    _buildSectionCard(
                      title: 'Equipment Details',
                      icon: Icons.inventory_2_rounded,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Equipment Name',
                          hint: 'e.g., Wheelchair, Oxygen Cylinder',
                          icon: Icons.medical_services_outlined,
                          validator: (v) => v!.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _quantityController,
                          label: 'Quantity',
                          hint: 'Number of items',
                          icon: Icons.numbers_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Quantity is required';
                            final num = int.tryParse(v);
                            if (num == null || num < 1) return 'Enter a valid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Purchase Info Card
                    _buildSectionCard(
                      title: 'Purchase Information',
                      icon: Icons.shopping_bag_rounded,
                      children: [
                        _buildTextField(
                          controller: _purchasedFromController,
                          label: 'Purchased From',
                          hint: 'Vendor or store name',
                          icon: Icons.store_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Contact Phone',
                          hint: 'Vendor phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Location Card
                    _buildSectionCard(
                      title: 'Storage Location',
                      icon: Icons.location_on_rounded,
                      children: [
                        _buildTextField(
                          controller: _placeController,
                          label: 'Place',
                          hint: 'Where the equipment is stored',
                          icon: Icons.place_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.indigo.shade300,
                          elevation: 2,
                          shadowColor: Colors.indigo.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'Create Equipment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// Edit Page (Single Item)
class EquipmentEditPage extends StatefulWidget {
  final Equipment equipment;
  const EquipmentEditPage({super.key, required this.equipment});

  @override
  State<EquipmentEditPage> createState() => _EquipmentEditPageState();
}

class _EquipmentEditPageState extends State<EquipmentEditPage> {
  // Simplified edit page logic
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _placeController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _placeController = TextEditingController(text: widget.equipment.place);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
     await EquipmentService.updateEquipment(widget.equipment.id!, name: _nameController.text, place: _placeController.text);
     if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit')),
      body: Padding(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        TextFormField(controller: _placeController, decoration: const InputDecoration(labelText: 'Place')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ]))),
    );
  }
}
