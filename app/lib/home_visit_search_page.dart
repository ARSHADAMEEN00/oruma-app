import 'package:flutter/material.dart';
import 'package:oruma_app/homevisit.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/services/home_visit_service.dart';
import 'package:intl/intl.dart';

class HomeVisitSearchPage extends StatefulWidget {
  const HomeVisitSearchPage({super.key});

  @override
  State<HomeVisitSearchPage> createState() => _HomeVisitSearchPageState();
}

class _HomeVisitSearchPageState extends State<HomeVisitSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<HomeVisit> _allVisits = [];
  List<HomeVisit> _filteredVisits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisits();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    try {
      final visits = await HomeVisitService.getAllHomeVisits();
      setState(() {
        _allVisits = visits;
        _filteredVisits = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterVisits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVisits = [];
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredVisits = _allVisits.where((visit) {
          return visit.patientName.toLowerCase().contains(lowerQuery) ||
              visit.address.toLowerCase().contains(lowerQuery) ||
              (visit.notes?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
        
        // Sort by date (most recent first)
        _filteredVisits.sort((a, b) {
          final dateA = DateTime.tryParse(a.visitDate);
          final dateB = DateTime.tryParse(b.visitDate);
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterVisits('');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _filterVisits,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search by patient name, address...",
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: _buildBody(primaryColor),
    );
  }

  Widget _buildBody(Color primaryColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text("Error: $_error"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVisits,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildSearchPrompt();
    }

    if (_filteredVisits.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults(primaryColor);
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Search Home Visits",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Search by patient name, address, or notes",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  "${_allVisits.length} total visits available",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                "${_filteredVisits.length} ${_filteredVisits.length == 1 ? 'result' : 'results'} found",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredVisits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final visit = _filteredVisits[index];
              return _buildVisitCard(visit, primaryColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(HomeVisit visit, Color primaryColor) {
    final date = DateTime.tryParse(visit.visitDate);
    final now = DateTime.now();
    final isToday = date != null && 
        date.year == now.year && 
        date.month == now.month && 
        date.day == now.day;
    final isPast = date != null && date.isBefore(DateTime(now.year, now.month, now.day));
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showVisitDetails(visit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isToday 
                      ? Colors.green.withOpacity(0.1) 
                      : isPast 
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date != null ? DateFormat('dd').format(date) : '??',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isToday 
                            ? Colors.green.shade700
                            : isPast 
                                ? Colors.grey.shade600
                                : Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      date != null ? DateFormat('MMM').format(date).toUpperCase() : 'N/A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday 
                            ? Colors.green.shade700
                            : isPast 
                                ? Colors.grey.shade600
                                : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Visit Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, 
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visit.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notes_outlined, 
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visit.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitDetails(HomeVisit visit) {
    final date = DateTime.tryParse(visit.visitDate);
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Home Visit Details",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visit.patientName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.home_work_rounded, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow(Icons.calendar_today, "Visit Date", 
              date != null ? DateFormat('EEEE, d MMMM yyyy').format(date) : "N/A"),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.location_on, "Address", visit.address),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.notes, "Notes", visit.notes ?? "No notes provided"),
            if (visit.createdBy != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  "Created by: ${visit.createdBy}",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Homevisit(visit: visit)),
                  );
                  if (result == true) {
                    _loadVisits();
                    _filterVisits(_searchController.text);
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Edit Details"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
