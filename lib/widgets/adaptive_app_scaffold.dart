import 'package:flutter/material.dart';
import 'package:oruma_app/widgets/compact_app_bottom_bar.dart';

class AdaptiveAppScaffold extends StatelessWidget {
  const AdaptiveAppScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.drawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.currentSection,
    this.onNavigationSelected,
    this.centerBodyOnTablet = true,
    this.contentMaxWidth = 860,
    this.tabletBreakpoint = 600,
    this.extendBody = false,
    this.resizeToAvoidBottomInset,
  });

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final AppBottomSection? currentSection;
  final ValueChanged<AppBottomSection>? onNavigationSelected;
  final bool centerBodyOnTablet;
  final double contentMaxWidth;
  final double tabletBreakpoint;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= tabletBreakpoint;
        final usesRail = isTablet && currentSection != null;
        final customBottomBar = bottomNavigationBar == null
            ? null
            : _TabletWidthFrame(
                enabled: isTablet && centerBodyOnTablet,
                maxWidth: contentMaxWidth,
                child: bottomNavigationBar!,
              );
        final customBottomSheet = bottomSheet == null
            ? null
            : _TabletWidthFrame(
                enabled: isTablet && centerBodyOnTablet,
                maxWidth: contentMaxWidth,
                child: bottomSheet!,
              );

        return Scaffold(
          key: scaffoldKey,
          appBar: appBar,
          drawer: drawer,
          backgroundColor: backgroundColor,
          bottomSheet: customBottomSheet,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          extendBody: extendBody,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          bottomNavigationBar: usesRail
              ? null
              : currentSection == null
              ? customBottomBar
              : CompactAppBottomBar(
                  current: currentSection!,
                  onSelected: onNavigationSelected ?? (_) {},
                ),
          body: usesRail
              ? Row(
                  children: [
                    _TabletNavigationRail(
                      current: currentSection!,
                      extended: constraints.maxWidth >= 1100,
                      onSelected: onNavigationSelected ?? (_) {},
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _TabletBodyFrame(
                        enabled: centerBodyOnTablet,
                        maxWidth: contentMaxWidth,
                        child: body,
                      ),
                    ),
                  ],
                )
              : _TabletBodyFrame(
                  enabled: isTablet && centerBodyOnTablet,
                  maxWidth: contentMaxWidth,
                  child: body,
                ),
        );
      },
    );
  }
}

class _TabletBodyFrame extends StatelessWidget {
  const _TabletBodyFrame({
    required this.enabled,
    required this.maxWidth,
    required this.child,
  });

  final bool enabled;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        final framedChild = constraints.hasBoundedHeight
            ? SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: child,
              )
            : SizedBox(width: width, child: child);

        return Align(alignment: Alignment.topCenter, child: framedChild);
      },
    );
  }
}

class _TabletWidthFrame extends StatelessWidget {
  const _TabletWidthFrame({
    required this.enabled,
    required this.maxWidth,
    required this.child,
  });

  final bool enabled;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

class _TabletNavigationRail extends StatelessWidget {
  const _TabletNavigationRail({
    required this.current,
    required this.extended,
    required this.onSelected,
  });

  final AppBottomSection current;
  final bool extended;
  final ValueChanged<AppBottomSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = CompactAppBottomBar.visibleItemsFor(
      CompactAppBottomBar.maybeAuth(context),
    );

    return Material(
      color: Colors.white,
      child: SizedBox(
        width: extended ? 188 : 94,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: _RailBrand(extended: extended),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: extended ? 12 : 0,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final item in items) ...[
                        _RailDestinationItem(
                          item: item,
                          selected: item.section == current,
                          extended: extended,
                          onTap: () {
                            if (item.section != current) {
                              onSelected(item.section);
                            }
                          },
                        ),
                        if (item != items.last) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailDestinationItem extends StatelessWidget {
  const _RailDestinationItem({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = const Color(0xFF4D544B);
    final selectedBackground = selectedColor.withValues(alpha: 0.16);
    final iconColor = selected ? selectedColor : inactiveColor;
    const compactIndicatorWidth = 56.0;
    const compactIndicatorHeight = 32.0;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: extended
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? selectedBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 25, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? selectedColor : inactiveColor,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(18),
                      hoverColor: selectedBackground,
                      highlightColor: selectedBackground,
                      splashColor: selectedColor.withValues(alpha: 0.12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: compactIndicatorWidth,
                        height: compactIndicatorHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? selectedBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(item.icon, size: 25, color: iconColor),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: selected
                          ? Padding(
                              key: ValueKey(item.section),
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedColor,
                                  fontSize: 12,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty'), height: 0),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final logo = ClipOval(
      child: Image.asset(
        'assets/logo/logo.png',
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.local_hospital_outlined,
          color: Color(0xFF185FA5),
          size: 28,
        ),
      ),
    );

    if (!extended) {
      return Padding(padding: const EdgeInsets.only(bottom: 18), child: logo);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 12, 22),
      child: SizedBox(
        width: 162,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            const SizedBox(width: 10),
            const Flexible(
              fit: FlexFit.loose,
              child: Text(
                'Team Oruma',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
