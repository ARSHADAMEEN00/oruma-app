import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oruma_app/models/config.dart';
import 'package:oruma_app/services/config_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  Config? _config;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _planController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  String? _selectedWardVillage;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  @override
  void dispose() {
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
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final config = await ConfigService.getConfig();
      setState(() {
        _config = config;
        _ensureSelectedWardVillage(config);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedConfig = await ConfigService.updateConfig(_config!);
      if (mounted) {
        setState(() {
          _config = updatedConfig;
          _ensureSelectedWardVillage(updatedConfig);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItem(String listName, TextEditingController controller) {
    if (controller.text.trim().isEmpty || _config == null) return;
    final item = controller.text.trim();

    setState(() {
      if (listName == 'villages' && !_config!.villages.contains(item)) {
        _config!.villages.add(item);
        _ensureSelectedWardVillage(_config!);
      } else if (listName == 'diseases' && !_config!.diseases.contains(item)) {
        _config!.diseases.add(item);
      } else if (listName == 'plans' && !_config!.plans.contains(item)) {
        _config!.plans.add(item);
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

  Widget _buildListSection(
    String title,
    String listName,
    List<String> items,
    TextEditingController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Add new $title item',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _addItem(listName, controller),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addItem(listName, controller),
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF1A237E),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Chip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeItem(listName, item),
                  backgroundColor: Colors.blue.shade50,
                  deleteIconColor: Colors.red,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardSection() {
    final wards = _config == null
        ? const <WardConfig>[]
        : sortWardConfigs(_config!.wards);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedWardVillage,
              decoration: InputDecoration(
                hintText: 'Select village',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wardController,
                    enabled: (_config?.villages.isNotEmpty ?? false),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Add ward number',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _addWard(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: (_config?.villages.isEmpty ?? true)
                      ? null
                      : _addWard,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF1A237E),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (wards.isEmpty)
              Text(
                'No wards added yet',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wards.map((ward) {
                  return Chip(
                    label: Text('${ward.village} - Ward ${ward.number}'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeWard(ward),
                    backgroundColor: Colors.blue.shade50,
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _config == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchConfig,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                  children: [
                    _buildListSection(
                      'Villages',
                      'villages',
                      _config!.villages,
                      _villageController,
                    ),
                    _buildWardSection(),
                    _buildListSection(
                      'Diseases',
                      'diseases',
                      _config!.diseases,
                      _diseaseController,
                    ),
                    _buildListSection(
                      'Plans',
                      'plans',
                      _config!.plans,
                      _planController,
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveConfig,
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Save Changes',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
