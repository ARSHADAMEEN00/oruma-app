import 'package:flutter/material.dart';

class EquipmentRegistration extends StatefulWidget {
  const EquipmentRegistration({Key? key}) : super(key: key);

  @override
  State<EquipmentRegistration> createState() => _EquipmentRegistrationState();
}

class _EquipmentRegistrationState extends State<EquipmentRegistration> {
  final _formKey = GlobalKey<FormState>();

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

  void submitEquipment() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(quantityController.text);

      for (int i = 0; i < qty; i++) {
        final equipment = Equipment(
          serialNo: generateSerial(itemNameController.text),
          name: itemNameController.text,
          quantity: 1, // each entry = 1 item
          purchasedFrom: purchasedFromController.text,
          place: placeController.text,
          phone: phoneController.text,
        );

        setState(() {
          equipmentList.add(equipment);
          counter++; // increase per item
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $qty ${itemNameController.text}(s)')),
      );

      // clear fields after submission
      itemNameController.clear();
      quantityController.clear();
      purchasedFromController.clear();
      placeController.clear();
      phoneController.clear();
      setState(() {
        selectedValue = null;
      });
    }
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
                value: selectedValue,
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
                  });
                },
                validator: (val) =>
                    val == null ? 'Please select equipment' : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: submitEquipment,
                child: const Text('Submit'),
              ),

              const SizedBox(height: 20),

              // Show list of added equipment
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: equipmentList.length,
                itemBuilder: (context, index) {
                  final eq = equipmentList[index];
                  return ListTile(
                    title: Text('${eq.serialNo} - ${eq.name}'),
                    subtitle: Text(
                      'Qty: ${eq.quantity}, From: ${eq.purchasedFrom}, Place: ${eq.place}, Phone: ${eq.phone}',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Equipment model
class Equipment {
  final String serialNo;
  final String name;
  final int quantity;
  final String purchasedFrom;
  final String place;
  final String phone;

  Equipment({
    required this.serialNo,
    required this.name,
    required this.quantity,
    required this.purchasedFrom,
    required this.place,
    required this.phone,
  });
}
