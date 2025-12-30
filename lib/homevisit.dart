import 'package:flutter/material.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/services/home_visit_service.dart';

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
  bool _isLoading = false;

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

  Future<void> _scheduleVisit() async {
    final valid = _formKey.currentState!.validate();
    final hasDate = visitDate != null;
    setState(() {}); // refresh UI if needed
    
    if (!hasDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a visit date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (valid && hasDate) {
      setState(() => _isLoading = true);
      
      try {
        final homeVisit = HomeVisit(
          patientName: patientController.text,
          address: addressController.text,
          visitDate: visitDate!.toIso8601String(),
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        );

        await HomeVisitService.createHomeVisit(homeVisit);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Visit scheduled for ${visitDate!.day}/${visitDate!.month}/${visitDate!.year}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
                onPressed: _isLoading ? null : _scheduleVisit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}