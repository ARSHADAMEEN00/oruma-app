import 'package:flutter/material.dart';
import 'package:oruma_app/models/equipment.dart';
import 'package:oruma_app/services/equipment_service.dart';

class EquipmentRegistration extends StatefulWidget {
  const EquipmentRegistration({super.key});

  @override
  State<EquipmentRegistration> createState() => _EquipmentRegistrationState();
}

class _EquipmentRegistrationState extends State<EquipmentRegistration> {
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _errorMessage;

  // Controllers
  final TextEditingController purchasedFromController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  // Dropdown Items
  final List<String> items = [
    'Wheelchair',
    'Walker',
    'Oxygen Cylinder',
    'Crutches',
    'Air bed',
    'Hospital cot',
    'Nebulizer',
    'Concentrator',
  ];

  String? selectedValue;

  // List to store saved equipment
  final List<Equipment> equipmentList = [];

  // Serial number counter
  int counter = 1;

  // Generate serial number like WA01, WH02, etc.
  String generateSerial(String name) {
    String prefix = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : 'EQ';
    return "$prefix${counter.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    purchasedFromController.dispose();
    placeController.dispose();
    phoneController.dispose();
    itemNameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> submitEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _errorMessage = 'Quantity must be greater than 0');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await EquipmentService.createEquipment(
        name: itemNameController.text.trim(),
        quantity: qty,
        purchasedFrom: purchasedFromController.text.trim(),
        place: placeController.text.trim(),
        phone: phoneController.text.trim(),
        serialNo: generateSerial(itemNameController.text.trim()),
      );

      setState(() {
        equipmentList.insertAll(0, response.equipment);
        counter += qty;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Equipment saved: ${itemNameController.text.trim()} ($qty items)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _clearForm();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    itemNameController.clear();
    quantityController.clear();
    purchasedFromController.clear();
    placeController.clear();
    phoneController.clear();
    setState(() {
      selectedValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Item Name
              TextFormField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter Item Name' : null,
              ),
              const SizedBox(height: 15),

              // Quantity
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter Quantity' : null,
              ),
              const SizedBox(height: 15),

              // Purchased From
              TextFormField(
                controller: purchasedFromController,
                decoration: const InputDecoration(
                  labelText: 'Purchased From',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter value' : null,
              ),
              const SizedBox(height: 15),

              // Place
              TextFormField(
                controller: placeController,
                decoration: const InputDecoration(
                  labelText: 'Place',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter the place' : null,
              ),
              const SizedBox(height: 15),

              // Phone Number
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Enter the Phone Number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Equipment',
                ),
                hint: const Text('Choose equipment'),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedValue = newValue;
                    if (newValue != null) {
                      itemNameController.text = newValue;
                    }
                  });
                },
                validator: (val) =>
                    val == null ? 'Please select equipment' : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : submitEquipment,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),

              const SizedBox(height: 20),

              // Show list of added equipment
              if (equipmentList.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Recently Added Equipment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: equipmentList.length,
                  itemBuilder: (context, index) {
                    final eq = equipmentList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            eq.serialNo.substring(0, 2),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('${eq.serialNo} - ${eq.name}'),
                        subtitle: Text(
                          'Qty: ${eq.quantity} | From: ${eq.purchasedFrom}\n'
                          'Place: ${eq.place} | Phone: ${eq.phone}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
