import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Compact streak indicator (e.g. "🔥 7"). Deliberately small — per the
/// product spec, streak should be visible but must not dominate the
/// interface.
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.days, super.key, this.animate = false});

  final int days;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    final Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.local_fire_department_rounded, size: 16, color: semantic.streak),
          const SizedBox(width: 4),
          Text('$days', style: text.labelLarge?.copyWith(color: semantic.streak)),
        ],
      ),
    );

    if (!animate) return content;
    return content
        .animate()
        .scale(duration: 300.ms, curve: Curves.elasticOut, begin: const Offset(0.8, 0.8))
        .then()
        .shake(duration: 400.ms, hz: 3);
  }
}
