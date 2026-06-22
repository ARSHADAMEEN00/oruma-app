import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/medicine.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/medicine_service.dart';
import 'package:provider/provider.dart';

const _medicineGreen = Color(0xFF11A683);
const _medicineDarkGreen = Color(0xFF087B66);
const _medicineSurface = Color(0xFFEAF8F4);

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Medicine> _medicines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadMedicines(showLoader: false),
    );
    setState(() {});
  }

  Future<void> _loadMedicines({bool showLoader = true}) async {
    final search = _searchController.text.trim();
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final medicines = await MedicineService.getMedicines(
        search: search.isEmpty ? null : search,
      );
      if (!mounted || search != _searchController.text.trim()) return;
      setState(() {
        _medicines = medicines;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || search != _searchController.text.trim()) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _openForm([Medicine? medicine]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineFormPage(medicine: medicine),
      ),
    );
    if (result == true) {
      await _loadMedicines();
    }
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    if (medicine.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text(
          'Delete ${medicine.name} (${medicine.code}) from inventory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await MedicineService.deleteMedicine(medicine.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicine deleted')));
      await _loadMedicines();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  void _showDetails(Medicine medicine) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.94,
        minChildSize: 0.5,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _medicineIcon(medicine, size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          medicine.code,
                          style: const TextStyle(
                            color: _medicineDarkGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stockPill(medicine),
                ],
              ),
              const SizedBox(height: 22),
              _detailCard([
                _detailRow(
                  Icons.science_outlined,
                  'Dosage',
                  _strengthText(medicine),
                ),
                _detailRow(
                  Icons.inventory_2_outlined,
                  'Stock',
                  _stockText(medicine),
                ),
                _detailRow(
                  Icons.category_outlined,
                  'Category',
                  _titleCase(medicine.category),
                ),
                _detailRow(
                  Icons.medication_outlined,
                  'Formulation',
                  _displayValue(medicine.formulation),
                ),
                _detailRow(
                  Icons.qr_code_2_outlined,
                  'Barcode',
                  _displayValue(medicine.barcode),
                ),
                _detailRow(
                  Icons.local_offer_outlined,
                  'Brand names',
                  medicine.brandNames.isEmpty
                      ? 'Not recorded'
                      : medicine.brandNames.join(', '),
                ),
                _detailRow(
                  Icons.event_outlined,
                  'Expiry date',
                  medicine.expiryDate == null
                      ? 'Not recorded'
                      : DateFormat(
                          'dd MMM yyyy',
                        ).format(medicine.expiryDate!.toLocal()),
                ),
                _detailRow(
                  Icons.confirmation_number_outlined,
                  'Batch number',
                  _displayValue(medicine.batchNumber),
                ),
                if (medicine.description?.trim().isNotEmpty == true)
                  _detailRow(
                    Icons.notes_outlined,
                    'Description',
                    medicine.description!,
                  ),
                _detailRow(
                  Icons.person_outline,
                  'Created by',
                  medicine.createdBy?.name ?? 'Not recorded',
                ),
              ]),
              if (medicine.photos.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Photo references',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...medicine.photos.map(
                  (photo) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _medicineSurface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: _medicineDarkGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            photo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (context.read<AuthService>().canEdit) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openForm(medicine);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _medicineGreen,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit medicine'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF8),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: _medicineDarkGreen,
        surfaceTintColor: _medicineDarkGreen,
        title: const Text(
          'Medicine Inventory',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadMedicines,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: auth.canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: _medicineGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: _medicineDarkGreen,
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 22),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search code, barcode, name or brand',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(auth)),
        ],
      ),
    );
  }

  Widget _buildContent(AuthService auth) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _medicineGreen),
      );
    }
    if (_error != null) {
      return _messageState(
        Icons.cloud_off_outlined,
        'Could not load medicines',
        _error!,
        action: OutlinedButton.icon(
          onPressed: _loadMedicines,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }
    if (_medicines.isEmpty) {
      return _messageState(
        Icons.medication_outlined,
        _searchController.text.isEmpty
            ? 'No medicines added'
            : 'No medicines found',
        _searchController.text.isEmpty
            ? 'Create the first medicine inventory record.'
            : 'Try another code, name, brand or barcode.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedicines,
      color: _medicineGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        itemCount: _medicines.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final medicine = _medicines[index];
          return InkWell(
            onTap: () => _showDetails(medicine),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _medicineDarkGreen.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _medicineIcon(medicine),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _stockPill(medicine),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            medicine.code,
                            if (medicine.formulation?.isNotEmpty == true)
                              _titleCase(medicine.formulation!),
                          ].join(' • '),
                          style: const TextStyle(
                            color: _medicineDarkGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 12,
                          runSpacing: 5,
                          children: [
                            _inlineDetail(
                              Icons.science_outlined,
                              _strengthText(medicine),
                            ),
                            _inlineDetail(
                              Icons.inventory_2_outlined,
                              _stockText(medicine),
                            ),
                            if (medicine.expiryDate != null)
                              _inlineDetail(
                                Icons.event_outlined,
                                DateFormat(
                                  'MMM yyyy',
                                ).format(medicine.expiryDate!.toLocal()),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (auth.canEdit || auth.canDelete)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(medicine);
                        if (value == 'delete') _deleteMedicine(medicine);
                      },
                      itemBuilder: (context) => [
                        if (auth.canEdit)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (auth.canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _medicineIcon(Medicine medicine, {double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: medicine.isActive ? _medicineSurface : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.medication_liquid_outlined,
        color: medicine.isActive ? _medicineGreen : Colors.grey,
        size: size * 0.5,
      ),
    );
  }

  Widget _stockPill(Medicine medicine) {
    final lowStock = medicine.qty <= 10;
    final expired =
        medicine.expiryDate != null &&
        medicine.expiryDate!.isBefore(DateTime.now());
    final color = expired
        ? Colors.red
        : lowStock
        ? Colors.orange
        : _medicineGreen;
    final label = expired
        ? 'Expired'
        : lowStock
        ? 'Low stock'
        : 'In stock';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _inlineDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  Widget _messageState(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 52, color: _medicineGreen),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          Center(child: action),
        ],
      ],
    );
  }

  Widget _detailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children.expand((child) sync* {
          yield child;
          if (child != children.last) yield const SizedBox(height: 14);
        }).toList(),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _medicineGreen, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _strengthText(Medicine medicine) {
    if (medicine.strength == null) return 'Strength not set';
    return '${_number(medicine.strength!)} ${medicine.strengthUnit ?? ''}'
        .trim();
  }

  String _stockText(Medicine medicine) {
    return '${_number(medicine.qty)} ${medicine.qtyUnit ?? 'units'}'.trim();
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _displayValue(String? value) {
    return value?.trim().isNotEmpty == true ? value!.trim() : 'Not recorded';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class MedicineFormPage extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormPage({super.key, this.medicine});

  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  static const categories = [
    'opioid',
    'nsaid',
    'antiemetic',
    'anxiolytic',
    'corticosteroid',
    'laxative',
    'other',
  ];
  static const formulations = [
    'tablet',
    'capsule',
    'syrup',
    'injection',
    'patch',
    'suppository',
    'drops',
  ];
  static const strengthUnits = ['mg', 'mcg', 'g', 'IU', 'mEq', '%'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _strengthController;
  late final TextEditingController _qtyController;
  late final TextEditingController _qtyUnitController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _brandController;
  late final TextEditingController _batchController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _photosController;

  String _category = 'other';
  String? _formulation;
  String? _strengthUnit = 'mg';
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _showMore = false;
  bool _saving = false;

  bool get _editing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    _codeController = TextEditingController(text: medicine?.code);
    _nameController = TextEditingController(text: medicine?.name);
    _strengthController = TextEditingController(
      text: medicine?.strength == null ? '' : _number(medicine!.strength!),
    );
    _qtyController = TextEditingController(
      text: medicine == null ? '' : _number(medicine.qty),
    );
    _qtyUnitController = TextEditingController(text: medicine?.qtyUnit);
    _barcodeController = TextEditingController(text: medicine?.barcode);
    _brandController = TextEditingController(
      text: medicine?.brandNames.join(', '),
    );
    _batchController = TextEditingController(text: medicine?.batchNumber);
    _descriptionController = TextEditingController(text: medicine?.description);
    _photosController = TextEditingController(
      text: medicine?.photos.join('\n'),
    );
    _category = medicine?.category ?? 'other';
    _formulation = medicine?.formulation;
    _strengthUnit = medicine?.strengthUnit ?? 'mg';
    _expiryDate = medicine?.expiryDate;
    _isActive = medicine?.isActive ?? true;
    _showMore = _editing;
  }

  @override
  void dispose() {
    for (final controller in [
      _codeController,
      _nameController,
      _strengthController,
      _qtyController,
      _qtyUnitController,
      _barcodeController,
      _brandController,
      _batchController,
      _descriptionController,
      _photosController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final medicine = Medicine(
      id: widget.medicine?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      strength: double.tryParse(_strengthController.text.trim()),
      strengthUnit: _strengthController.text.trim().isEmpty
          ? null
          : _strengthUnit,
      qty: double.tryParse(_qtyController.text.trim()) ?? 0,
      qtyUnit: _emptyToNull(_qtyUnitController.text),
      barcode: _emptyToNull(_barcodeController.text),
      brandNames: _splitValues(_brandController.text, RegExp(r'[,;\n]')),
      category: _category,
      formulation: _formulation,
      expiryDate: _expiryDate,
      batchNumber: _emptyToNull(_batchController.text),
      description: _emptyToNull(_descriptionController.text),
      photos: _splitValues(_photosController.text, RegExp(r'\n')),
      isActive: _isActive,
    );

    try {
      if (_editing) {
        await MedicineService.updateMedicine(widget.medicine!.id!, medicine);
      } else {
        await MedicineService.createMedicine(medicine);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Medicine updated' : 'Medicine created'),
          backgroundColor: _medicineDarkGreen,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _expiryDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF8),
      appBar: AppBar(
        backgroundColor: _medicineDarkGreen,
        foregroundColor: Colors.white,
        title: Text(
          _editing ? 'Edit Medicine' : 'New Medicine',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            _formIntro(),
            const SizedBox(height: 16),
            _formCard(
              title: 'Essential details',
              subtitle: 'Only the information needed to create a medicine.',
              icon: Icons.medication_outlined,
              children: [
                _textField(
                  _codeController,
                  'Medicine code',
                  hint: 'MED-0042',
                  icon: Icons.tag_outlined,
                  required: true,
                  textCapitalization: TextCapitalization.characters,
                ),
                _textField(
                  _nameController,
                  'Generic / scientific name',
                  hint: 'Morphine',
                  icon: Icons.medication_liquid_outlined,
                  required: true,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _textField(
                        _strengthController,
                        'Dosage strength',
                        hint: '10',
                        icon: Icons.science_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _dropdown(
                        label: 'Unit',
                        value: _strengthUnit,
                        values: strengthUnits,
                        onChanged: (value) =>
                            setState(() => _strengthUnit = value),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _textField(
                        _qtyController,
                        'Quantity',
                        hint: '100',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _qtyUnitController,
                        'Stock unit',
                        hint: 'tablets',
                        icon: Icons.straighten_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _medicineSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_outlined, color: _medicineDarkGreen),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _medicineDarkGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Brand, category, batch, expiry and photos',
                            style: TextStyle(
                              color: Color(0xFF5F786F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showMore ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _medicineDarkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _formCard(
                  title: 'Additional details',
                  subtitle: 'Optional information for safer stock management.',
                  icon: Icons.fact_check_outlined,
                  children: [
                    _textField(
                      _barcodeController,
                      'Barcode',
                      hint: 'Scan or enter barcode number',
                      icon: Icons.qr_code_2_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    _textField(
                      _brandController,
                      'Brand names',
                      hint: 'Separate multiple brands with commas',
                      icon: Icons.local_offer_outlined,
                    ),
                    _dropdown(
                      label: 'Category',
                      value: _category,
                      values: categories,
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'other'),
                    ),
                    _dropdown(
                      label: 'Formulation',
                      value: _formulation,
                      values: formulations,
                      allowEmpty: true,
                      onChanged: (value) =>
                          setState(() => _formulation = value),
                    ),
                    InkWell(
                      onTap: _pickExpiryDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          'Expiry date',
                          Icons.event_outlined,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _expiryDate == null
                                    ? 'Select expiry date'
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_expiryDate!),
                              ),
                            ),
                            if (_expiryDate != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _expiryDate = null),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _textField(
                      _batchController,
                      'Batch / lot number',
                      icon: Icons.confirmation_number_outlined,
                    ),
                    _textField(
                      _descriptionController,
                      'Clinical description',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    _textField(
                      _photosController,
                      'Photo references',
                      hint: 'One image URL or reference per line',
                      icon: Icons.photo_library_outlined,
                      maxLines: 3,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      activeThumbColor: _medicineGreen,
                      title: const Text(
                        'Active medicine',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Inactive medicines remain in history but are clearly marked.',
                      ),
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
              crossFadeState: _showMore
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          color: Colors.white,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _medicineGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_editing ? 'Save changes' : 'Create medicine'),
          ),
        ),
      ),
    );
  }

  Widget _formIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_medicineDarkGreen, _medicineGreen],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.medication_liquid_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine inventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start with the essentials. Add clinical and batch details only when needed.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _medicineDarkGreen.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _medicineGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children.expand(
            (child) => [
              child,
              if (child != children.last) const SizedBox(height: 13),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: required
          ? (value) =>
                value?.trim().isEmpty == true ? '$label is required' : null
          : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    bool allowEmpty = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(
        label,
        Icons.arrow_drop_down_circle_outlined,
      ),
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Not selected'),
          ),
        ...values.map(
          (item) =>
              DropdownMenuItem(value: item, child: Text(_titleCase(item))),
        ),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _medicineGreen, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FBFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _medicineGreen, width: 1.5),
      ),
    );
  }

  List<String> _splitValues(String value, RegExp separator) {
    return value
        .split(separator)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _emptyToNull(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _titleCase(String value) {
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}
