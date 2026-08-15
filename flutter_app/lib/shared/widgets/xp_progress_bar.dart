import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Level + XP progress bar, e.g. "Level 12 — 1,240 / 1,500 XP", with a
/// smoothly animated fill whenever [currentXp]/[neededXp] change.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    required this.level,
    required this.currentXp,
    required this.neededXp,
    super.key,
    this.compact = false,
  });

  final int level;
  final int currentXp;
  final int neededXp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final double progress = neededXp == 0 ? 0 : (currentXp / neededXp).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Level $level', style: text.labelLarge),
            Text(
              '$currentXp / $neededXp XP',
              style: text.labelMedium?.copyWith(color: semantic.textMuted),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: compact ? 8 : 10,
            color: semantic.surfaceRaised,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.accentIndigoMuted,
                          AppColors.accentIndigo,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
