import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/achievement.dart';
import '../../../models/user_progress.dart';

/// Grid of all achievement definitions, unlocked ones shown in full
/// color with their unlock date implied by order, locked ones dimmed
/// with a lock glyph and their progress-to-unlock where it's meaningful
/// to show (e.g. "4/7 дней"). New achievements are a pure data addition
/// (assets/data/achievements/achievements.json) — this screen needs no
/// changes to support them, per the architecture note in
/// AchievementRepository.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProgress> progressAsync = ref.watch(userProgressProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (UserProgress progress) {
            return FutureBuilder<List<Achievement>>(
              future: ref.watch(achievementRepositoryProvider).loadAll(),
              builder: (BuildContext context, AsyncSnapshot<List<Achievement>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<Achievement> all = snapshot.data!;
                final int unlockedCount =
                    all.where((Achievement a) => progress.unlockedAchievementIds.contains(a.id)).length;

                return CustomScrollView(
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Открыто $unlockedCount из ${all.length}',
                          style: text.bodyMedium,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final Achievement a = all[index];
                            final bool unlocked = progress.unlockedAchievementIds.contains(a.id);
                            return _AchievementCard(achievement: a, unlocked: unlocked, progress: progress)
                                .animate()
                                .fadeIn(delay: (index * 40).ms)
                                .slideY(begin: 0.05, end: 0);
                          },
                          childCount: all.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  final Achievement achievement;
  final bool unlocked;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.accentIndigo.withValues(alpha: 0.08) : semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: unlocked ? AppColors.accentIndigo.withValues(alpha: 0.35) : semantic.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? AppColors.accentIndigo.withValues(alpha: 0.16) : semantic.border.withValues(alpha: 0.4),
            ),
            child: Icon(
              unlocked ? _iconFor(achievement.iconName) : Icons.lock_rounded,
              color: unlocked ? AppColors.accentIndigo : semantic.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: text.titleSmall?.copyWith(color: unlocked ? null : semantic.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              achievement.description,
              style: text.bodySmall?.copyWith(color: semantic.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!unlocked) _ProgressHint(achievement: achievement, progress: progress, semantic: semantic, text: text),
          if (unlocked)
            Row(
              children: <Widget>[
                const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentIndigo),
                const SizedBox(width: 2),
                Text('+${achievement.xpReward} XP', style: text.labelSmall?.copyWith(color: AppColors.accentIndigo)),
              ],
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

class _ProgressHint extends StatelessWidget {
  const _ProgressHint({
    required this.achievement,
    required this.progress,
    required this.semantic,
    required this.text,
  });

  final Achievement achievement;
  final UserProgress progress;
  final AppSemanticColors semantic;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final int? current = switch (achievement.trigger) {
      AchievementTrigger.streakDays => progress.currentStreak,
      AchievementTrigger.lessonsCompleted => progress.lessonsCompleted,
      AchievementTrigger.projectsCompleted => progress.projectsCompleted,
      AchievementTrigger.levelReached => progress.level,
      _ => null,
    };
    if (current == null) return const SizedBox.shrink();

    final double ratio = (current / achievement.threshold).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: semantic.border,
              color: semantic.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text('$current/${achievement.threshold}', style: text.labelSmall?.copyWith(color: semantic.textMuted)),
        ],
      ),
    );
  }
}
