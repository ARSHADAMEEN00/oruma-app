import 'package:flutter/material.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/pt_registration.dart';
import 'package:intl/intl.dart';

class PatientDetailsPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailsPage({super.key, required this.patient});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Patient _currentPatient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  Future<void> _deletePatient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text("Are you sure you want to delete ${_currentPatient.name}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await PatientService.deletePatient(_currentPatient.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient deleted successfully")),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => patientrigister(patient: _currentPatient),
                ),
              );
              if (result != null && result is Patient) {
                setState(() {
                  _currentPatient = result;
                });
              } else if (result == true) {
                // If it just returned true, refetch
                try {
                   final updated = await PatientService.getPatientById(_currentPatient.id!);
                   setState(() {
                     _currentPatient = updated;
                   });
                } catch(e) {
                  // ignore
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _isLoading ? null : _deletePatient,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInfoSection("Personal Information", [
                    _buildInfoTile(Icons.person, "Full Name", _currentPatient.name),
                    _buildInfoTile(Icons.info_outline, "Relation", _currentPatient.relation),
                    _buildInfoTile(Icons.wc, "Gender", _currentPatient.gender),
                    _buildInfoTile(Icons.cake, "Age", "${_currentPatient.age} years"),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection("Location", [
                    _buildInfoTile(Icons.location_on, "Address", _currentPatient.address),
                    _buildInfoTile(Icons.place, "Place", _currentPatient.place),
                    _buildInfoTile(Icons.home, "Village", _currentPatient.village),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection("Medical Details", [
                    _buildInfoTile(Icons.medical_services, "Disease", _currentPatient.disease),
                    _buildInfoTile(Icons.assignment, "Plan", _currentPatient.plan),
                  ]),
                  const SizedBox(height: 24),
                  if (_currentPatient.createdAt != null)
                     Text(
                       "Registered on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentPatient.createdAt!)}",
                       style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                     ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              _currentPatient.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentPatient.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentPatient.disease,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }
}
