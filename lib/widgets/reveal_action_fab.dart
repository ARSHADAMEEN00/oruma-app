import 'package:flutter/material.dart';

class RevealActionFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const RevealActionFab({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  State<RevealActionFab> createState() => _RevealActionFabState();
}

class _RevealActionFabState extends State<RevealActionFab> {
  static const _collapsedSize = 56.0;
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant RevealActionFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label || oldWidget.icon != widget.icon) {
      _expanded = false;
    }
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (!_expanded) {
      setState(() => _expanded = true);
      return;
    }

    setState(() => _expanded = false);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fabTheme = theme.floatingActionButtonTheme;
    final backgroundColor =
        widget.backgroundColor ??
        fabTheme.backgroundColor ??
        theme.colorScheme.primary;
    final foregroundColor =
        widget.foregroundColor ??
        fabTheme.foregroundColor ??
        theme.colorScheme.onPrimary;
    final enabled = widget.onPressed != null;
    final width = _expanded ? _expandedWidth(context) : _collapsedSize;

    return Tooltip(
      message: widget.tooltip ?? widget.label,
      child: Material(
        color: enabled ? backgroundColor : theme.disabledColor,
        elevation: enabled ? 6 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? _handleTap : null,
          child: AnimatedContainer(
            width: width,
            height: _collapsedSize,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: _expanded ? 18 : 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    axis: Axis.horizontal,
                    axisAlignment: -1,
                    sizeFactor: animation,
                    child: child,
                  ),
                );
              },
              child: _expanded
                  ? SizedBox(
                      key: const ValueKey('expanded'),
                      height: _collapsedSize,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, color: foregroundColor, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 16,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      key: const ValueKey('collapsed'),
                      child: Icon(Icons.add, color: foregroundColor, size: 28),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  double _expandedWidth(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final labelWidth = widget.label.length * 8.8 * textScale;
    return (92 + labelWidth).clamp(144.0, 236.0).toDouble();
  }
}
