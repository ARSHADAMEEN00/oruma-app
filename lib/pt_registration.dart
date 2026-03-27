import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/config_service.dart';
import 'package:oruma_app/models/config.dart';
import 'package:intl/intl.dart';

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
  bool _isLoadingConfig = true;
  String? _configError;

  // Dropdown values
  String? _selectedVillage;
  List<String> _selectedDiseases = [];
  String? _selectedPlan;
  String? _gender;
  DateTime? _registrationDate;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController relationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController phone2Controller = TextEditingController();
  final TextEditingController locationLinkController = TextEditingController();
  final TextEditingController wardController = TextEditingController();

  // Dropdown options (loaded from API)
  List<String> villages = [];
  List<String> diseases = [];
  List<String> plans = [];
  List<WardConfig> allWards = [];
  List<String> filteredWards = [];
  String? _selectedWardTitle;

  @override
  void initState() {
    super.initState();
    // Set default registration date to today at noon
    final now = DateTime.now();
    _registrationDate = DateTime(now.year, now.month, now.day, 12, 0, 0);

    // Load configuration data
    _loadConfig();

    if (widget.patient != null) {
      nameController.text = widget.patient!.name;
      relationController.text = widget.patient!.relation;
      addressController.text = widget.patient!.address;
      ageController.text = widget.patient!.age.toString();
      placeController.text = widget.patient!.place;
      phoneController.text = widget.patient!.phone;
      phone2Controller.text = widget.patient!.phone2 ?? '';
      locationLinkController.text = widget.patient!.locationLink ?? '';
      _gender = widget.patient!.gender;
      _selectedVillage = widget.patient!.village;
      _selectedWardTitle = widget.patient!.ward;
      _selectedDiseases = List.from(widget.patient!.disease);
      _selectedPlan = widget.patient!.plan;

      // Normalize existing registration date to noon if it exists
      if (widget.patient!.registrationDate != null) {
        final regDate = widget.patient!.registrationDate!;
        _registrationDate = DateTime(
          regDate.year,
          regDate.month,
          regDate.day,
          12,
          0,
          0,
        );
      }
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ConfigService.getConfig();
      setState(() {
        villages = config.villages;
        diseases = config.diseases;
        plans = config.plans;
        allWards = sortWardConfigs(config.wards);
        _updateFilteredWards();
        _isLoadingConfig = false;
      });
    } catch (e) {
      setState(() {
        _configError = e.toString();
        _isLoadingConfig = false;
      });
    }
  }

  void _updateFilteredWards() {
    if (_selectedVillage == null) {
      filteredWards = [];
    } else {
      filteredWards =
          allWards
              .where((w) => w.village == _selectedVillage)
              .map((w) => w.number)
              .toList()
            ..sort(compareWardNumbers);
    }
    // If current selected ward is not in the filtered list, clear it
    if (_selectedWardTitle != null &&
        !filteredWards.contains(_selectedWardTitle)) {
      _selectedWardTitle = null;
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
    locationLinkController.dispose();
    wardController.dispose();
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

  Future<void> _pickRegistrationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? now,
      firstDate: DateTime(2020), // Allow backdating to 2020
      lastDate: now, // Can't select future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Normalize to noon to avoid timezone conversion issues
      // This ensures the date doesn't shift when converting to UTC
      final normalizedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        12, // Set to noon
        0,
        0,
      );
      setState(() => _registrationDate = normalizedDate);
    }
  }

  Future<void> _showAddWardDialog() async {
    final TextEditingController newWardController = TextEditingController();
    String? popupSelectedVillage = _selectedVillage;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: const Text('Add New Ward'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration(
                      "Village",
                      Icons.location_city,
                    ),
                    value: popupSelectedVillage,
                    items: villages
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      setStateBuilder(() {
                        popupSelectedVillage = v;
                      });
                    },
                    hint: const Text("Select Village"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newWardController,
                    decoration: const InputDecoration(
                      labelText: 'Ward Number',
                      hintText: 'e.g. 1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (isSaving || popupSelectedVillage == null)
                      ? null
                      : () async {
                          final newWardNumber = normalizeWardNumberValue(
                            newWardController.text,
                          );
                          if (newWardNumber.isEmpty) return;

                          setStateBuilder(() => isSaving = true);

                          try {
                            final config = await ConfigService.getConfig();
                            final exists = config.wards.any(
                              (w) =>
                                  w.number == newWardNumber &&
                                  w.village == popupSelectedVillage,
                            );

                            if (!exists) {
                              config.wards.add(
                                WardConfig(
                                  number: newWardNumber,
                                  village: popupSelectedVillage!,
                                ),
                              );
                              await ConfigService.updateConfig(config);
                            }

                            setState(() {
                              if (!allWards.any(
                                (w) =>
                                    w.number == newWardNumber &&
                                    w.village == popupSelectedVillage,
                              )) {
                                allWards = sortWardConfigs([
                                  ...allWards,
                                  WardConfig(
                                    number: newWardNumber,
                                    village: popupSelectedVillage!,
                                  ),
                                ]);
                              }
                              // If we added it for the currently selected village in the main form,
                              // update the filtered list and select it. Otherwise just refresh.
                              if (_selectedVillage == popupSelectedVillage) {
                                _updateFilteredWards();
                                _selectedWardTitle = newWardNumber;
                              }
                            });

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setStateBuilder(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add ward: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddDiseaseDialog() async {
    final TextEditingController newDiseaseController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: const Text('Add New Disease'),
              content: TextField(
                controller: newDiseaseController,
                decoration: const InputDecoration(
                  labelText: 'Disease Name',
                  hintText: 'e.g. ASTHMA',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newDisease = newDiseaseController.text
                              .trim()
                              .toUpperCase();
                          if (newDisease.isEmpty) return;

                          setStateBuilder(() => isSaving = true);

                          try {
                            // Fetch current config to update it
                            final config = await ConfigService.getConfig();
                            if (!config.diseases.contains(newDisease)) {
                              config.diseases.add(newDisease);
                              await ConfigService.updateConfig(config);
                            }

                            // Update the local state
                            setState(() {
                              if (!diseases.contains(newDisease)) {
                                diseases.add(newDisease);
                              }
                              if (!_selectedDiseases.contains(newDisease)) {
                                _selectedDiseases.add(newDisease);
                              }
                            });

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setStateBuilder(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add disease: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;

    // Show loading indicator while config is loading
    if (_isLoadingConfig) {
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
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
    }

    // Show error if config failed to load
    if (_configError != null) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load configuration',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _configError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoadingConfig = true;
                    _configError = null;
                  });
                  _loadConfig();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              InkWell(
                onTap: _pickRegistrationDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF1A237E),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registration Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _registrationDate == null
                                  ? 'Select Date'
                                  : DateFormat(
                                      'EEEE, d MMMM yyyy',
                                    ).format(_registrationDate!),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                    children: [
                      ...diseases.map((disease) {
                        final isSelected = _selectedDiseases.contains(disease);
                        return FilterChip(
                          label: Text(disease),
                          selected: isSelected,
                          selectedColor: const Color(
                            0xFF1A237E,
                          ).withValues(alpha: 0.8),
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
                      }),
                      ActionChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: Color(0xFF1A237E)),
                            SizedBox(width: 4),
                            Text(
                              'Other',
                              style: TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        onPressed: _showAddDiseaseDialog,
                      ),
                    ],
                  ),
                  if (_selectedDiseases.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Please select at least one disease",
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
                    controller: addressController,
                    maxLines: 2,
                    decoration: _buildInputDecoration(
                      "Full Address",
                      Icons.home_outlined,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
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
                    controller: phone2Controller,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(
                      "Caregiver Phone Number",
                      Icons.phone_android,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Location & Care Plan",
                icon: Icons.map_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration(
                      "Village",
                      Icons.location_city,
                    ),
                    value: _selectedVillage,
                    items: villages
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedVillage = v;
                        _updateFilteredWards();
                      });
                    },
                    validator: (val) => val == null ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration(
                            "Ward Number",
                            Icons.apartment,
                          ),
                          value: _selectedWardTitle,
                          hint: const Text("Select Ward Number"),
                          items: filteredWards
                              .map(
                                (w) =>
                                    DropdownMenuItem(value: w, child: Text(w)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedWardTitle = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          onPressed: _showAddWardDialog,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF1A237E),
                            size: 30,
                          ),
                          tooltip: 'Add New Ward',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: placeController,
                    decoration: _buildInputDecoration("Place", Icons.place),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationLinkController,
                    decoration: _buildInputDecoration(
                      "Location Link (Google Maps)",
                      Icons.map,
                    ),
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
          ward: _selectedWardTitle == null
              ? null
              : normalizeWardNumberValue(_selectedWardTitle),
          locationLink: locationLinkController.text.trim().isEmpty
              ? null
              : locationLinkController.text.trim(),
          disease: _selectedDiseases,
          plan: _selectedPlan!,
          registerId: widget.patient?.registerId,
          registrationDate: _registrationDate,
        );

        if (widget.patient != null) {
          var updated = await PatientService.updatePatient(
            widget.patient!.id!,
            patientData,
          );

          // Optimistic update: If API response lacks locationLink but we sent it, preserve it
          if (updated.locationLink == null &&
              patientData.locationLink != null) {
            updated = updated.copyWith(locationLink: patientData.locationLink);
          }

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
