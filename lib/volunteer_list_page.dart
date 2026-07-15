import 'package:flutter/material.dart';
import 'package:oruma_app/models/config.dart';
import 'package:oruma_app/models/volunteer.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/config_service.dart';
import 'package:oruma_app/services/volunteer_service.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/reveal_action_fab.dart';
import 'package:provider/provider.dart';

const _volunteerPrimary = Color(0xFF2F6F73);
const _volunteerSurface = Color(0xFFE3F4F3);
const _volunteerIconSurface = Color(0xFFACDDDA);

class VolunteerListPage extends StatefulWidget {
  const VolunteerListPage({super.key});

  @override
  State<VolunteerListPage> createState() => _VolunteerListPageState();
}

class _VolunteerListPageState extends State<VolunteerListPage> {
  final _searchController = TextEditingController();
  List<Volunteer> _volunteers = [];
  List<String> _villages = [];
  List<WardConfig> _allWards = [];
  List<String> _filteredWards = ['All'];
  String _selectedVillage = 'All';
  String _selectedWard = 'All';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        VolunteerService.getVolunteers(),
        ConfigService.getConfig(),
      ]);
      final config = results[1] as Config;
      if (!mounted) return;
      setState(() {
        _volunteers = results[0] as List<Volunteer>;
        _villages = [...config.villages]..sort(compareNaturally);
        _allWards = sortWardConfigs(config.wards);
        _updateFilteredWards();
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateFilteredWards() {
    if (_selectedVillage == 'All') {
      _filteredWards = ['All'];
    } else {
      _filteredWards =
          [
            'All',
            ..._allWards
                .where((ward) => ward.village == _selectedVillage)
                .map((ward) => ward.number),
          ]..sort((a, b) {
            if (a == 'All') return -1;
            if (b == 'All') return 1;
            return compareWardNumbers(a, b);
          });
    }

    if (!_filteredWards.contains(_selectedWard)) {
      _selectedWard = 'All';
    }
  }

  List<Volunteer> get _filteredVolunteers {
    final query = _searchController.text.trim();
    return _volunteers.where((volunteer) {
      if (_selectedVillage != 'All' && volunteer.village != _selectedVillage) {
        return false;
      }
      if (_selectedWard != 'All' && volunteer.ward != _selectedWard) {
        return false;
      }
      return volunteer.matches(query);
    }).toList();
  }

  Future<void> _openForm([Volunteer? volunteer]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VolunteerFormPage(volunteer: volunteer),
      ),
    );
    if (result == true) {
      await _loadData(showLoading: false);
    }
  }

  Future<void> _deleteVolunteer(Volunteer volunteer) async {
    if (volunteer.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete volunteer?'),
        content: Text('Delete ${volunteer.name} from volunteers?'),
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

    if (confirmed != true) return;

    try {
      await VolunteerService.deleteVolunteer(volunteer.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer deleted'),
          backgroundColor: _volunteerPrimary,
        ),
      );
      await _loadData(showLoading: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AdaptiveAppScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _volunteerSurface,
        surfaceTintColor: _volunteerSurface,
        foregroundColor: _volunteerPrimary,
        elevation: 1,
        title: const Text('Volunteers', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: auth.canCreate
          ? RevealActionFab(
              onPressed: () => _openForm(),
              backgroundColor: _volunteerPrimary,
              foregroundColor: Colors.white,
              icon: Icons.add,
              label: 'Add Volunteer',
            )
          : null,
      contentMaxWidth: 820,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody(auth)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name, phone, address, place or ward',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.grey.shade50,
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
                borderSide: const BorderSide(
                  color: _volunteerPrimary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  icon: Icons.location_city_outlined,
                  value: _selectedVillage,
                  items: ['All', ..._villages],
                  labelFor: (value) => value == 'All' ? 'All villages' : value,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedVillage = value;
                      _updateFilteredWards();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterDropdown(
                  icon: Icons.apartment_outlined,
                  value: _selectedWard,
                  items: _filteredWards,
                  labelFor: (value) =>
                      value == 'All' ? 'All wards' : 'Ward $value',
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedWard = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required String Function(String value) labelFor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$value-${items.join('|')}'),
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _volunteerPrimary, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(labelFor(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBody(AuthService auth) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _volunteerPrimary),
      );
    }

    if (_error != null) {
      return _messageState(
        Icons.cloud_off_outlined,
        'Could not load volunteers',
        _error!,
        action: OutlinedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    final volunteers = _filteredVolunteers;
    if (volunteers.isEmpty) {
      final hasFilters =
          _searchController.text.isNotEmpty ||
          _selectedVillage != 'All' ||
          _selectedWard != 'All';
      return _messageState(
        hasFilters ? Icons.search_off_outlined : Icons.group_add_outlined,
        hasFilters ? 'No matching volunteers' : 'No volunteers added',
        hasFilters
            ? 'Try another name, phone, village or ward.'
            : 'Add the first volunteer profile.',
      );
    }

    return RefreshIndicator(
      color: _volunteerPrimary,
      onRefresh: () => _loadData(showLoading: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: volunteers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _volunteerCard(volunteers[index], auth),
      ),
    );
  }

  Widget _volunteerCard(Volunteer volunteer, AuthService auth) {
    return InkWell(
      onTap: () => _showDetails(volunteer, auth),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _volunteerPrimary.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _avatar(),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volunteer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202333),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    volunteer.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _volunteerPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _inlineDetail(Icons.call_outlined, volunteer.phone),
                  if (volunteer.phone2.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _inlineDetail(
                      Icons.phone_iphone_outlined,
                      volunteer.phone2,
                    ),
                  ],
                  if (volunteer.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _inlineDetail(
                      Icons.home_outlined,
                      volunteer.address.trim(),
                    ),
                  ],
                ],
              ),
            ),
            if (auth.canEdit || auth.canDelete)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openForm(volunteer);
                  if (value == 'delete') _deleteVolunteer(volunteer);
                },
                itemBuilder: (context) => [
                  if (auth.canEdit)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
  }

  Widget _avatar({double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _volunteerIconSurface,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.volunteer_activism_outlined,
        color: _volunteerPrimary,
        size: size * 0.52,
      ),
    );
  }

  Widget _inlineDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showDetails(Volunteer volunteer, AuthService auth) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(size: 54),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        volunteer.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        volunteer.phone2.trim().isEmpty
                            ? volunteer.phone
                            : '${volunteer.phone} / ${volunteer.phone2}',
                        style: const TextStyle(
                          color: _volunteerPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _detailLine(
              Icons.location_city_outlined,
              'Village',
              volunteer.village,
            ),
            const SizedBox(height: 10),
            _detailLine(Icons.apartment_outlined, 'Ward', volunteer.wardLabel),
            const SizedBox(height: 10),
            _detailLine(Icons.place_outlined, 'Place', volunteer.place),
            if (volunteer.address.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailLine(
                Icons.home_outlined,
                'Address',
                volunteer.address.trim(),
              ),
            ],
            if (volunteer.phone2.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailLine(
                Icons.phone_iphone_outlined,
                'Second Phone',
                volunteer.phone2.trim(),
              ),
            ],
            if (auth.canEdit) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openForm(volunteer);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _volunteerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit volunteer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _volunteerPrimary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 14)),
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

  Widget _messageState(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) {
    return RefreshIndicator(
      color: _volunteerPrimary,
      onRefresh: () => _loadData(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 80),
          Icon(icon, color: _volunteerPrimary, size: 54),
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
      ),
    );
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class VolunteerFormPage extends StatefulWidget {
  final Volunteer? volunteer;

  const VolunteerFormPage({super.key, this.volunteer});

  @override
  State<VolunteerFormPage> createState() => _VolunteerFormPageState();
}

class _VolunteerFormPageState extends State<VolunteerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _phone2Controller;
  late final TextEditingController _placeController;
  late final TextEditingController _addressController;
  List<String> _villages = [];
  List<WardConfig> _allWards = [];
  List<String> _wardOptions = [];
  String? _selectedVillage;
  String? _selectedWard;
  bool _loadingConfig = true;
  bool _saving = false;
  String? _configError;

  bool get _editing => widget.volunteer != null;

  @override
  void initState() {
    super.initState();
    final volunteer = widget.volunteer;
    _nameController = TextEditingController(text: volunteer?.name);
    _phoneController = TextEditingController(text: volunteer?.phone);
    _phone2Controller = TextEditingController(text: volunteer?.phone2);
    _placeController = TextEditingController(text: volunteer?.place);
    _addressController = TextEditingController(text: volunteer?.address);
    _selectedVillage = volunteer?.village;
    _selectedWard = volunteer?.ward;
    _loadConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _placeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ConfigService.getConfig();
      if (!mounted) return;
      setState(() {
        _villages = [...config.villages]..sort(compareNaturally);
        _allWards = sortWardConfigs(config.wards);
        _updateWardOptions();
        _loadingConfig = false;
        _configError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _configError = _friendlyError(error);
        _loadingConfig = false;
      });
    }
  }

  void _updateWardOptions() {
    if (_selectedVillage == null) {
      _wardOptions = [];
    } else {
      _wardOptions =
          _allWards
              .where((ward) => ward.village == _selectedVillage)
              .map((ward) => ward.number)
              .toList()
            ..sort(compareWardNumbers);
    }

    if (_selectedWard != null && !_wardOptions.contains(_selectedWard)) {
      if (widget.volunteer?.ward == _selectedWard &&
          widget.volunteer?.village == _selectedVillage) {
        _wardOptions = [..._wardOptions, _selectedWard!]
          ..sort(compareWardNumbers);
      } else {
        _selectedWard = null;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final volunteer = Volunteer(
      id: widget.volunteer?.id,
      village: _selectedVillage!,
      ward: normalizeWardNumberValue(_selectedWard),
      place: _placeController.text.trim(),
      address: _addressController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      phone2: _phone2Controller.text.trim(),
    );

    try {
      if (_editing) {
        await VolunteerService.updateVolunteer(
          widget.volunteer!.id!,
          volunteer,
        );
      } else {
        await VolunteerService.createVolunteer(volunteer);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Volunteer updated' : 'Volunteer created'),
          backgroundColor: _volunteerPrimary,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return AdaptiveAppScaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: _volunteerSurface,
          foregroundColor: _volunteerPrimary,
          title: Text(_editing ? 'Edit Volunteer' : 'New Volunteer'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _volunteerPrimary),
        ),
        contentMaxWidth: 900,
      );
    }

    return AdaptiveAppScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _volunteerSurface,
        surfaceTintColor: _volunteerSurface,
        foregroundColor: _volunteerPrimary,
        title: Text(
          _editing ? 'Edit Volunteer' : 'New Volunteer',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            if (_configError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  _configError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            _formCard(
              title: 'Location',
              icon: Icons.map_outlined,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'village-${_selectedVillage ?? ''}-${_villageOptions.join('|')}',
                  ),
                  initialValue: _villageOptions.contains(_selectedVillage)
                      ? _selectedVillage
                      : null,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Village',
                    Icons.location_city_outlined,
                  ),
                  items: _villageOptions
                      .map(
                        (village) => DropdownMenuItem(
                          value: village,
                          child: Text(village),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVillage = value;
                      _selectedWard = null;
                      _updateWardOptions();
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Village is required' : null,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'ward-${_selectedWard ?? ''}-${_wardOptions.join('|')}',
                  ),
                  initialValue: _wardOptions.contains(_selectedWard)
                      ? _selectedWard
                      : null,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Ward',
                    Icons.apartment_outlined,
                  ),
                  hint: const Text('Select Ward'),
                  items: _wardOptions
                      .map(
                        (ward) => DropdownMenuItem(
                          value: ward,
                          child: Text('Ward $ward'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedWard = value),
                  validator: (value) =>
                      value == null ? 'Ward is required' : null,
                ),
                TextFormField(
                  controller: _placeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Place', Icons.place_outlined),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Place is required'
                      : null,
                ),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Address', Icons.home_outlined),
                  minLines: 1,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _formCard(
              title: 'Volunteer',
              icon: Icons.volunteer_activism_outlined,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Name', Icons.person_outline),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Phone', Icons.call_outlined),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Phone is required'
                      : null,
                ),
                TextFormField(
                  controller: _phone2Controller,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    'Second Phone',
                    Icons.phone_iphone_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      contentMaxWidth: 900,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _volunteerPrimary,
              foregroundColor: Colors.white,
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
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_editing ? 'Update Volunteer' : 'Save Volunteer'),
          ),
        ),
      ),
    );
  }

  List<String> get _villageOptions {
    final values = <String>{
      ..._villages,
      if (_selectedVillage?.trim().isNotEmpty == true) _selectedVillage!,
    }.toList()..sort(compareNaturally);
    return values;
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _volunteerPrimary.withValues(alpha: 0.06),
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
              Icon(icon, color: _volunteerPrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _volunteerPrimary, size: 20),
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
        borderSide: const BorderSide(color: _volunteerPrimary, width: 1.5),
      ),
    );
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
