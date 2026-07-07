import 'package:flutter/material.dart';
import 'package:oruma_app/services/auth_service.dart';
import 'package:provider/provider.dart';

enum AppBottomSection { home, medicine, patients, homeVisit, nhc }

class AppBottomNavItem {
  const AppBottomNavItem(this.section, this.icon, this.label);

  final AppBottomSection section;
  final IconData icon;
  final String label;
}

class CompactAppBottomBar extends StatelessWidget {
  const CompactAppBottomBar({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final AppBottomSection current;
  final ValueChanged<AppBottomSection> onSelected;

  static const items = <AppBottomNavItem>[
    AppBottomNavItem(AppBottomSection.home, Icons.home_outlined, 'Home'),
    AppBottomNavItem(
      AppBottomSection.medicine,
      Icons.medication_outlined,
      'Medicine',
    ),
    AppBottomNavItem(
      AppBottomSection.patients,
      Icons.people_outline,
      'Patients',
    ),
    AppBottomNavItem(
      AppBottomSection.homeVisit,
      Icons.home_work_outlined,
      'Home Visit',
    ),
    AppBottomNavItem(
      AppBottomSection.nhc,
      Icons.assignment_outlined,
      'Visit (NHC)',
    ),
  ];

  static List<AppBottomNavItem> visibleItems(AuthService auth) {
    return items.where((item) {
      if (item.section == AppBottomSection.medicine &&
          !auth.canAccessMedicine) {
        return false;
      }
      if (item.section == AppBottomSection.nhc && !auth.canAccessNHC) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<AppBottomNavItem> visibleItemsFor(AuthService? auth) {
    return auth == null ? items : visibleItems(auth);
  }

  static AuthService? maybeAuth(BuildContext context) {
    try {
      return context.watch<AuthService>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = visibleItemsFor(maybeAuth(context));

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECEF))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: SizedBox(
          height: 54,
          child: Row(
            children: items.map((item) {
              final selected = current == item.section;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.label,
                  child: InkWell(
                    onTap: () => onSelected(item.section),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 34,
                            height: 27,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE7F5EF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 19,
                              color: selected
                                  ? const Color(0xFF0F7A55)
                                  : const Color(0xFF687582),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF0F7A55)
                                  : const Color(0xFF687582),
                              fontSize: 8.5,
                              height: 1.1,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
