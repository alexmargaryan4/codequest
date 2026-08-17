import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/chest_provider.dart';
import '../../../core/providers/duel_provider.dart';
import '../../../core/providers/gems_provider.dart';
import '../../../core/providers/hearts_provider.dart';
import '../../../core/providers/pet_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/providers/quest_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/course.dart';
import '../../../models/daily_challenge.dart';
import '../../../models/daily_chest.dart';
import '../../../models/duel.dart';
import '../../../models/gems_wallet.dart';
import '../../../models/hearts_state.dart';
import '../../../models/pet_companion.dart';
import '../../../models/user_progress.dart';
import '../../../models/weekly_quest.dart';
import '../../../shared/widgets/gems_badge.dart';
import '../../../shared/widgets/hearts_badge.dart';
import '../../../shared/widgets/stat_chip.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../shared/widgets/topic_node_widget.dart';
import '../../../shared/widgets/xp_progress_bar.dart';
import '../../daily_challenge/application/daily_challenge_providers.dart';
import '../application/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProgress> progressAsync = ref.watch(userProgressProvider);
    final AsyncValue<Course?> courseAsync = ref.watch(activeCourseProvider);
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (UserProgress progress) {
            final (int currentXp, int neededXp) = progress.levelProgress;

            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('CodeQuest', style: text.headlineMedium),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Consumer(
                              builder: (BuildContext context, WidgetRef ref, _) {
                                final AsyncValue<HeartsState> heartsAsync =
                                    ref.watch(heartsProvider);
                                return heartsAsync.maybeWhen(
                                  data: (HeartsState hearts) => HeartsBadge(
                                    hearts: hearts,
                                    onTap: () => context.push(AppRoutes.shop),
                                  ),
                                  orElse: () => const SizedBox.shrink(),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Consumer(
                              builder: (BuildContext context, WidgetRef ref, _) {
                                final AsyncValue<GemsWallet> gemsAsync = ref.watch(gemsProvider);
                                return gemsAsync.maybeWhen(
                                  data: (GemsWallet wallet) => GemsBadge(
                                    balance: wallet.balance,
                                    onTap: () => context.push(AppRoutes.shop),
                                  ),
                                  orElse: () => const SizedBox.shrink(),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            StreakBadge(days: progress.currentStreak),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: XpProgressBar(
                      level: progress.level,
                      currentXp: currentXp,
                      neededXp: neededXp,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          StatChip(
                            icon: Icons.bolt_rounded,
                            value: '${progress.totalXp}',
                            label: 'Всего XP',
                            color: AppColors.accentIndigo,
                          ),
                          const SizedBox(width: 10),
                          StatChip(
                            icon: Icons.menu_book_rounded,
                            value: '${progress.lessonsCompleted}',
                            label: 'Уроков',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          StatChip(
                            icon: Icons.rocket_launch_rounded,
                            value: '${progress.projectsCompleted}',
                            label: 'Проектов',
                            color: AppColors.streakAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) {
                        final AsyncValue<DailyChallenge> challengeAsync =
                            ref.watch(dailyChallengeProvider);
                        return challengeAsync.maybeWhen(
                          data: (DailyChallenge c) => _DailyChallengeCard(challenge: c),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Consumer(
                            builder: (BuildContext context, WidgetRef ref, _) {
                              final AsyncValue<DailyChestState> chestAsync =
                                  ref.watch(chestProvider);
                              return chestAsync.maybeWhen(
                                data: (DailyChestState chest) => _ChestMiniCard(chest: chest),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Consumer(
                            builder: (BuildContext context, WidgetRef ref, _) {
                              final AsyncValue<PetCompanion> petAsync = ref.watch(petProvider);
                              return petAsync.maybeWhen(
                                data: (PetCompanion pet) => _PetMiniCard(pet: pet),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) {
                        final AsyncValue<Duel> duelAsync = ref.watch(duelProvider);
                        return duelAsync.maybeWhen(
                          data: (Duel duel) => _DuelMiniCard(duel: duel),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) {
                        final AsyncValue<List<WeeklyQuest>> questsAsync =
                            ref.watch(weeklyQuestsProvider);
                        return questsAsync.maybeWhen(
                          data: (List<WeeklyQuest> quests) =>
                              _WeeklyQuestsCard(quests: quests),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text('Продолжить обучение', style: text.titleLarge),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: courseAsync.when(
                      loading: () => const _MapPreviewSkeleton(),
                      error: (Object e, StackTrace st) => const Text('Не удалось загрузить курс'),
                      data: (Course? course) {
                        if (course == null) {
                          return _EmptyStateCard(semantic: semantic, text: text);
                        }
                        return _ContinueCard(course: course, progress: progress);
                      },
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course, required this.progress});

  final Course course;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final Color accent = AppColors.fromHex(course.colorSeed);

    final List<TopicNode> preview = course.topics.take(5).toList();
    final TopicNode? current = preview.cast<TopicNode?>().firstWhere(
          (TopicNode? t) =>
              t!.status == TopicNodeStatus.available || t.status == TopicNodeStatus.inProgress,
          orElse: () => null,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.code_rounded, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(course.title, style: text.titleMedium),
                      if (current != null)
                        Text(
                          current.title,
                          style: text.bodySmall?.copyWith(color: semantic.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (BuildContext context, int i) {
                  return TopicNodeWidget(
                    topic: preview[i],
                    accentColor: accent,
                    size: 52,
                    onTap: () => context.push(AppRoutes.courseMapPath(course.id)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.courseMapPath(course.id)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.semantic, required this.text});

  final AppSemanticColors semantic;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.explore_rounded, size: 40, color: semantic.textMuted),
            const SizedBox(height: 12),
            Text('Выбери курс, чтобы начать обучение', style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.learn),
              child: const Text('Перейти к курсам'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.dailyChallenge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: challenge.completed
                ? <Color>[AppColors.success.withValues(alpha: 0.14), AppColors.success.withValues(alpha: 0.06)]
                : <Color>[AppColors.streakAmber.withValues(alpha: 0.16), AppColors.streakAmber.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: (challenge.completed ? AppColors.success : AppColors.streakAmber).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              challenge.completed ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
              color: challenge.completed ? AppColors.success : AppColors.streakAmber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Дневной челлендж', style: text.titleSmall),
                  Text(
                    challenge.completed ? 'Пройден сегодня' : 'Сегодня: ${challenge.topicLabel} · +${challenge.xpReward} XP',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            if (!challenge.completed) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}

class _WeeklyQuestsCard extends StatelessWidget {
  const _WeeklyQuestsCard({required this.quests});
  final List<WeeklyQuest> quests;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) return const SizedBox.shrink();

    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final int completedCount = quests.where((WeeklyQuest q) => q.completed).length;
    final bool hasUnclaimed = quests.any((WeeklyQuest q) => q.completed && !q.isClaimed);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.weeklyQuests),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasUnclaimed ? AppColors.accentIndigo.withValues(alpha: 0.4) : semantic.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.accentIndigo, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Квесты недели', style: text.titleSmall),
                  Text(
                    hasUnclaimed
                        ? 'Есть награда за получением!'
                        : '$completedCount из ${quests.length} выполнено',
                    style: text.bodySmall?.copyWith(color: semantic.textMuted),
                  ),
                ],
              ),
            ),
            if (hasUnclaimed)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accentIndigo,
                  shape: BoxShape.circle,
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.05, end: 0);
  }
}

class _ChestMiniCard extends StatelessWidget {
  const _ChestMiniCard({required this.chest});
  final DailyChestState chest;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool available = chest.isAvailableToday;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.dailyChest),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: available
                ? <Color>[
                    AppColors.streakAmber.withValues(alpha: 0.18),
                    AppColors.streakAmber.withValues(alpha: 0.06),
                  ]
                : <Color>[
                    AppColors.streakAmber.withValues(alpha: 0.08),
                    AppColors.streakAmber.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.streakAmber.withValues(alpha: available ? 0.35 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              available ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
              color: AppColors.streakAmber,
            ),
            const SizedBox(height: 8),
            Text('Сундук', style: text.titleSmall),
            Text(
              available ? 'Открой награду' : 'Открыт сегодня',
              style: text.labelSmall?.copyWith(color: AppColors.streakAmber),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0);
  }
}

class _PetMiniCard extends StatelessWidget {
  const _PetMiniCard({required this.pet});
  final PetCompanion pet;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.pet),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: semantic.border),
        ),
        child: Row(
          children: <Widget>[
            Text(pet.species.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pet.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    pet.stageLabel,
                    style: text.labelSmall?.copyWith(color: semantic.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

class _DuelMiniCard extends StatelessWidget {
  const _DuelMiniCard({required this.duel});
  final Duel duel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final bool wonUnclaimed = duel.won == true && !duel.isClaimed;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.duel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: wonUnclaimed ? AppColors.success.withValues(alpha: 0.5) : semantic.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.sports_kabaddi_rounded, color: AppColors.accentIndigo, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Дуэль против ${duel.opponentName}', style: text.titleSmall),
                  Text(
                    wonUnclaimed
                        ? 'Победа! Забери награду'
                        : '${duel.playerScore} / ${duel.targetScore} очков',
                    style: text.bodySmall?.copyWith(
                      color: wonUnclaimed ? AppColors.success : semantic.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (wonUnclaimed)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 175.ms).slideY(begin: 0.05, end: 0);
  }
}

class _MapPreviewSkeleton extends StatelessWidget {
  const _MapPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
