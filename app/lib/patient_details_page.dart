import 'package:flutter/material.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/pt_registration.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/services/auth_service.dart';

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
        content: Text(
          "Are you sure you want to delete ${_currentPatient.name}? This action cannot be undone.",
        ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsDeceased() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: "Select Date of Death",
    );

    if (selectedDate == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark as Deceased"),
        content: Text(
          "Are you sure you want to mark ${_currentPatient.name} as deceased on ${DateFormat('MMM dd, yyyy').format(selectedDate)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final updatedPatient = _currentPatient.copyWith(
          isDead: true,
          dateOfDeath: selectedDate,
        );

        final result = await PatientService.updatePatient(
          _currentPatient.id!,
          updatedPatient,
        );

        if (mounted) {
          setState(() {
            _currentPatient = result;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient marked as deceased")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
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
                  builder: (context) =>
                      patientrigister(patient: _currentPatient),
                ),
              );
              if (result != null && result is Patient) {
                setState(() {
                  _currentPatient = result;
                });
              } else if (result == true) {
                // If it just returned true, refetch
                try {
                  final updated = await PatientService.getPatientById(
                    _currentPatient.id!,
                  );
                  setState(() {
                    _currentPatient = updated;
                  });
                } catch (e) {
                  // ignore
                }
              }
            },
          ),
          if (context.watch<AuthService>().isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _deletePatient,
            ),
          if (!_currentPatient.isDead)
            IconButton(
              icon: const Icon(Icons.person_off_outlined),
              tooltip: "Mark as Deceased",
              onPressed: _isLoading ? null : _markAsDeceased,
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
                    if (_currentPatient.registerId != null)
                      _buildInfoTile(
                        Icons.app_registration,
                        "Register ID",
                        _currentPatient.registerId!,
                      ),
                    _buildInfoTile(
                      Icons.person,
                      "Full Name",
                      _currentPatient.name,
                    ),
                    _buildInfoTile(Icons.phone, "Phone", _currentPatient.phone),
                    _buildInfoTile(
                      Icons.info_outline,
                      "Relation",
                      _currentPatient.relation,
                    ),
                    _buildInfoTile(Icons.wc, "Gender", _currentPatient.gender),
                    _buildInfoTile(
                      Icons.cake,
                      "Age",
                      "${_currentPatient.age} years",
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection("Location", [
                    _buildInfoTile(
                      Icons.location_on,
                      "Address",
                      _currentPatient.address,
                    ),
                    _buildInfoTile(Icons.place, "Place", _currentPatient.place),
                    _buildInfoTile(
                      Icons.home,
                      "Village",
                      _currentPatient.village,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection("Medical Details", [
                    _buildInfoTile(
                      Icons.medical_services,
                      "Disease",
                      _currentPatient.disease,
                    ),
                    _buildInfoTile(
                      Icons.assignment,
                      "Plan",
                      _currentPatient.plan,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  if (_currentPatient.createdAt != null)
                    Text(
                      "Registered on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentPatient.createdAt!)}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  if (_currentPatient.createdBy != null)
                    Text(
                      "Created by: ${_currentPatient.createdBy}",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
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
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _currentPatient.isDead
                    ? Colors.grey.shade300
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: _currentPatient.isDead
                    ? const Icon(Icons.person_off, size: 40, color: Colors.grey)
                    : Text(
                        _currentPatient.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
              if (_currentPatient.isDead)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentPatient.isDead)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "DECEASED",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            _currentPatient.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_currentPatient.isDead && _currentPatient.dateOfDeath != null)
            Text(
              "Died on: ${DateFormat('MMM dd, yyyy').format(_currentPatient.dateOfDeath!)}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          const SizedBox(height: 4),
          if (_currentPatient.registerId != null)
            Text(
              "ID: ${_currentPatient.registerId}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
