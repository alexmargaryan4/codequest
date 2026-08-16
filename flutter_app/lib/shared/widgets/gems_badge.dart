import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Compact gem-balance indicator, styled to match [StreakBadge] /
/// [HeartsBadge]. Tapping is handled by the caller (typically opens the
/// shop) via [onTap].
class GemsBadge extends StatelessWidget {
  const GemsBadge({required this.balance, super.key, this.onTap, this.animate = false});

  final int balance;
  final VoidCallback? onTap;
  final bool animate;

  static const Color gemColor = Color(0xFF34D8C7);

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
          const Icon(Icons.diamond_rounded, size: 16, color: gemColor),
          const SizedBox(width: 4),
          Text('$balance', style: text.labelLarge),
        ],
      ),
    );

    final Widget tappable = onTap != null
        ? InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: content,
          )
        : content;

    if (!animate) return tappable;
    return tappable
        .animate()
        .scale(duration: 300.ms, curve: Curves.elasticOut, begin: const Offset(0.8, 0.8));
  }
}
