import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/config.dart';
import 'package:oruma_app/models/staff_user.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/services/config_service.dart';
import 'package:oruma_app/services/staff_service.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/reveal_action_fab.dart';
import 'package:provider/provider.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF1A237E);
  static const _surfaceColor = Color(0xFFF7F8FB);
  static const _inkColor = Color(0xFF252A3A);
  static const _mutedInkColor = Color(0xFF687082);
  static const _lineColor = Color(0xFFE5E8F0);
  static const _fieldFillColor = Color(0xFFFBFCFE);
  static const _chipFillColor = Color(0xFFF3F6FB);
  static const _chipLineColor = Color(0xFFE0E5EF);
  static const _softAccentColor = Color(0xFFEFF2FB);
  static const _removeIconColor = Color(0xFF8F6F75);
  static const _roles = ['admin', 'staff', 'member', 'user'];

  late final TabController _tabController;

  Config? _config;
  List<StaffUser> _staff = [];
  final Set<String> _updatingStaffIds = <String>{};

  bool _isLoadingConfig = true;
  bool _isLoadingStaff = true;
  bool _isSavingConfig = false;
  String? _configErrorMessage;
  String? _staffErrorMessage;

  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _planController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  String? _selectedWardVillage;

  static InputDecoration _fieldDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(14));
    const enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: _lineColor, width: 1),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: _fieldFillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      suffixIcon: suffixIcon,
      prefixIconColor: _mutedInkColor,
      suffixIconColor: _mutedInkColor,
      hintStyle: const TextStyle(color: _mutedInkColor, fontSize: 15),
      labelStyle: const TextStyle(color: _mutedInkColor),
      floatingLabelStyle: const TextStyle(
        color: _primaryColor,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: enabledBorder,
      disabledBorder: enabledBorder,
      border: enabledBorder,
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Color(0xFFB9C1DD), width: 1.2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Color(0xFFE0A3A3), width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Color(0xFFC97979), width: 1.2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging && mounted) setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthService>().isAdmin) {
        _fetchConfig();
        _fetchStaff();
      } else {
        setState(() {
          _isLoadingConfig = false;
          _isLoadingStaff = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _villageController.dispose();
    _diseaseController.dispose();
    _planController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  void _ensureSelectedWardVillage(Config config) {
    if (config.villages.isEmpty) {
      _selectedWardVillage = null;
      return;
    }

    if (_selectedWardVillage == null ||
        !config.villages.contains(_selectedWardVillage)) {
      _selectedWardVillage = config.villages.first;
    }
  }

  Future<void> _fetchConfig() async {
    setState(() {
      _isLoadingConfig = true;
      _configErrorMessage = null;
    });

    try {
      final config = await ConfigService.getConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _ensureSelectedWardVillage(config);
        _isLoadingConfig = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _configErrorMessage = e.toString();
        _isLoadingConfig = false;
      });
    }
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoadingStaff = true;
      _staffErrorMessage = null;
    });

    try {
      final staff = await StaffService.getStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _isLoadingStaff = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _staffErrorMessage = e.toString();
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    setState(() => _isSavingConfig = true);
    try {
      final updatedConfig = await ConfigService.updateConfig(_config!);
      if (!mounted) return;
      setState(() {
        _config = updatedConfig;
        _ensureSelectedWardVillage(updatedConfig);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  void _addItem(String listName, TextEditingController controller) {
    if (controller.text.trim().isEmpty || _config == null) return;
    final item = controller.text.trim();

    setState(() {
      if (listName == 'villages' && !_config!.villages.contains(item)) {
        _config!.villages.add(item);
        _config!.villages.sort(compareNaturally);
        _ensureSelectedWardVillage(_config!);
      } else if (listName == 'diseases' && !_config!.diseases.contains(item)) {
        _config!.diseases.add(item);
        _config!.diseases.sort(compareNaturally);
      } else if (listName == 'plans' && !_config!.plans.contains(item)) {
        _config!.plans.add(item);
        _config!.plans.sort(compareNaturally);
      }
      controller.clear();
    });
  }

  void _removeItem(String listName, String item) {
    if (_config == null) return;
    setState(() {
      if (listName == 'villages') {
        _config!.villages.remove(item);
        _config!.wards.removeWhere((ward) => ward.village == item);
        _ensureSelectedWardVillage(_config!);
      } else if (listName == 'diseases') {
        _config!.diseases.remove(item);
      } else if (listName == 'plans') {
        _config!.plans.remove(item);
      }
    });
  }

  void _addWard() {
    if (_config == null || _selectedWardVillage == null) return;

    final wardNumber = normalizeWardNumberValue(_wardController.text);
    if (wardNumber.isEmpty) return;

    final exists = _config!.wards.any(
      (ward) =>
          ward.village == _selectedWardVillage && ward.number == wardNumber,
    );
    if (exists) {
      _wardController.clear();
      return;
    }

    setState(() {
      _config!.wards.add(
        WardConfig(number: wardNumber, village: _selectedWardVillage!),
      );
      _config!.wards.sort(compareWardConfigs);
      _wardController.clear();
    });
  }

  void _removeWard(WardConfig ward) {
    if (_config == null) return;

    setState(() {
      _config!.wards.removeWhere(
        (item) => item.village == ward.village && item.number == ward.number,
      );
    });
  }

  Future<void> _updateStaffRole(StaffUser staff, String role) async {
    if (staff.role == role || _updatingStaffIds.contains(staff.id)) return;

    setState(() => _updatingStaffIds.add(staff.id));
    try {
      final updated = await StaffService.updateRole(staff.id, role);
      if (!mounted) return;
      setState(() {
        final index = _staff.indexWhere((item) => item.id == staff.id);
        if (index != -1) {
          _staff[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} is now ${_roleLabel(role)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingStaffIds.remove(staff.id));
    }
  }

  Future<void> _showAddStaffSheet() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedRole = 'staff';
    var obscurePassword = true;
    var isSubmitting = false;
    String? formError;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> submit() async {
                if (!(formKey.currentState?.validate() ?? false) ||
                    isSubmitting) {
                  return;
                }

                final navigator = Navigator.of(sheetContext);
                final messenger = ScaffoldMessenger.of(this.context);
                setSheetState(() {
                  isSubmitting = true;
                  formError = null;
                });

                try {
                  final staff = await StaffService.createStaff(
                    name: nameController.text,
                    email: emailController.text,
                    password: passwordController.text,
                    role: selectedRole,
                  );
                  if (!mounted) return;
                  setState(() {
                    _staff = [..._staff, staff]..sort(_compareStaffUsers);
                  });
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('${staff.name} added to staff')),
                  );
                } catch (e) {
                  setSheetState(() {
                    formError = e.toString();
                    isSubmitting = false;
                  });
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _IconBadge(
                                  icon: Icons.person_add_alt_1_outlined,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Add Staff',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (value) =>
                                  value?.trim().isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(
                                labelText: 'Email',
                                prefixIcon: Icons.mail_outline,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'Email is required';
                                if (!email.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: _fieldDecoration(
                                labelText: 'Temporary password',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setSheetState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                if (password.length < 6) {
                                  return 'Use at least 6 characters';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => submit(),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: _fieldDecoration(
                                labelText: 'Role',
                                prefixIcon: Icons.admin_panel_settings,
                              ),
                              items: _roles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(_roleLabel(role)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (value) => setSheetState(
                                      () => selectedRole = value ?? 'staff',
                                    ),
                            ),
                            if (formError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                formError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSubmitting ? null : submit,
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.person_add_alt_1),
                                label: const Text('Add Staff'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final activeIndex = _tabController.index;

    return AdaptiveAppScaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text('System Configuration'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        bottom: auth.isAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.tune_outlined), text: 'Configuration'),
                  Tab(icon: Icon(Icons.groups_2_outlined), text: 'Staff'),
                ],
              )
            : null,
      ),
      body: auth.isAdmin
          ? Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [_buildConfigurationView(), _buildStaffView()],
                ),
                if (_isSavingConfig)
                  Container(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            )
          : _buildAccessDenied(),
      floatingActionButton: auth.isAdmin
          ? RevealActionFab(
              onPressed: activeIndex == 0
                  ? (_isLoadingConfig || _config == null || _isSavingConfig
                        ? null
                        : _saveConfig)
                  : (_isLoadingStaff ? null : _showAddStaffSheet),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              icon: activeIndex == 0 ? Icons.save_outlined : Icons.person_add,
              label: activeIndex == 0 ? 'Save Changes' : 'Add Staff',
            )
          : null,
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: Icons.lock_outline,
              color: Colors.red.shade700,
              size: 64,
            ),
            const SizedBox(height: 18),
            const Text(
              'Admin Access Required',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'System configuration is available only for admin users.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationView() {
    if (_isLoadingConfig && _config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_configErrorMessage != null && _config == null) {
      return _ErrorState(message: _configErrorMessage!, onRetry: _fetchConfig);
    }

    final config = _config!;

    return RefreshIndicator(
      onRefresh: _fetchConfig,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          _buildOverviewHeader(config),
          const SizedBox(height: 10),
          _buildListSection(
            title: 'Villages',
            icon: Icons.location_city_outlined,
            listName: 'villages',
            items: config.villages,
            controller: _villageController,
            hintText: 'Add village',
          ),
          _buildWardSection(),
          _buildListSection(
            title: 'Diseases',
            icon: Icons.medical_information_outlined,
            listName: 'diseases',
            items: config.diseases,
            controller: _diseaseController,
            hintText: 'Add disease',
          ),
          _buildListSection(
            title: 'Plans',
            icon: Icons.event_repeat_outlined,
            listName: 'plans',
            items: config.plans,
            controller: _planController,
            hintText: 'Add care plan',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader(Config config) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(
                icon: Icons.admin_panel_settings,
                color: _primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Configuration Hub',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isLoadingConfig ? null : _fetchConfig,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: 'Villages',
                value: config.villages.length.toString(),
                icon: Icons.location_city_outlined,
              ),
              _MetricPill(
                label: 'Wards',
                value: config.wards.length.toString(),
                icon: Icons.map_outlined,
              ),
              _MetricPill(
                label: 'Diseases',
                value: config.diseases.length.toString(),
                icon: Icons.medical_information_outlined,
              ),
              _MetricPill(
                label: 'Plans',
                value: config.plans.length.toString(),
                icon: Icons.event_repeat_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required String listName,
    required List<String> items,
    required TextEditingController controller,
    required String hintText,
  }) {
    return _ConfigSection(
      title: title,
      icon: icon,
      count: items.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AddInlineField(
            controller: controller,
            hintText: hintText,
            onSubmitted: () => _addItem(listName, controller),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyInlineState(label: 'No ${title.toLowerCase()} added yet')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return _ConfigChip(
                  label: Text(item),
                  icon: icon,
                  onDeleted: () => _removeItem(listName, item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWardSection() {
    final wards = _config == null
        ? const <WardConfig>[]
        : sortWardConfigs(_config!.wards);
    final selectedVillage = _selectedWardVillage;
    final selectedWards = selectedVillage == null
        ? const <WardConfig>[]
        : wards.where((ward) => ward.village == selectedVillage).toList();

    return _ConfigSection(
      title: 'Wards',
      icon: Icons.map_outlined,
      count: wards.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedWardVillage),
            initialValue: _selectedWardVillage,
            decoration: _fieldDecoration(
              labelText: 'Village',
              prefixIcon: Icons.location_city_outlined,
            ),
            items: (_config?.villages ?? [])
                .map(
                  (village) =>
                      DropdownMenuItem(value: village, child: Text(village)),
                )
                .toList(),
            onChanged: (_config?.villages.isEmpty ?? true)
                ? null
                : (value) => setState(() => _selectedWardVillage = value),
          ),
          const SizedBox(height: 10),
          _AddInlineField(
            controller: _wardController,
            hintText: 'Add ward number',
            enabled: (_config?.villages.isNotEmpty ?? false),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: _addWard,
          ),
          const SizedBox(height: 12),
          if (selectedVillage == null)
            const _EmptyInlineState(label: 'Add a village before adding wards')
          else if (selectedWards.isEmpty)
            Text(
              'No wards added for $selectedVillage yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedWards.map((ward) {
                return _ConfigChip(
                  label: Text('Ward ${ward.number}'),
                  icon: Icons.map_outlined,
                  onDeleted: () => _removeWard(ward),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStaffView() {
    if (_isLoadingStaff && _staff.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_staffErrorMessage != null && _staff.isEmpty) {
      return _ErrorState(message: _staffErrorMessage!, onRetry: _fetchStaff);
    }

    final roleCounts = {
      for (final role in _roles)
        role: _staff.where((staff) => staff.role == role).length,
    };

    return RefreshIndicator(
      onRefresh: _fetchStaff,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _IconBadge(
                      icon: Icons.groups_2_outlined,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Staff Module',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoadingStaff ? null : _fetchStaff,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      label: 'Total',
                      value: _staff.length.toString(),
                      icon: Icons.badge_outlined,
                    ),
                    for (final role in _roles)
                      _MetricPill(
                        label: _roleLabel(role),
                        value: roleCounts[role].toString(),
                        icon: _roleIcon(role),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_staff.isEmpty)
            const _EmptyStaffState()
          else
            ..._staff.map(_buildStaffCard),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffUser staff) {
    final isUpdating = _updatingStaffIds.contains(staff.id);
    final joined = staff.createdAt == null
        ? 'Joined date unavailable'
        : 'Joined ${DateFormat('dd MMM yyyy').format(staff.createdAt!.toLocal())}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 540;
            final profile = Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _roleColor(
                    staff.role,
                  ).withValues(alpha: 0.12),
                  foregroundColor: _roleColor(staff.role),
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name.isEmpty ? 'Unnamed staff' : staff.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        staff.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        joined,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final roleControl = SizedBox(
              width: compact ? double.infinity : 190,
              child: DropdownButtonFormField<String>(
                key: ValueKey('${staff.id}:${staff.role}'),
                initialValue: _roles.contains(staff.role)
                    ? staff.role
                    : 'staff',
                decoration: _fieldDecoration(
                  labelText: 'Role',
                  prefixIcon: isUpdating ? null : _roleIcon(staff.role),
                  suffixIcon: isUpdating
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                items: _roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: isUpdating
                    ? null
                    : (role) {
                        if (role != null) _updateStaffRole(staff, role);
                      },
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [profile, const SizedBox(height: 14), roleControl],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: profile),
                const SizedBox(width: 16),
                roleControl,
              ],
            );
          },
        ),
      ),
    );
  }

  static int _compareStaffUsers(StaffUser a, StaffUser b) {
    final roleCompare = _roles
        .indexOf(a.role)
        .compareTo(_roles.indexOf(b.role));
    if (roleCompare != 0) return roleCompare;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      case 'member':
        return 'Member';
      default:
        return 'User';
    }
  }

  static IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'staff':
        return Icons.medical_services_outlined;
      case 'member':
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.person_outline;
    }
  }

  static Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return _primaryColor;
      case 'staff':
        return const Color(0xFF0F6E56);
      case 'member':
        return const Color(0xFF8A2454);
      default:
        return const Color(0xFF656A73);
    }
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
  });

  final String title;
  final IconData icon;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon, color: _ConfigPageState._primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ConfigPageState._primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _ConfigPageState._softAccentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: _ConfigPageState._primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.margin = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _ConfigPageState._lineColor),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _AddInlineField extends StatelessWidget {
  const _AddInlineField({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSubmitted;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: _ConfigPageState._fieldDecoration(
              hintText: hintText,
              prefixIcon: Icons.edit_outlined,
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filledTonal(
            tooltip: hintText,
            onPressed: enabled ? onSubmitted : null,
            style: IconButton.styleFrom(
              backgroundColor: _ConfigPageState._softAccentColor,
              foregroundColor: _ConfigPageState._primaryColor,
              disabledBackgroundColor: const Color(0xFFF1F2F5),
              disabledForegroundColor: _ConfigPageState._mutedInkColor,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.add_rounded, size: 24),
          ),
        ),
      ],
    );
  }
}

class _ConfigChip extends StatelessWidget {
  const _ConfigChip({
    required this.label,
    required this.icon,
    required this.onDeleted,
  });

  final Widget label;
  final IconData icon;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: DefaultTextStyle.merge(
        style: const TextStyle(
          color: _ConfigPageState._inkColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        child: label,
      ),
      avatar: Icon(
        icon,
        size: 15,
        color: _ConfigPageState._primaryColor.withValues(alpha: 0.84),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      onDeleted: onDeleted,
      backgroundColor: _ConfigPageState._chipFillColor,
      selectedColor: _ConfigPageState._softAccentColor,
      deleteIconColor: _ConfigPageState._removeIconColor,
      side: const BorderSide(color: _ConfigPageState._chipLineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelPadding: const EdgeInsets.only(left: 2, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size <= 40 ? 21 : 26),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _ConfigPageState._fieldFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ConfigPageState._lineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _ConfigPageState._mutedInkColor),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _ConfigPageState._primaryColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _ConfigPageState._mutedInkColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  const _EmptyInlineState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

class _EmptyStaffState extends StatelessWidget {
  const _EmptyStaffState();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          _IconBadge(
            icon: Icons.group_add_outlined,
            color: _ConfigPageState._primaryColor,
            size: 58,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Staff Added',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Staff accounts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: Icons.error_outline,
              color: Colors.red.shade700,
              size: 62,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
