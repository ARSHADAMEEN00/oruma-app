import 'package:flutter/material.dart';

class Homevisit extends StatefulWidget {
  const Homevisit({super.key});

  @override
  State<Homevisit> createState() => _HomevisitState();
}

class _HomevisitState extends State<Homevisit> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController patientController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  DateTime? visitDate;

  @override
  void dispose() {
    patientController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: visitDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => visitDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Visit')),
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
                validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        visitDate == null
                            ? 'Pick visit date'
                            : '${visitDate!.day}/${visitDate!.month}/${visitDate!.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes / Requests',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final valid = _formKey.currentState!.validate();
                  final hasDate = visitDate != null;
                  setState(() {}); // refresh UI if needed
                  if (valid && hasDate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Visit scheduled for ${visitDate!.day}/${visitDate!.month}/${visitDate!.year}',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } else if (!hasDate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a visit date')),
                    );
                  }
                },
                child: const Text('Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}