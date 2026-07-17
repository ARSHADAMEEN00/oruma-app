import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oruma_app/billing_plan_screen.dart';
import 'package:oruma_app/eq_supply.dart';
import 'package:oruma_app/equipment_list_page.dart';
import 'package:oruma_app/equipment_supply_list_page.dart';
import 'package:oruma_app/home_visit_list_page.dart';
import 'package:oruma_app/medicine_list_page.dart';
import 'package:oruma_app/medicine_supply_list_page.dart';
import 'package:oruma_app/social_support_list_page.dart';
import 'package:oruma_app/volunteer_list_page.dart';
import 'package:oruma_app/pt_registration.dart' show patientrigister;
import 'package:oruma_app/patient_list_page.dart';
import 'package:oruma_app/deceased_patient_list_page.dart';
import 'package:provider/provider.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:oruma_app/loginscreen.dart';
import 'package:oruma_app/services/equipment_supply_service.dart';
import 'package:oruma_app/services/notification_service.dart';
import 'package:oruma_app/models/app_notification.dart';
import 'package:oruma_app/models/equipment_supply.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oruma_app/config_page.dart';
import 'package:oruma_app/widgets/adaptive_app_scaffold.dart';
import 'package:oruma_app/widgets/app_bottom_nav_router.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';
import 'package:oruma_app/widgets/module_theme.dart';
import 'package:oruma_app/widgets/unit_brand_avatar.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/features/visit_assessment/presentation/screens/visit_assessment_visit_picker_screen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _activeSuppliesScrollController = ScrollController();
  Timer? _activeSuppliesAutoSlideTimer;
  int _activeSuppliesPageIndex = 0;
  List<EquipmentSupply> _activeSupplies = [];
  bool _activeSuppliesLoading = true;
  int _notificationCount = 0;
  List<AppNotification> _notifications = [];
  bool _notificationsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeSuppliesAutoSlideTimer?.cancel();
    _activeSuppliesScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthService>().fetchUserProfile();
    }
  }

  Future<void> _bootstrapAccess() async {
    final auth = context.read<AuthService>();
    await auth.fetchUserProfile();
    if (!mounted || auth.isAccessBlocked) return;
    _loadActiveSupplies();
    _loadNotifications();
  }

  Future<void> _loadActiveSupplies() async {
    try {
      final supplies = await EquipmentSupplyService.getActiveSupplies();
      if (!mounted) return;
      setState(() {
        _activeSupplies = supplies;
        _activeSuppliesLoading = false;
        _activeSuppliesPageIndex = 0;
      });
      if (_activeSuppliesScrollController.hasClients) {
        _activeSuppliesScrollController.jumpTo(0);
      }
      _restartActiveSuppliesAutoSlide();
    } catch (e) {
      if (!mounted) return;
      setState(() => _activeSuppliesLoading = false);
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    try {
      final notifications = await NotificationService.getActiveNotifications(
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _notificationCount = notifications.length;
        _notificationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _notificationsLoading = false);
    }
  }

  Future<void> _openNotifications() async {
    await _loadNotifications(refresh: true);
    if (!mounted) return;
    _showNotifications();
  }

  void _restartActiveSuppliesAutoSlide() {
    _activeSuppliesAutoSlideTimer?.cancel();
    if (_activeSupplies.length <= 1) return;

    _activeSuppliesAutoSlideTimer = Timer.periodic(const Duration(seconds: 4), (
      _,
    ) {
      if (!mounted || !_activeSuppliesScrollController.hasClients) return;
      final availableWidth = MediaQuery.sizeOf(context).width - 40;
      final visibleCount = _activeSuppliesVisibleCount(availableWidth);
      final maxStart = (_activeSupplies.length - visibleCount)
          .clamp(0, _activeSupplies.length - 1)
          .toInt();
      if (maxStart <= 0) return;

      final next = (_activeSuppliesPageIndex + 1) % (maxStart + 1);
      final cardExtent = _activeSupplyCardWidth(availableWidth) + 12;
      final targetOffset = (next * cardExtent).clamp(
        0.0,
        _activeSuppliesScrollController.position.maxScrollExtent,
      );
      setState(() => _activeSuppliesPageIndex = next);
      _activeSuppliesScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showNotifications() {
    final notifications = List<AppNotification>.from(_notifications);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.64,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$_notificationCount Active",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _notificationsLoading && notifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No notifications",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final color = _notificationColor(notification);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _notificationIcon(notification),
                              color: color,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        notification.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatNotificationTime(
                                        notification.triggeredAt,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleNotificationTap(notification);
                          },
                        );
                      },
                    ),
            ),
            if (notifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openNotifications();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Refresh Notifications",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (notification.id != null) {
      NotificationService.markRead(
        notification.id!,
      ).then((_) => _loadNotifications(refresh: true)).catchError((_) {});
    }

    if (notification.type == 'equipment_overdue') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ModuleTheme(
            palette: ModulePalettes.equipmentSupply,
            child: EquipmentSupplyListPage(),
          ),
        ),
      );
      return;
    }

    if (notification.type.startsWith('medicine_expiry')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ModuleTheme(
            palette: ModulePalettes.medicineSupply,
            child: MedicineListPage(),
          ),
        ),
      );
    }
  }

  // Helper widget to build the Quick Add Bottom Sheet
  void _showQuickAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Add",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionItem(
                  icon: Icons.person_add_rounded,
                  label: "Patient",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModuleTheme(
                          palette: ModulePalettes.patients,
                          child: patientrigister(),
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.add_home_work_rounded,
                  label: "Visit",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Home Visit Form if available, or List
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModuleTheme(
                          palette: ModulePalettes.homeVisits,
                          child: HomeVisitListPage(),
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.medical_services_rounded,
                  label: "Supply",
                  color: Colors.orange,
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModuleTheme(
                          palette: ModulePalettes.equipmentSupply,
                          child: EqSupply(),
                        ),
                      ),
                    );
                    _loadActiveSupplies();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final auth = context.watch<AuthService>();
        final user = auth.user;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const UnitBrandAvatar(
                    size: 80,
                    preferAppIcon: true,
                    backgroundColor: Color(0xFF1A237E),
                    iconColor: Colors.white,
                    fallbackIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    auth.unitName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    user?['name'] ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    user?['email'] ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: "Billing & Plan",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BillingPlanScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpAndSupport(context);
                    },
                  ),
                  const Divider(height: 32),
                  _buildProfileMenuItem(
                    icon: Icons.logout,
                    title: "Logout",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context); // Close sheet
                      context.read<AuthService>().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const Loginscreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final auth = context.watch<AuthService>();
        final supportPhone = auth.unitSupportPhone;
        final supportPhoneDial = auth.unitSupportPhoneDial;

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF0277BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.contact_support,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Help & Support",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Color(0xFF1A237E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.unitName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    auth.unitLocation,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.phone,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Contact Number",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    supportPhone ?? 'Not added',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: supportPhoneDial == null
                          ? null
                          : () async {
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: supportPhoneDial,
                              );
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not launch phone dialer',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text(
                        "Make a Call",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQRModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/QR.jpeg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (kIsWeb) {
                      return Image.network(
                        'assets/QR.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const _QrImageFallback(),
                      );
                    }

                    return const _QrImageFallback();
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
              child: Text(
                'ORUMA PALLIATIVE CARE SOCIETY KODUR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF1A237E)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF1A237E), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[800],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleBottomNavigation(AppBottomSection section) {
    AppBottomNavRouter.handle(
      context,
      current: AppBottomSection.home,
      target: section,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('User Role: ${context.read<AuthService>().role}');
    final auth = context.watch<AuthService>();
    return AdaptiveAppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: _buildProfessionalDrawer(context),
      backgroundColor: Colors.white,
      currentSection: AppBottomSection.home,
      onNavigationSelected: _handleBottomNavigation,
      contentMaxWidth: 1040,
      // floatingActionButton: context.watch<AuthService>().canCreate
      //     ? FloatingActionButton(
      //         onPressed: _showQuickAddOptions,
      //         backgroundColor: const Color(0xFF1A237E),
      //         child: const Icon(Icons.add, color: Colors.white),
      //       )
      //     : null,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E), // Deep Blue
                  Color(0xFF0277BD), // Light Blue
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showQRModal(context),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _openNotifications,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              if (_notificationCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _notificationCount > 99
                                            ? '99+'
                                            : _notificationCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showUserProfile(context),
                          child: const UnitBrandAvatar(
                            size: 36,
                            preferAppIcon: true,
                            backgroundColor: Colors.white,
                            iconColor: Color(0xFF1A237E),
                            fallbackIcon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back,",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.unitName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  auth.unitLocation,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (auth.unitSupportPhone != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    "Support: ${auth.unitSupportPhone}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 900
                          ? 4
                          : width >= 620
                          ? 3
                          : 2;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns >= 3 ? 1.5 : 1.4,
                        children: [
                          if (auth.isMember)
                            _buildModernActionCard(
                              context,
                              title: "Patients",
                              icon: Icons.people_alt_rounded,
                              palette: ModulePalettes.patients,
                              page: const ModuleTheme(
                                palette: ModulePalettes.patients,
                                child: PatientListPage(),
                              ),
                            ),
                          if (auth.canAccessNHC)
                            _buildModernActionCard(
                              context,
                              title: "Visit Assessment\n(NHC)",
                              icon: Icons.assignment_rounded,
                              palette: ModulePalettes.patients,
                              page: const VisitAssessmentVisitPickerScreen(),
                            ),
                          _buildModernActionCard(
                            context,
                            title: "Home Visits",
                            icon: Icons.home_rounded,
                            palette: ModulePalettes.homeVisits,
                            page: const ModuleTheme(
                              palette: ModulePalettes.homeVisits,
                              child: HomeVisitListPage(),
                            ),
                          ),
                          if (auth.isMember)
                            _buildModernActionCard(
                              context,
                              title: "Social Support",
                              icon: Icons.volunteer_activism_rounded,
                              palette: ModulePalettes.socialSupport,
                              page: const ModuleTheme(
                                palette: ModulePalettes.socialSupport,
                                child: SocialSupportListPage(),
                              ),
                            ),
                          if (auth.isMember)
                            _buildModernActionCard(
                              context,
                              title: "Volunteers",
                              icon: Icons.badge_rounded,
                              palette: ModulePalettes.volunteers,
                              page: const ModuleTheme(
                                palette: ModulePalettes.volunteers,
                                child: VolunteerListPage(),
                              ),
                            ),
                          _buildModernActionCard(
                            context,
                            title: "Equipment Supply",
                            icon: Icons.inventory_2_rounded,
                            palette: ModulePalettes.equipmentSupply,
                            page: const ModuleTheme(
                              palette: ModulePalettes.equipmentSupply,
                              child: EquipmentSupplyListPage(),
                            ),
                          ),
                          if (auth.canAccessMedicine)
                            _buildModernActionCard(
                              context,
                              title: "Medicine Supply",
                              icon: Icons.medication_liquid_rounded,
                              palette: ModulePalettes.medicineSupply,
                              page: const ModuleTheme(
                                palette: ModulePalettes.medicineSupply,
                                child: MedicineSupplyListPage(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Active Supplies Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Active Supplies",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ModuleTheme(
                                palette: ModulePalettes.equipmentSupply,
                                child: EquipmentSupplyListPage(),
                              ),
                            ),
                          );
                        },
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildActiveSuppliesList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ModulePalette palette,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
          if (title == "Equipment Supply") {
            _loadActiveSupplies();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: palette.primary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.primary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSuppliesList(BuildContext context) {
    if (_activeSuppliesLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeSupplies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "No active supplies",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _activeSupplyCardWidth(constraints.maxWidth);
        final visibleCount = _activeSuppliesVisibleCount(constraints.maxWidth);
        final indicatorCount = (_activeSupplies.length - visibleCount + 1)
            .clamp(1, _activeSupplies.length)
            .toInt();

        return Column(
          children: [
            SizedBox(
              height: 130,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis != Axis.horizontal) {
                    return false;
                  }
                  final next = (notification.metrics.pixels / (cardWidth + 12))
                      .round()
                      .clamp(0, indicatorCount - 1)
                      .toInt();
                  if (next != _activeSuppliesPageIndex) {
                    setState(() => _activeSuppliesPageIndex = next);
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _activeSuppliesScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _activeSupplies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _activeSupplies.length - 1 ? 0 : 12,
                      ),
                      child: SizedBox(
                        width: cardWidth,
                        child: _activeSupplyCard(_activeSupplies[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (indicatorCount > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  indicatorCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _activeSuppliesPageIndex == index ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _activeSuppliesPageIndex == index
                          ? const Color(0xFF1A237E)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _activeSupplyCardWidth(double availableWidth) {
    if (availableWidth >= 680) {
      return (availableWidth - 12) / 2;
    }
    return availableWidth * 0.78;
  }

  int _activeSuppliesVisibleCount(double availableWidth) {
    return availableWidth >= 680 ? 2 : 1;
  }

  Widget _activeSupplyCard(EquipmentSupply supply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFFFAC775)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAC775),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Color(0xFF854F0B),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            supply.equipmentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _supplyRecipientName(supply),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatSupplyDate(supply.supplyDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSupplyDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  Color _notificationColor(AppNotification notification) {
    switch (notification.severity) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return const Color(0xFF1A237E);
    }
  }

  IconData _notificationIcon(AppNotification notification) {
    switch (notification.type) {
      case 'equipment_overdue':
        return Icons.inventory_2_outlined;
      case 'medicine_expiry_60':
      case 'medicine_expiry_30':
        return Icons.medication_outlined;
      case 'subscription_renewal':
        return Icons.event_repeat_outlined;
      case 'subscription_paid':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatNotificationTime(DateTime? date) {
    if (date == null) return 'Just now';

    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('d MMM yyyy').format(date);
  }

  String _supplyRecipientName(EquipmentSupply supply) {
    return _firstNonEmpty([
          supply.patientName,
          supply.receiverName,
          supply.careOf,
        ]) ??
        'Unknown';
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalDrawer(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final userName = (user?['name']?.toString().trim().isNotEmpty ?? false)
        ? user!['name'].toString()
        : auth.unitName;
    final userDetail = (user?['email']?.toString().trim().isNotEmpty ?? false)
        ? user!['email'].toString()
        : 'Healthcare Management';
    final drawerWidth = MediaQuery.sizeOf(context).width > 520
        ? 360.0
        : MediaQuery.sizeOf(context).width * 0.88;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 14, 20),
              child: Row(
                children: [
                  UnitBrandAvatar(
                    size: 58,
                    preferAppIcon: true,
                    border: Border.all(color: const Color(0xFFB5D4F4)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style: TextStyle(
                            color: Color(0xFF1D1D24),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF696974),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          userDetail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_outlined,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_outline_rounded,
                    title: "Patients",
                    color: ModulePalettes.patients.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.patients,
                            child: PatientListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_off_outlined,
                    title: "Passed Away Patients",
                    color: ModulePalettes.patients.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.patients,
                            child: DeceasedPatientListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_work_outlined,
                    title: "Home Visits",
                    color: ModulePalettes.homeVisits.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.homeVisits,
                            child: HomeVisitListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.volunteer_activism_outlined,
                    title: "Social Support",
                    color: ModulePalettes.socialSupport.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.socialSupport,
                            child: SocialSupportListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.badge_outlined,
                    title: "Volunteers",
                    color: ModulePalettes.volunteers.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.volunteers,
                            child: VolunteerListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 7),
                    child: Text(
                      'INVENTORY',
                      style: TextStyle(
                        color: Color(0xFF9A9AA5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: "Equipment Inventory",
                    color: ModulePalettes.equipmentSupply.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.equipmentSupply,
                            child: EquipmentListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.local_shipping_outlined,
                    title: "Distributed",
                    color: ModulePalettes.equipmentSupply.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.equipmentSupply,
                            child: EquipmentListPage(initialTab: 1),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.medical_services_outlined,
                    title: "Supply Record",
                    color: ModulePalettes.equipmentSupply.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.equipmentSupply,
                            child: EquipmentSupplyListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  if (auth.canAccessMedicine)
                    _buildDrawerItem(
                      context,
                      icon: Icons.medication_liquid_outlined,
                      title: "Medicine",
                      color: ModulePalettes.medicineSupply.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModuleTheme(
                              palette: ModulePalettes.medicineSupply,
                              child: MedicineListPage(),
                            ),
                          ),
                        );
                      },
                    ),
                  if (auth.canAccessMedicine)
                    _buildDrawerItem(
                      context,
                      icon: Icons.vaccines_outlined,
                      title: "Medicine Supply",
                      color: ModulePalettes.medicineSupply.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModuleTheme(
                              palette: ModulePalettes.medicineSupply,
                              child: MedicineSupplyListPage(),
                            ),
                          ),
                        );
                      },
                    ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.precision_manufacturing_outlined,
                    title: "Equipments",
                    color: ModulePalettes.equipmentSupply.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleTheme(
                            palette: ModulePalettes.equipmentSupply,
                            child: EquipmentSupplyListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  if (auth.canAccessNHC)
                    _buildDrawerItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: "Visit entry (NHC)",
                      color: ModulePalettes.homeVisits.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const VisitAssessmentVisitPickerScreen(),
                          ),
                        );
                      },
                    ),
                  if (auth.isAdmin) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, 7),
                      child: Text(
                        'SYSTEM',
                        style: TextStyle(
                          color: Color(0xFF9A9AA5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: "System Config",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConfigPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    color: const Color(0xFFC23B3B),
                    onTap: () {
                      auth.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const Loginscreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final Uri url = Uri.parse('https://ameen.osperb.com');
                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch website'),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      "All rights reserved by AFO",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? color,
  }) {
    final itemColor = color ?? const Color(0xFF20212A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFF0F1F4) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          minLeadingWidth: 28,
          leading: Icon(
            icon,
            color: isSelected ? const Color(0xFF20212A) : itemColor,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF20212A),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          onTap: onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
        ),
      ),
    );
  }
}

class _QrImageFallback extends StatelessWidget {
  const _QrImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF5F7FB),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, size: 64, color: Color(0xFF1A237E)),
          SizedBox(height: 12),
          Text(
            'QR image unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }
}
