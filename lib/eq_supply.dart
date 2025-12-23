import 'package:flutter/material.dart';

class EqSupply extends StatefulWidget {
  const EqSupply({super.key});

  @override
  State<EqSupply> createState() => _EqSupplyState();
}

class _EqSupplyState extends State<EqSupply> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController patientController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    patientController.dispose();
    equipmentController.dispose();
    quantityController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Supply')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: patientController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter patient' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: equipmentController,
                decoration: const InputDecoration(
                  labelText: 'Equipment',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter equipment' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter quantity';
                  final qty = int.tryParse(val);
                  if (qty == null || qty <= 0) return 'Enter valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter phone';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                    return 'Enter 10 digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address / Delivery Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Request logged for ${quantityController.text} ${equipmentController.text}(s)',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
