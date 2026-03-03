import 'package:flutter/material.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

/// Primary action button using theme colors and spacing.
class ViikshanaButton extends StatelessWidget {
  const ViikshanaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: ViikshanaSpacing.lg,
          vertical: ViikshanaSpacing.sm,
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: theme.textTheme.labelLarge?.fontSize ?? 14),
                const SizedBox(width: ViikshanaSpacing.sm),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}
