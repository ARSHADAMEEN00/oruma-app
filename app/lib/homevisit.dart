import 'package:flutter/material.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/home_visit_service.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:intl/intl.dart';

class Homevisit extends StatefulWidget {
  final HomeVisit? visit;

  const Homevisit({super.key, this.visit});

  @override
  State<Homevisit> createState() => _HomevisitState();
}

class _HomevisitState extends State<Homevisit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController addressController;
  late TextEditingController teamController;
  late TextEditingController notesController;
  DateTime? visitDate;
  bool _isLoading = false;

  // Patient selection fields
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoadingPatients = true;

  // Visit mode options
  String _selectedVisitMode = 'new';
  final List<Map<String, String>> _visitModeOptions = [
    {'value': 'new', 'label': 'New Visit'},
    {'value': 'monthly', 'label': 'Monthly Visit'},
    {'value': 'emergency', 'label': 'Emergency Visit'},
    {'value': 'dhc_visit', 'label': 'DHC Visit'},
    {'value': 'vhc_visit', 'label': 'VHC Visit'},
  ];

  bool get isEditing => widget.visit != null;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(
      text: widget.visit?.address ?? '',
    );
    teamController = TextEditingController(text: widget.visit?.team ?? '');
    notesController = TextEditingController(text: widget.visit?.notes ?? '');
    if (widget.visit?.visitDate != null) {
      visitDate = DateTime.tryParse(widget.visit!.visitDate);
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingPatients = true);
    try {
      final patients = await PatientService.getAllPatients(isDead: false);
      setState(() {
        _patients = patients;
        _isLoadingPatients = false;

        // If editing, try to find the matching patient and visit mode
        if (isEditing) {
          try {
            _selectedPatient = _patients.firstWhere(
              (p) => p.name == widget.visit!.patientName,
            );
          } catch (_) {
            // If not found (maybe name changed or deleted), we'll handle it
            _selectedPatient = null;
          }
          // Set visit mode from existing visit
          if (widget.visit!.visitMode.isNotEmpty) {
            _selectedVisitMode = widget.visit!.visitMode;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingPatients = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load patients: $e')));
      }
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    teamController.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => visitDate = picked);
    }
  }

  Future<void> _saveVisit() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a patient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a visit date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final homeVisit = HomeVisit(
        id: widget.visit?.id,
        patientName: _selectedPatient!.name,
        address: addressController.text.trim(),
        visitDate: visitDate!.toIso8601String(),
        visitMode: _selectedVisitMode,
        team: teamController.text.trim().isNotEmpty
            ? teamController.text.trim()
            : null,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (isEditing) {
        await HomeVisitService.updateHomeVisit(widget.visit!.id!, homeVisit);
      } else {
        await HomeVisitService.createHomeVisit(homeVisit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? '✅ Visit updated successfully'
                  : '✅ Visit scheduled successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
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

  Future<void> _showAddPatientDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String selectedGender = 'Male';

    final formKey = GlobalKey<FormState>();
    bool localLoading = false;

    // Helper for consistent decoration
    InputDecoration getModernDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
    }

    final result = await showDialog<Patient>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'New Patient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernTextField(
                            controller: nameCtrl,
                            label: 'Patient Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null,
                            decoration: getModernDecoration(
                              'Patient Name',
                              Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: phoneCtrl,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null,
                            decoration: getModernDecoration(
                              'Phone',
                              Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: ageCtrl,
                            label: 'Age',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null,
                            decoration: getModernDecoration(
                              'Age',
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Gender Selection
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: getModernDecoration(
                              'Gender',
                              Icons.people_outline,
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedGender = v!),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: addressCtrl,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null,
                            decoration: getModernDecoration(
                              'Address',
                              Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: localLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setDialogState(() => localLoading = true);
                              try {
                                final newPatient = Patient(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  relation: 'Self',
                                  gender: selectedGender,
                                  age: int.tryParse(ageCtrl.text.trim()) ?? 0,
                                  place: 'Home',
                                  village: 'Kodur',
                                  disease: const ['OLD AGE'],
                                  plan: '1/1',
                                );
                                final created =
                                    await PatientService.createPatient(
                                      newPatient,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context, created);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setDialogState(() => localLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: localLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Patient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _loadInitialData();
      setState(() {
        _selectedPatient = _patients.firstWhere((p) => p.name == result.name);
        // Update address to the new patient's address
        addressController.text = _selectedPatient!.address;
      });
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    InputDecoration? decoration,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: decoration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Home Visit' : 'Schedule Home Visit'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Patient Information'),
                    const SizedBox(height: 16),

                    // Patient Autocomplete Search with Add Icon Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Autocomplete<Patient>(
                                  initialValue: _selectedPatient != null
                                      ? TextEditingValue(
                                          text: _selectedPatient!.name,
                                        )
                                      : null,
                                  optionsBuilder:
                                      (
                                        TextEditingValue textEditingValue,
                                      ) async {
                                        if (textEditingValue.text.isEmpty) {
                                          // Return initial patients if nothing typed
                                          return _patients;
                                        }
                                        try {
                                          // Search from backend
                                          final searchResults =
                                              await PatientService.searchPatients(
                                                textEditingValue.text,
                                                isDead: false,
                                              );
                                          return searchResults;
                                        } catch (e) {
                                          return _patients.where((patient) {
                                            return patient.name
                                                .toLowerCase()
                                                .contains(
                                                  textEditingValue.text
                                                      .toLowerCase(),
                                                );
                                          });
                                        }
                                      },
                                  displayStringForOption: (Patient patient) =>
                                      patient.name,
                                  onSelected: (Patient patient) {
                                    setState(() {
                                      _selectedPatient = patient;
                                      addressController.text = patient.address;
                                    });
                                  },
                                  fieldViewBuilder:
                                      (
                                        BuildContext context,
                                        TextEditingController
                                        textEditingController,
                                        FocusNode focusNode,
                                        VoidCallback onFieldSubmitted,
                                      ) {
                                        return TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            labelText: 'Search Patient',
                                            hintText: 'Type to search...',
                                            prefixIcon: Icon(
                                              Icons.person_search,
                                              size: 22,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                          ),
                                          onFieldSubmitted: (String value) {
                                            onFieldSubmitted();
                                          },
                                        );
                                      },
                                  optionsViewBuilder:
                                      (
                                        BuildContext context,
                                        AutocompleteOnSelected<Patient>
                                        onSelected,
                                        Iterable<Patient> options,
                                      ) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Material(
                                              elevation: 4.0,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 200,
                                                      maxWidth: 400,
                                                    ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  itemBuilder: (BuildContext context, int index) {
                                                    final Patient patient =
                                                        options.elementAt(
                                                          index,
                                                        );
                                                    return InkWell(
                                                      onTap: () {
                                                        onSelected(patient);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color: Colors
                                                                  .grey
                                                                  .shade200,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.person,
                                                              size: 18,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          patient
                                                                              .name,
                                                                          style: const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (patient
                                                                              .registerId !=
                                                                          null)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8,
                                                                            vertical:
                                                                                2,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).primaryColor.withOpacity(
                                                                                  0.15,
                                                                                ),
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            '#${patient.registerId}',
                                                                            style: TextStyle(
                                                                              fontSize: 11,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Theme.of(
                                                                                context,
                                                                              ).primaryColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                  if (patient
                                                                      .phone
                                                                      .isNotEmpty)
                                                                    Text(
                                                                      patient
                                                                          .phone,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade600,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                              // Add Patient Icon Button
                              Container(
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _showAddPatientDialog,
                                  icon: Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                  tooltip: 'Add New Patient',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter address'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Visit Details'),
                    const SizedBox(height: 16),

                    // Visit Mode Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVisitMode,
                        decoration: InputDecoration(
                          labelText: 'Visit Mode',
                          prefixIcon: const Icon(
                            Icons.medical_services_outlined,
                            size: 22,
                          ),
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
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _visitModeOptions
                            .map(
                              (option) => DropdownMenuItem(
                                value: option['value'],
                                child: Row(
                                  children: [
                                    Icon(
                                      option['value'] == 'emergency'
                                          ? Icons.emergency_outlined
                                          : option['value'] == 'monthly'
                                          ? Icons.calendar_month_outlined
                                          : option['value'] == 'dhc_visit'
                                          ? Icons.home_work_outlined
                                          : option['value'] == 'vhc_visit'
                                          ? Icons.local_hospital_outlined
                                          : Icons.add_circle_outline,
                                      size: 18,
                                      color: option['value'] == 'emergency'
                                          ? Colors.red
                                          : option['value'] == 'monthly'
                                          ? Colors.blue
                                          : option['value'] == 'dhc_visit'
                                          ? Colors.orange
                                          : option['value'] == 'vhc_visit'
                                          ? Colors.purple
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(option['label']!),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedVisitMode = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                visitDate == null
                                    ? 'Select Visit Date'
                                    : DateFormat(
                                        'EEEE, d MMMM yyyy',
                                      ).format(visitDate!),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: visitDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: teamController,
                      label: 'Team',
                      icon: Icons.group_outlined,
                      required: false,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: notesController,
                      label: 'Notes / Special Requests',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                      required: false,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveVisit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isEditing ? 'UPDATE VISIT' : 'SCHEDULE VISIT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool required = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
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
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
