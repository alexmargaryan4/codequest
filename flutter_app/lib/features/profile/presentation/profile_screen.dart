import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rewards_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/cosmetics_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/achievement.dart';
import '../../../models/cosmetics_state.dart';
import '../../../models/course.dart';
import '../../../models/user_progress.dart';
import '../../../shared/widgets/stat_chip.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../shared/widgets/xp_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProgress> progressAsync = ref.watch(userProgressProvider);
    final AsyncValue<String> usernameAsync = ref.watch(usernameProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (UserProgress progress) {
            final String username = usernameAsync.valueOrNull ?? 'Student';
            final (int currentXp, int neededXp) = progress.levelProgress;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: <Widget>[
                _ProfileHeader(username: username, progress: progress),
                const SizedBox(height: 20),
                const _ExtrasRow(),
                const SizedBox(height: 20),
                XpProgressBar(level: progress.level, currentXp: currentXp, neededXp: neededXp),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatChip(
                        icon: Icons.menu_book_rounded,
                        value: '${progress.lessonsCompleted}',
                        label: 'Уроков',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatChip(
                        icon: Icons.rocket_launch_rounded,
                        value: '${progress.projectsCompleted}',
                        label: 'Проектов',
                        color: AppColors.streakAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatChip(
                        icon: Icons.local_fire_department_rounded,
                        value: '${progress.longestStreak}',
                        label: 'Рекорд',
                        color: AppColors.accentIndigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Курсы', style: text.titleLarge),
                const SizedBox(height: 12),
                _CoursesSummary(progress: progress),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Достижения', style: text.titleLarge),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.achievements),
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _AchievementsPreview(progress: progress),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _SettingsSheet(),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.username, required this.progress});
  final String username;
  final UserProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final CosmeticsState? cosmetics = ref.watch(cosmeticsProvider).valueOrNull;
    final CosmeticItem? equippedFrame = cosmetics?.equippedAvatarFrameId != null
        ? CosmeticsCatalog.byId(cosmetics!.equippedAvatarFrameId!)
        : null;
    final Color? frameColor =
        equippedFrame != null ? AppColors.fromHex(equippedFrame.colorHex) : null;

    return Row(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          padding: frameColor != null ? const EdgeInsets.all(3) : EdgeInsets.zero,
          decoration: frameColor != null
              ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: frameColor, width: 3))
              : null,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[AppColors.accentIndigoMuted, AppColors.accentIndigo],
              ),
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: text.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(username, style: text.headlineSmall),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text('Level ${progress.level}', style: text.bodyMedium?.copyWith(color: semantic.textMuted)),
                  const SizedBox(width: 10),
                  StreakBadge(days: progress.currentStreak),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExtrasRow extends StatelessWidget {
  const _ExtrasRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ExtraTile(
            icon: Icons.diamond_rounded,
            label: 'Скины',
            color: AppColors.accentIndigo,
            onTap: () => context.push(AppRoutes.cosmetics),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ExtraTile(
            icon: Icons.pets_rounded,
            label: 'Питомец',
            color: AppColors.success,
            onTap: () => context.push(AppRoutes.pet),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ExtraTile(
            icon: Icons.insights_rounded,
            label: 'Отчёт',
            color: AppColors.streakAmber,
            onTap: () => context.push(AppRoutes.weeklyReport),
          ),
        ),
      ],
    );
  }
}

class _ExtraTile extends StatelessWidget {
  const _ExtraTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: semantic.border),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _CoursesSummary extends ConsumerWidget {
  const _CoursesSummary({required this.progress});
  final UserProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return FutureBuilder<List<Course>>(
      future: ref.read(courseRepositoryProvider).getCoursesForTrack(LearningTrack.programming),
      builder: (BuildContext context, AsyncSnapshot<List<Course>> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()));
        }
        final List<Course> courses = snapshot.data!.where((Course c) => c.isAvailable).toList();

        return Column(
          children: courses.map((Course course) {
            final Color accent = AppColors.fromHex(course.colorSeed);
            final bool isActive = course.id == progress.activeCourseId;
            final int completedTopics =
                course.topics.where((TopicNode t) => progress.completedTopicIds.contains(t.id)).length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isActive ? accent.withValues(alpha: 0.5) : semantic.border,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.terminal_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(course.title, style: text.titleSmall),
                        Text(
                          '$completedTopics / ${course.topics.length} тем пройдено',
                          style: text.labelSmall?.copyWith(color: semantic.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('Активный', style: text.labelSmall?.copyWith(color: accent)),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AchievementsPreview extends ConsumerWidget {
  const _AchievementsPreview({required this.progress});
  final UserProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return FutureBuilder<List<Achievement>>(
      future: ref.read(achievementRepositoryProvider).loadAll(),
      builder: (BuildContext context, AsyncSnapshot<List<Achievement>> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
        }
        final List<Achievement> unlocked = snapshot.data!
            .where((Achievement a) => progress.unlockedAchievementIds.contains(a.id))
            .toList();

        if (unlocked.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: semantic.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: semantic.border),
            ),
            child: Text(
              'Пройди первый урок, чтобы открыть достижения',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
            ),
          );
        }

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: unlocked.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int i) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                ),
                child: Text(unlocked[i].title, style: Theme.of(context).textTheme.labelMedium),
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    SettingsStore.instance.username.then((String value) {
      if (mounted) _usernameController.text = value;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Настройки', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Имя пользователя'),
            onSubmitted: (String value) => SettingsStore.instance.setUsername(value),
          ),
          const SizedBox(height: 20),
          Text('Тема', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('Система')),
              ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Светлая')),
              ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Тёмная')),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await SettingsStore.instance.setUsername(_usernameController.text.trim());
                ref.invalidate(usernameProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}
