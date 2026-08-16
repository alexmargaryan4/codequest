import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/quest_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/weekly_quest.dart';

/// This week's 3 quests, with a progress bar each and a claim button
/// once a quest crosses its target. Quests reset automatically once the
/// ISO week rolls over (see [WeeklyQuestRepository.weekKeyFor]) — no
/// user action needed, the next visit after Monday just shows a fresh
/// set.
class WeeklyQuestsScreen extends ConsumerWidget {
  const WeeklyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WeeklyQuest>> questsAsync = ref.watch(weeklyQuestsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Квесты недели')),
      body: SafeArea(
        child: questsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (List<WeeklyQuest> quests) {
            if (quests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Квесты появятся с началом новой недели',
                    style: text.bodyMedium?.copyWith(color: semantic.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final int completedCount = quests.where((WeeklyQuest q) => q.completed).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: <Widget>[
                Text(
                  'Выполнено $completedCount из ${quests.length} · обновится в понедельник',
                  style: text.bodyMedium?.copyWith(color: semantic.textMuted),
                ),
                const SizedBox(height: 16),
                for (final WeeklyQuest quest in quests) ...<Widget>[
                  _QuestCard(quest: quest),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.quest});
  final WeeklyQuest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final Color accent = quest.isClaimed
        ? semantic.textMuted
        : (quest.completed ? AppColors.success : AppColors.accentIndigo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: quest.completed && !quest.isClaimed
              ? AppColors.success.withValues(alpha: 0.4)
              : semantic.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                quest.isClaimed
                    ? Icons.check_circle_rounded
                    : (quest.completed ? Icons.celebration_rounded : Icons.flag_rounded),
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(quest.title, style: text.titleSmall)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: quest.progressRatio,
              minHeight: 8,
              backgroundColor: semantic.border,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${quest.progress} / ${quest.target}',
                style: text.labelMedium?.copyWith(color: semantic.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (quest.gemsReward > 0) ...<Widget>[
                    const Icon(Icons.diamond_rounded, size: 14, color: GemsAccent.color),
                    const SizedBox(width: 2),
                    Text('+${quest.gemsReward}', style: text.labelMedium),
                  ],
                  if (quest.xpReward > 0) ...<Widget>[
                    const SizedBox(width: 8),
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentIndigo),
                    const SizedBox(width: 2),
                    Text('+${quest.xpReward}', style: text.labelMedium),
                  ],
                ],
              ),
            ],
          ),
          if (quest.completed && !quest.isClaimed) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ref.read(weeklyQuestsProvider.notifier).claimReward(quest),
                child: const Text('Забрать награду'),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03, end: 0);
  }
}

/// Small standalone color token so this file doesn't need to import the
/// full gems badge widget just for its icon color.
class GemsAccent {
  const GemsAccent._();
  static const Color color = Color(0xFF34D8C7);
}
