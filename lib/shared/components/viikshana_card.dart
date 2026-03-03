import 'package:flutter/material.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

/// Surface card using theme surface color and spacing.
class ViikshanaCard extends StatelessWidget {
  const ViikshanaCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(ViikshanaSpacing.md),
      child: child,
    );
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
