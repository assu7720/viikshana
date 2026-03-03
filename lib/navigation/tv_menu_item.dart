import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viikshana/shared/tokens/viikshana_colors.dart';

/// A TV sidebar menu item that is focusable via D-pad and shows a visible focus highlight.
class TvMenuItem extends StatefulWidget {
  const TvMenuItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<TvMenuItem> createState() => _TvMenuItemState();
}

class _TvMenuItemState extends State<TvMenuItem> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hasFocus
                  ? ViikshanaColors.brandOrange.withValues(alpha: 0.2)
                  : (widget.selected
                      ? ViikshanaColors.surfaceDark
                      : Colors.transparent),
              border: Border(
                left: BorderSide(
                  color: hasFocus || widget.selected
                      ? ViikshanaColors.brandOrange
                      : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                focusColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 28,
                        color: hasFocus || widget.selected
                            ? ViikshanaColors.brandOrange
                            : ViikshanaColors.onSurfaceDark,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                widget.selected ? FontWeight.w600 : FontWeight.w500,
                            color: hasFocus || widget.selected
                                ? ViikshanaColors.brandOrange
                                : ViikshanaColors.onSurfaceDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
