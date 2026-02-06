import 'package:flutter/material.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:oruma_app/services/equipment_supply_service.dart';

class EqSupplyEdit extends StatefulWidget {
  final EquipmentSupply supply;
  const EqSupplyEdit({super.key, required this.supply});

  @override
  State<EqSupplyEdit> createState() => _EqSupplyEditState();
}

class _EqSupplyEditState extends State<EqSupplyEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _careOfController;
  late TextEditingController _receiverNameController;
  late TextEditingController _receiverPhoneController;
  late TextEditingController _receiverAddressController;
  late TextEditingController _receiverPlaceController;
  
  bool _submitting = false;
  bool _loading = true;
  late EquipmentSupply _supply;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty values
    _notesController = TextEditingController();
    _careOfController = TextEditingController();
    _receiverNameController = TextEditingController();
    _receiverPhoneController = TextEditingController();
    _receiverAddressController = TextEditingController();
    _receiverPlaceController = TextEditingController();
    
    _loadSupplyData();
  }

  Future<void> _loadSupplyData() async {
    try {
      final supply = await EquipmentSupplyService.getById(widget.supply.id!);
      if (mounted) {
        setState(() {
          _supply = supply;
          _notesController.text = supply.notes ?? '';
          _careOfController.text = supply.careOf ?? '';
          _receiverNameController.text = supply.receiverName ?? '';
          _receiverPhoneController.text = supply.receiverPhone ?? '';
          _receiverAddressController.text = supply.receiverAddress ?? '';
          _receiverPlaceController.text = supply.receiverPlace ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading supply: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _careOfController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverPlaceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final updates = {
        'careOf': _careOfController.text.trim(),
        'receiverName': _receiverNameController.text.trim(),
        'receiverPhone': _receiverPhoneController.text.trim(),
        'receiverAddress': _receiverAddressController.text.trim(),
        'receiverPlace': _receiverPlaceController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      await EquipmentSupplyService.updateSupply(widget.supply.id!, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Equipment supply updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          'Edit Equipment Supply',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Loading supply details...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Equipment Info Card
                          _buildSectionCard(
                            title: 'Equipment Details',
                            icon: Icons.inventory_2_outlined,
                            iconColor: Colors.blue,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _supply.equipmentName.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${_supply.equipmentUniqueId}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Handover Details
                          _buildSectionCard(
                            title: 'Handover & Receiver',
                            icon: Icons.handshake_outlined,
                            iconColor: Colors.teal,
                            children: [
                              _buildTextField(
                                controller: _careOfController,
                                label: 'C/O (Care Of)',
                                hint: 'Guardian Name',
                                icon: Icons.supervised_user_circle_outlined,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _receiverNameController,
                                      label: 'Name',
                                      hint: 'Name',
                                      icon: Icons.person_pin_circle_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _receiverPhoneController,
                                      label: 'Phone',
                                      hint: 'Phone',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _receiverAddressController,
                                label: 'Address',
                                hint: 'Address',
                                icon: Icons.location_on_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _receiverPlaceController,
                                label: 'Place',
                                hint: 'Place',
                                icon: Icons.map_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _notesController,
                                label: 'Notes',
                                hint: 'Any additional instructions...',
                                icon: Icons.notes_rounded,
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: Colors.grey.shade700,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor: Colors.orange.shade200,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
