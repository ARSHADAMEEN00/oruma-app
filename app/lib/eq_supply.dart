import 'package:flutter/material.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/models/equipment.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:oruma_app/services/equipment_service.dart';
import 'package:oruma_app/services/equipment_supply_service.dart';

class EqSupply extends StatefulWidget {
  const EqSupply({super.key});

  @override
  State<EqSupply> createState() => _EqSupplyState();
}

class _EqSupplyState extends State<EqSupply> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  Equipment? _selectedEquipment;
  Patient? _selectedPatient;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _careOfController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();

  // Data
  List<Equipment> _availableEquipment = [];
  List<Patient> _patients = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    await Future.wait([_fetchAvailableEquipment(), _fetchPatients()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchPatients() async {
    try {
      final list = await PatientService.getAllPatients(isDead: false);
      setState(() {
        _patients = list;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _careOfController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableEquipment() async {
    try {
      final list = await EquipmentService.getAvailableEquipment();
      setState(() {
        _availableEquipment = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading equipment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => {});
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedEquipment == null || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _selectedEquipment == null
                    ? 'Please select a equipment'
                    : 'Please select a patient',
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final supply = EquipmentSupply(
        equipmentId: _selectedEquipment!.id!,
        equipmentUniqueId: _selectedEquipment!.uniqueId,
        equipmentName: _selectedEquipment!.name,
        patientName: _selectedPatient!.name,
        patientPhone: _selectedPatient!.phone,
        patientAddress: _selectedPatient!.address,
        careOf: _careOfController.text.trim(),
        receiverName: _receiverNameController.text.trim(),
        receiverPhone: _receiverPhoneController.text.trim(),
        supplyDate: DateTime.now(),
        notes: _notesController.text.trim(),
      );

      await EquipmentSupplyService.createSupply(supply);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Equipment distributed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAddPatientDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final phone2Ctrl = TextEditingController();
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
                            controller: phone2Ctrl,
                            label: 'Phone 2',
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            decoration: getModernDecoration(
                              'Phone 2',
                              Icons.phone_android_outlined,
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
                                  phone2: phone2Ctrl.text.trim().isEmpty
                                      ? null
                                      : phone2Ctrl.text.trim(),
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
      await _fetchPatients();
      setState(() {
        _selectedPatient = _patients.firstWhere((p) => p.name == result.name);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Distribute Equipment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'Distribution Details',
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.blue,
                            children: [
                              // Equipment Autocomplete Search
                              Autocomplete<Equipment>(
                                initialValue: _selectedEquipment != null
                                    ? TextEditingValue(
                                        text:
                                            '${_selectedEquipment!.uniqueId} - ${_selectedEquipment!.name}',
                                      )
                                    : null,
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) async {
                                      if (textEditingValue.text.isEmpty) {
                                        return _availableEquipment;
                                      }
                                      try {
                                        final searchResults =
                                            await EquipmentService.searchEquipment(
                                              textEditingValue.text,
                                              status: 'available',
                                            );
                                        return searchResults;
                                      } catch (e) {
                                        return _availableEquipment.where((
                                          equipment,
                                        ) {
                                          final searchText =
                                              '${equipment.uniqueId} ${equipment.name}'
                                                  .toLowerCase();
                                          return searchText.contains(
                                            textEditingValue.text.toLowerCase(),
                                          );
                                        });
                                      }
                                    },
                                displayStringForOption: (Equipment equipment) =>
                                    '${equipment.uniqueId} - ${equipment.name}',
                                onSelected: (Equipment equipment) {
                                  setState(() {
                                    _selectedEquipment = equipment;
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
                                        decoration:
                                            _inputDecoration(
                                              'Search Equipment',
                                              Icons.inventory_2_outlined,
                                            ).copyWith(
                                              hintText: 'Type to search...',
                                            ),
                                        onFieldSubmitted: (String value) {
                                          onFieldSubmitted();
                                        },
                                      );
                                    },
                                optionsViewBuilder:
                                    (
                                      BuildContext context,
                                      AutocompleteOnSelected<Equipment>
                                      onSelected,
                                      Iterable<Equipment> options,
                                    ) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Material(
                                            elevation: 4.0,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxHeight: 200,
                                                maxWidth: 400,
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final Equipment equipment =
                                                      options.elementAt(index);
                                                  return InkWell(
                                                    onTap: () {
                                                      onSelected(equipment);
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
                                                            Icons.inventory_2,
                                                            size: 18,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .withOpacity(
                                                                          0.15,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    equipment
                                                                        .uniqueId,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    equipment
                                                                        .name,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
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
                              if (_selectedEquipment != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.orange.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_selectedEquipment!.name} (${_selectedEquipment!.place})',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Patient Autocomplete Search
                              Row(
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
                                              return _patients;
                                            }
                                            try {
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
                                      displayStringForOption:
                                          (Patient patient) => patient.name,
                                      onSelected: (Patient patient) {
                                        setState(() {
                                          _selectedPatient = patient;
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
                                              decoration:
                                                  _inputDecoration(
                                                    'Search Patient',
                                                    Icons.person_outline,
                                                  ).copyWith(
                                                    hintText:
                                                        'Type to search...',
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
                                                      itemBuilder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            int index,
                                                          ) {
                                                            final Patient
                                                            patient = options
                                                                .elementAt(
                                                                  index,
                                                                );
                                                            return InkWell(
                                                              onTap: () {
                                                                onSelected(
                                                                  patient,
                                                                );
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          12,
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
                                                                      Icons
                                                                          .person,
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
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Text(
                                                                                  patient.name,
                                                                                  style: const TextStyle(
                                                                                    fontSize: 15,
                                                                                    fontWeight: FontWeight.w500,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              if (patient.registerId !=
                                                                                  null)
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(
                                                                                    horizontal: 8,
                                                                                    vertical: 2,
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
                                                                              patient.phone,
                                                                              style: TextStyle(
                                                                                fontSize: 12,
                                                                                color: Colors.grey.shade600,
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
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: IconButton.filled(
                                      onPressed: _showAddPatientDialog,
                                      icon: const Icon(
                                        Icons.person_add_rounded,
                                        size: 20,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: Colors.blue.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedPatient != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_selectedPatient!.name}, ${_selectedPatient!.address}',
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Care Of
                              _buildTextField(
                                controller: _careOfController,
                                label: 'C/O (Care Of)',
                                hint: 'Guardian Name',
                                icon: Icons.supervised_user_circle_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionCard(
                            title: 'Handover & Notes',
                            icon: Icons.handshake_outlined,
                            iconColor: Colors.teal,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _receiverNameController,
                                      label: 'Receiver Name',
                                      hint: 'Name',
                                      icon: Icons.person_pin_circle_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _receiverPhoneController,
                                      label: 'Receiver Phone',
                                      hint: 'Phone',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _notesController,
                                label: 'Notes',
                                hint: 'Any additional instructions...',
                                icon: Icons.notes_rounded,
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: Colors.grey.shade700,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed:
                                _submitting || _availableEquipment.isEmpty
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor: Colors.orange.shade200,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Confirm Distribution',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
