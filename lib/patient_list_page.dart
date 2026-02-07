import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/services/patient_service.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/pt_registration.dart';
import 'package:oruma_app/patient_details_page.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  // Data
  List<Patient> _allPatients = [];
  PatientCounts? _counts;
  bool _isLoading = true;
  String? _error;
  String _currentFilter = 'all';

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await PatientService.getPatientsList(filter: _currentFilter);
      if (mounted) {
        setState(() {
          _allPatients = response.patients;
          _counts = response.counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search patients...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : const Text("Patients"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPatients,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_counts != null) _buildFilterTabs(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text("Error: $_error"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPatients,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                // Client-side filtering as fallback/robustness
                // We check if the API returned a mixed list despite the filter request.
                final filteredPatients = _allPatients.where((p) {
                  // Text search filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchesSearch =
                        p.name.toLowerCase().contains(q) ||
                        p.village.toLowerCase().contains(q) ||
                        (p.registerId ?? '').toLowerCase().contains(q) ||
                        p.phone.toLowerCase().contains(q);
                    if (!matchesSearch) return false;
                  }

                  // Status filter (double check in case API returns mixed results)
                  if (_currentFilter == 'alive' && p.isDead) return false;
                  if (_currentFilter == 'dead' && !p.isDead) return false;

                  return true;
                }).toList();

                if (filteredPatients.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No matching patients found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text("No patients found."));
                }

                return RefreshIndicator(
                  onRefresh: _loadPatients,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPatients.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildPatientCard(context, patient);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const patientrigister()),
          );
          if (result == true) {
            _loadPatients();
          }
        },
        label: const Text("Add Patient"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTab("All", _counts?.allCount ?? 0, 'all'),
            _buildTab("Active", _counts?.aliveCount ?? 0, 'alive'),
            _buildTab("Dead", _counts?.deadCount ?? 0, 'dead'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, String filterKey) {
    final isSelected = _currentFilter == filterKey;
    
    // Determine color based on filter type
    Color activeColor;
    if (filterKey == 'alive') {
      activeColor = Colors.green.shade700;
    } else if (filterKey == 'dead') {
      activeColor = Colors.red.shade700;
    } else {
      activeColor = Colors.blue.shade700;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentFilter != filterKey) {
            setState(() {
              _currentFilter = filterKey;
            });
            _loadPatients();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? activeColor : Colors.grey.shade600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? activeColor.withOpacity(0.1) 
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEditPatient(Patient patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => patientrigister(patient: patient),
      ),
    );
    if (result != null) {
      _loadPatients();
    }
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${patient.name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && patient.id != null) {
      try {
        await PatientService.deletePatient(patient.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Patient deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPatients();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error deleting patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.isAdmin;

    Widget cardContent = Card(
      elevation: 0,
      color: patient.isDead ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: patient.isDead
                  ? Colors.grey.shade300
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: patient.isDead
                  ? const Icon(Icons.person_off, color: Colors.grey)
                  : Text(
                      patient.name.isNotEmpty
                          ? patient.name[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              patient.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (patient.registerId != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "REG ID: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: patient.registerId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  "${patient.age} years • ${patient.gender} • ${patient.plan}",
                ),
                Text(
                  patient.place,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsPage(patient: patient),
                ),
              );
              if (result == true) {
                _loadPatients();
              }
            },
          ),
          if (patient.isDead)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "PASSED AWAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (isAdmin) {
      // Wrap in a container to provide margin if needed, but Card already provides some.
      // However, for slidable to look good with rounded card, we might need ClipRRect.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Slidable(
            key: ValueKey(patient.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (_) => _navigateToEditPatient(patient),
                  backgroundColor: const Color(0xFF21B7CA),
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
                SlidableAction(
                  onPressed: (_) => _deletePatient(patient),
                  backgroundColor: const Color(0xFFFE4A49),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
