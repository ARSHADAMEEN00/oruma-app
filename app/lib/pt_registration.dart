import 'package:flutter/material.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';

// ignore: camel_case_types
class patientrigister extends StatefulWidget {
  final Patient? patient;
  const patientrigister({super.key, this.patient});

  @override
  State<patientrigister> createState() => _patientrigisterState();
}

// ignore: camel_case_types
class _patientrigisterState extends State<patientrigister> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Dropdown values
  String? _selectedVillage;
  List<String> _selectedDiseases = [];
  String? _selectedPlan;
  String? _gender;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController relationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController phone2Controller = TextEditingController();

  // Dropdown options
  final List<String> villages = ["Kodur", "Ponmala", "Kuruva", "Malappuram"];
  final List<String> diseases = [
    "CAD",
    "HTN DM",
    "CKD",
    "CLD",
    "OLD AGE",
    "PARAPLEGIA",
    "DIABETIC FOOT",
    "CVA",
    "CA",
    "COPD",
    "IVDP",
    "PRESSURE SORE",
    "MR",
    "MND",
    "TB",
  ];
  final List<String> plans = ["1/4", "1/8", "1/2", "1/1"];

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      nameController.text = widget.patient!.name;
      relationController.text = widget.patient!.relation;
      addressController.text = widget.patient!.address;
      ageController.text = widget.patient!.age.toString();
      placeController.text = widget.patient!.place;
      phoneController.text = widget.patient!.phone;
      phone2Controller.text = widget.patient!.phone2 ?? '';
      _gender = widget.patient!.gender;
      _selectedVillage = widget.patient!.village;
      _selectedDiseases = widget.patient!.disease;
      _selectedPlan = widget.patient!.plan;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    relationController.dispose();
    addressController.dispose();
    ageController.dispose();
    placeController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: const Color(0xFF1A237E)),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.grey.shade50,
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
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Patient" : "New Patient Registration",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: "Basic Information",
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: _buildInputDecoration(
                      "Patient Name",
                      Icons.person,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      "Age",
                      Icons.calendar_today,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Required";
                      if (int.tryParse(val) == null) return "Invalid";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Diseases",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: diseases.map((disease) {
                      final isSelected = _selectedDiseases.contains(disease);
                      return FilterChip(
                        label: Text(disease),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1A237E).withOpacity(0.8),
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDiseases.add(disease);
                            } else {
                              _selectedDiseases.remove(disease);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedDiseases.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Please select at least one disease",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    "Gender",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ["Male", "Female", "Other"].map((g) {
                      final isSelected = _gender == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1A237E),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _gender = selected ? g : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  if (_gender == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Please select a gender",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Contact Details",
                icon: Icons.contact_phone_outlined,
                children: [
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(
                      "Phone Number",
                      Icons.phone,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phone2Controller,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(
                      "Phone Number 2",
                      Icons.phone_android,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: relationController,
                    decoration: _buildInputDecoration(
                      "Caregiver/Relation",
                      Icons.people_outline,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: _buildInputDecoration(
                      "Full Address",
                      Icons.home_outlined,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Location & Care Plan",
                icon: Icons.map_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration(
                            "Village",
                            Icons.location_city,
                          ),
                          initialValue: _selectedVillage,
                          items: villages
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedVillage = v),
                          validator: (val) => val == null ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: placeController,
                          decoration: _buildInputDecoration(
                            "Place",
                            Icons.place,
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration(
                      "Care Plan",
                      Icons.assignment_outlined,
                    ),
                    initialValue: _selectedPlan,
                    items: plans
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPlan = v),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEditing ? "UPDATE PATIENT" : "REGISTER PATIENT",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
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

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState!.validate();
    final genderSelected = _gender != null;

    // Trigger rebuild to show gender error if needed
    if (!genderSelected) setState(() {});

    if (isValid && genderSelected && _selectedDiseases.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        final patientData = Patient(
          id: widget.patient?.id,
          name: nameController.text,
          relation: relationController.text,
          gender: _gender!,
          address: addressController.text,
          phone: phoneController.text,
          phone2: phone2Controller.text.trim().isEmpty
              ? null
              : phone2Controller.text.trim(),
          age: int.parse(ageController.text),
          place: placeController.text,
          village: _selectedVillage!,
          disease: _selectedDiseases,
          plan: _selectedPlan!,
          registerId: widget.patient?.registerId,
        );

        if (widget.patient != null) {
          final updated = await PatientService.updatePatient(
            widget.patient!.id!,
            patientData,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Patient Updated Successfully"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, updated);
          }
        } else {
          await PatientService.createPatient(patientData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Patient Registered Successfully"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Failed: ${e.toString()}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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
}
