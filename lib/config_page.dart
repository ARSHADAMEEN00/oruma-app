import 'package:flutter/material.dart';
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
    super.dispose();
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
      await ConfigService.updateConfig(_config!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
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
      } else if (listName == 'diseases') {
        _config!.diseases.remove(item);
      } else if (listName == 'plans') {
        _config!.plans.remove(item);
      }
    });
  }

  Widget _buildListSection(String title, String listName, List<String> items, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Add new $title item',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _addItem(listName, controller),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addItem(listName, controller),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF1A237E), size: 32),
                )
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
                      Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchConfig,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : Stack(
                children: [
                  ListView(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                      children: [
                        _buildListSection('Villages', 'villages', _config!.villages, _villageController),
                        _buildListSection('Diseases', 'diseases', _config!.diseases, _diseaseController),
                        _buildListSection('Plans', 'plans', _config!.plans, _planController),
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
        label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
