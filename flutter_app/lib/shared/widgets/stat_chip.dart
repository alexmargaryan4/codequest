import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small labeled stat pill used across Home/Profile (e.g. XP total,
/// lessons completed, projects completed).
class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final Color accent = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(value, style: text.titleMedium),
              Text(label, style: text.labelSmall?.copyWith(color: semantic.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
