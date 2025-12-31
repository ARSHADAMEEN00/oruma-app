import 'package:flutter/material.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';

class patientrigister extends StatefulWidget {
  final Patient? patient;
  const patientrigister({super.key, this.patient});

  @override
  State<patientrigister> createState() => _patientrigisterState();
}

class _patientrigisterState extends State<patientrigister> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Dropdown values
  String? _selectedVillage;
  String? _selectedDisease;
  String? _selectedPlan;
  String? _gender;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController relationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Dropdown options
  final List<String> villages = ["Kodur", "Ponmala", "Kuruva", "Malappuram"];
  final List<String> diseases = ["CA", "Old Age", "CVA", "CKD", "Dybetic"];
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
      _gender = widget.patient!.gender;
      _selectedVillage = widget.patient!.village;
      _selectedDisease = widget.patient!.disease;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Patient" : "Patient Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Patient Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Patient Name",
                ),
                validator: (val) => val == null || val.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: "Relation of patient with Name",
                ),
                validator: (val) => val == null || val.isEmpty ? "Enter relation" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? "Enter phone" : null,
              ),
              const SizedBox(height: 20),
              const Text(
                "Select Gender:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Radio<String>(
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text("Male"),
                  Radio<String>(
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text("Female"),
                  Radio<String>(
                    value: 'Other',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text("Other"),
                ],
              ),
              if (_gender == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "Select a gender",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              // Full Address
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Full Address",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 15),

              // Age
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter age";
                  final parsed = int.tryParse(val);
                  if (parsed == null || parsed <= 0) return "Enter valid age";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Place
              TextFormField(
                controller: placeController,
                decoration: const InputDecoration(
                  labelText: "Place",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? "Enter place" : null,
              ),
              const SizedBox(height: 20),

              // Village (Dropdown)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Village",
                  border: OutlineInputBorder(),
                ),
                value: _selectedVillage,
                items: villages.map((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedVillage = value);
                },
                validator: (val) => val == null ? "Select village" : null,
              ),
              const SizedBox(height: 20),

              // Disease (Dropdown)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Disease",
                  border: OutlineInputBorder(),
                ),
                value: _selectedDisease,
                items: diseases.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDisease = value);
                },
                validator: (val) => val == null ? "Select disease" : null,
              ),
              const SizedBox(height: 20),

              // Plan (Dropdown)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Plan",
                  border: OutlineInputBorder(),
                ),
                value: _selectedPlan,
                items: plans.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPlan = value);
                },
                validator: (val) => val == null ? "Select plan" : null,
              ),
              const SizedBox(height: 25),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final isValid = _formKey.currentState!.validate();
                        final genderSelected = _gender != null;
                        setState(() {}); // refresh gender helper text if needed
                        if (isValid && genderSelected) {
                          setState(() => _isLoading = true);
                          
                          try {
                            final patientData = Patient(
                              id: widget.patient?.id,
                              name: nameController.text,
                              relation: relationController.text,
                              gender: _gender!,
                              address: addressController.text,
                              phone: phoneController.text,
                              age: int.parse(ageController.text),
                              place: placeController.text,
                              village: _selectedVillage!,
                              disease: _selectedDisease!,
                              plan: _selectedPlan!,
                              registerId: widget.patient?.registerId,
                            );

                            if (isEditing) {
                              final updated = await PatientService.updatePatient(widget.patient!.id!, patientData);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ Patient Updated Successfully"),
                                    backgroundColor: Colors.green,
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
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? "Update" : "Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

