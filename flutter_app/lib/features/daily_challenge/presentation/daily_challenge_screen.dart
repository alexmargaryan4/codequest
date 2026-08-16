import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/game_economy_constants.dart';
import '../../../core/providers/gems_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/providers/quest_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import '../../../models/daily_challenge.dart';
import '../../../models/exercise.dart';
import '../../../models/weekly_quest.dart';
import '../../../shared/widgets/level_up_overlay.dart';
import '../../exercises/presentation/exercise_widget_factory.dart';
import '../application/daily_challenge_providers.dart';

/// Today's single bite-sized challenge — one exercise, +50 XP, reusing
/// the same exercise widgets as full lessons so the interaction feels
/// familiar. AI-generated when possible, falling back to bundled content
/// when offline or when both AI providers are unavailable — never shows
/// a raw API error.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DailyChallenge> challengeAsync = ref.watch(dailyChallengeProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Дневной челлендж')),
      body: SafeArea(
        child: challengeAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Готовим сегодняшнее задание...', style: text.bodyMedium),
              ],
            ),
          ),
          error: (Object e, StackTrace st) => Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Челлендж временно недоступен', style: text.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуй ещё раз чуть позже.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (DailyChallenge challenge) => _ChallengeBody(challenge: challenge),
        ),
      ),
    );
  }
}

class _ChallengeBody extends ConsumerStatefulWidget {
  const _ChallengeBody({required this.challenge});
  final DailyChallenge challenge;

  @override
  ConsumerState<_ChallengeBody> createState() => _ChallengeBodyState();
}

class _ChallengeBodyState extends ConsumerState<_ChallengeBody> {
  Object? _selection;
  bool _answered = false;
  bool _wasCorrect = false;
  int? _pendingLevelUp;

  @override
  void didUpdateWidget(covariant _ChallengeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.dateKey != widget.challenge.dateKey) {
      _selection = null;
      _answered = false;
      _wasCorrect = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final Exercise exercise = widget.challenge.exercise;

    if (widget.challenge.completed) {
      return _AlreadyDone(challenge: widget.challenge);
    }

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: semantic.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: semantic.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.streakAmber),
                    const SizedBox(width: 6),
                    Text('Сегодня: ${widget.challenge.topicLabel}', style: text.labelLarge),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              ExerciseWidgetFactory.build(
                exercise: exercise,
                answered: _answered,
                selection: _selection,
                onSelectionChanged: (Object? v) => setState(() => _selection = v),
                onSubmit: () {
                  final bool correct = ExerciseWidgetFactory.isCorrect(exercise, _selection);
                  setState(() {
                    _answered = true;
                    _wasCorrect = correct;
                  });
                },
              ),
            ],
          ),
        ),
        if (_answered)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: double.infinity,
              child: _wasCorrect
                  ? ElevatedButton.icon(
                      onPressed: () => _claimReward(context),
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text('Забрать +${widget.challenge.xpReward} XP'),
                    )
                  : ElevatedButton.icon(
                      onPressed: _tryAgain,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Попробовать снова'),
                    ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ),
        if (_pendingLevelUp != null)
          LevelUpOverlay(
            newLevel: _pendingLevelUp!,
            onDismiss: () => setState(() => _pendingLevelUp = null),
          ),
      ],
    );
  }

  /// Lets the user retry after an incorrect answer instead of silently
  /// unlocking the reward. The exercise resets to unanswered so the
  /// options become tappable again.
  void _tryAgain() {
    setState(() {
      _selection = null;
      _answered = false;
      _wasCorrect = false;
    });
  }

  Future<void> _claimReward(BuildContext context) async {
    final progressNotifier = ref.read(userProgressProvider.notifier);
    await ref
        .read(dailyChallengeRepositoryProvider)
        .markCompleted(widget.challenge.dateKey);
    await progressNotifier.awardXp(widget.challenge.xpReward);
    final ProgressEvent? event = progressNotifier.lastEvent;
    progressNotifier.clearEvent();

    ref.read(gemsProvider.notifier).earn(GemsConfig.dailyChallengeComplete);

    final questsNotifier = ref.read(weeklyQuestsProvider.notifier);
    questsNotifier.recordProgress(metric: QuestMetric.exercisesSolved, amount: 1);
    questsNotifier.recordProgress(
      metric: QuestMetric.xpEarned,
      amount: widget.challenge.xpReward,
    );

    if (!mounted) return;
    if (event?.leveledUp == true) {
      setState(() => _pendingLevelUp = event!.newLevel);
      return;
    }
    if (context.mounted) context.pop();
  }
}

class _AlreadyDone extends StatelessWidget {
  const _AlreadyDone({required this.challenge});
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text('Сегодняшний челлендж пройден', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Возвращайся завтра за новым заданием.',
              style: text.bodyMedium?.copyWith(color: semantic.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
