import 'package:flutter/material.dart';
import 'package:oruma_app/homevisit.dart';
import 'package:oruma_app/home_visit_search_page.dart';
import 'package:oruma_app/models/home_visit.dart';
import 'package:oruma_app/services/home_visit_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/services/auth_service.dart';

class HomeVisitListPage extends StatefulWidget {
  const HomeVisitListPage({super.key});

  @override
  State<HomeVisitListPage> createState() => _HomeVisitListPageState();
}

class _HomeVisitListPageState extends State<HomeVisitListPage> {
  late Future<List<HomeVisit>> _visitsFuture;
  List<HomeVisit> _allVisits = [];
  
  // Date navigation
  late DateTime _selectedDate;
  late DateTime _startOfWeek;
  late List<DateTime> _weekDates;
  late PageController _pageController;
  
  // Key to force PageView rebuild
  Key _pageViewKey = UniqueKey();
  
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeWeek();
    _pageController = PageController(initialPage: _getSelectedDateIndex());
    _refreshVisits();
  }

  void _initializeWeek() {
    // Start from 3 days ago to show past visits too
    final now = DateTime.now();
    _startOfWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
    // Generate 14 days (2 weeks view)
    _weekDates = List.generate(14, (i) => _startOfWeek.add(Duration(days: i)));
  }

  int _getSelectedDateIndex() {
    for (int i = 0; i < _weekDates.length; i++) {
      if (_isSameDay(_weekDates[i], _selectedDate)) {
        return i;
      }
    }
    return 3; // Default to "today" position
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _refreshVisits() {
    setState(() {
      _visitsFuture = HomeVisitService.getAllHomeVisits().then((visits) {
        _allVisits = visits;
        return visits;
      });
    });
  }

  List<HomeVisit> _getVisitsForDate(DateTime date) {
    return _allVisits.where((visit) {
      final visitDate = DateTime.tryParse(visit.visitDate);
      if (visitDate == null) return false;
      return _isSameDay(visitDate, date);
    }).toList();
  }

  int _getVisitCountForDate(DateTime date) {
    return _getVisitsForDate(date).length;
  }

  void _onDateSelected(int index) {
    setState(() {
      _selectedDate = _weekDates[index];
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _rebuildPageView(int initialPage) {
    _pageController.dispose();
    _pageController = PageController(initialPage: initialPage);
    _pageViewKey = UniqueKey();
  }

  void _goToPreviousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
      _weekDates = List.generate(14, (i) => _startOfWeek.add(Duration(days: i)));
      _selectedDate = _weekDates[3]; // Select the 4th day
      _rebuildPageView(3);
    });
  }

  void _goToNextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
      _weekDates = List.generate(14, (i) => _startOfWeek.add(Duration(days: i)));
      _selectedDate = _weekDates[3];
      _rebuildPageView(3);
    });
  }

  void _goToToday() {
    setState(() {
      final now = DateTime.now();
      _startOfWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
      _weekDates = List.generate(14, (i) => _startOfWeek.add(Duration(days: i)));
      _selectedDate = DateTime.now();
      _rebuildPageView(3);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Home Visits", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!isToday)
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 18),
              label: const Text("Today"),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeVisitSearchPage()),
              );
              _refreshVisits();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVisits,
          ),
        ],
      ),
      body: FutureBuilder<List<HomeVisit>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          return Column(
            children: [
              // Week Navigation Header
              _buildWeekNavigationHeader(primaryColor),
              
              // Date Tabs
              _buildDateTabs(primaryColor),
              
              // Selected Date Header
              _buildSelectedDateHeader(),
              
              // Visits for Selected Date (PageView for swipe)
              Expanded(
                child: PageView.builder(
                  key: _pageViewKey,
                  controller: _pageController,
                  itemCount: _weekDates.length,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedDate = _weekDates[index];
                    });
                  },
                  itemBuilder: (context, index) {
                    final date = _weekDates[index];
                    final visits = _getVisitsForDate(date);
                    return _buildVisitsList(visits);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Homevisit()),
          );
          if (result == true) _refreshVisits();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Schedule Visit"),
      ),
    );
  }

  Widget _buildWeekNavigationHeader(Color primaryColor) {
    final monthYear = DateFormat('MMMM yyyy').format(_selectedDate);
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousWeek,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          Text(
            monthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _goToNextWeek,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTabs(Color primaryColor) {
    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _weekDates.length,
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final visitCount = _getVisitCountForDate(date);
          final hasVisits = visitCount > 0;

          return GestureDetector(
            onTap: () => _onDateSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryColor 
                    : isToday 
                        ? primaryColor.withOpacity(0.1) 
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected 
                    ? Border.all(color: primaryColor, width: 2) 
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white.withOpacity(0.8) 
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasVisits)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.25) 
                            : primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$visitCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateHeader() {
    final visitCount = _getVisitCountForDate(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)));
    final isYesterday = _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)));
    
    String dateLabel;
    if (isToday) {
      dateLabel = "Today";
    } else if (isTomorrow) {
      dateLabel = "Tomorrow";
    } else if (isYesterday) {
      dateLabel = "Yesterday";
    } else {
      dateLabel = DateFormat('EEEE').format(_selectedDate);
    }
    
    final fullDate = DateFormat('d MMMM yyyy').format(_selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: visitCount > 0 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 18,
                  color: visitCount > 0 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '$visitCount ${visitCount == 1 ? 'visit' : 'visits'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: visitCount > 0 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(List<HomeVisit> visits) {
    if (visits.isEmpty) {
      return _buildEmptyDayState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _buildVisitCard(context, visit, index + 1);
      },
    );
  }

  Widget _buildVisitCard(BuildContext context, HomeVisit visit, int visitNumber) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showVisitDetails(context, visit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Visit Number Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#$visitNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Visit Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  void _showVisitDetails(BuildContext context, HomeVisit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVisitDetailsSheet(context, visit),
    );
  }

  Widget _buildVisitDetailsSheet(BuildContext context, HomeVisit visit) {
    final date = DateTime.tryParse(visit.visitDate);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
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
          Row(
            children: [
              if (context.read<AuthService>().isAdmin) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteVisit(visit);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text("Delete", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Homevisit(visit: visit)),
                    );
                    if (result == true) _refreshVisits();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Edit Details"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Future<void> _deleteVisit(HomeVisit visit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Visit?"),
        content: Text("Are you sure you want to delete the visit for ${visit.patientName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await HomeVisitService.deleteHomeVisit(visit.id!);
        _refreshVisits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visit deleted successfully"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildEmptyDayState() {
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
              Icons.event_available_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No visits scheduled",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This day is free!",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Oops! Something went wrong", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _refreshVisits, child: const Text("Try Again")),
          ],
        ),
      ),
    );
  }
}
