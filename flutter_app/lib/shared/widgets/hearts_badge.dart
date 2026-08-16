import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/game_economy_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/hearts_state.dart';

/// Compact hearts (lives) indicator — mirrors [StreakBadge]'s visual
/// weight so the two sit naturally side by side in the top bar. Tapping
/// it is handled by the caller (typically opens the shop) via [onTap].
class HeartsBadge extends StatelessWidget {
  const HeartsBadge({required this.hearts, super.key, this.onTap, this.animate = false});

  final HeartsState hearts;
  final VoidCallback? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final int liveHearts = hearts.currentHearts();
    final bool isLow = liveHearts <= 1;

    final Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: isLow ? AppColors.error.withValues(alpha: 0.4) : semantic.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.favorite_rounded,
            size: 16,
            color: isLow ? AppColors.error : AppColors.error.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 4),
          Text('$liveHearts', style: text.labelLarge),
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
        .scale(duration: 300.ms, curve: Curves.elasticOut, begin: const Offset(0.8, 0.8))
        .then()
        .shake(duration: 400.ms, hz: 3);
  }
}

/// Small helper row shown in the shop / lesson-blocked screens: hearts
/// count plus a live "next heart in mm:ss" countdown when not full.
class HeartsCountdownLabel extends StatelessWidget {
  const HeartsCountdownLabel({required this.hearts, super.key});
  final HeartsState hearts;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final Duration? remaining = hearts.timeUntilNextHeart();

    if (remaining == null) {
      return Text(
        hearts.currentHearts() >= HeartsConfig.maxHearts ? 'Жизни полные' : '',
        style: text.bodySmall?.copyWith(color: semantic.textMuted),
      );
    }

    final int minutes = remaining.inMinutes;
    final int seconds = remaining.inSeconds % 60;
    final String mmss = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Text(
      'Следующая жизнь через $mmss',
      style: text.bodySmall?.copyWith(color: semantic.textMuted),
    );
  }
}
