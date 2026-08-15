import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/exercise.dart';
import '../../../models/lesson.dart';
import '../../../shared/widgets/level_up_overlay.dart';
import '../../exercises/presentation/exercise_widget_factory.dart';
import '../application/lesson_provider.dart';
import '../application/lesson_session_notifier.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({
    required this.lessonId,
    required this.courseId,
    required this.topicId,
    super.key,
  });

  final String lessonId;
  final String courseId;
  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Lesson> lessonAsync = ref.watch(
      lessonProvider(LessonRequest(lessonId: lessonId, courseId: courseId, topicId: topicId)),
    );

    return Scaffold(
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const _LessonLoading(),
          error: (Object e, StackTrace st) => _LessonError(error: e),
          data: (Lesson lesson) => _LessonBody(lesson: lesson),
        ),
      ),
    );
  }
}

class _LessonLoading extends StatelessWidget {
  const _LessonLoading();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Готовим урок для тебя...', style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _LessonError extends StatelessWidget {
  const _LessonError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Урок временно недоступен', style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Проверь подключение к интернету и попробуй снова.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }
}

class _LessonBody extends ConsumerStatefulWidget {
  const _LessonBody({required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends ConsumerState<_LessonBody> {
  bool _requestingHint = false;
  int? _pendingLevelUp;

  @override
  Widget build(BuildContext context) {
    final LessonSessionState session = ref.watch(lessonSessionProvider(widget.lesson));
    final LessonSessionNotifier notifier = ref.read(lessonSessionProvider(widget.lesson).notifier);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    if (session.finished) {
      return _LessonComplete(lesson: widget.lesson, session: session);
    }

    final Exercise exercise = session.currentExercise;
    final double progress = (session.exerciseIndex) / session.totalExercises;

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        builder: (BuildContext context, double value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: semantic.surfaceRaised,
                            color: AppColors.accentIndigo,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, color: AppColors.accentIndigo, size: 18),
                      const SizedBox(width: 2),
                      Text('${session.xpEarned}', style: text.labelLarge),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey<String>(exercise.id),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _DifficultyTag(difficulty: exercise.difficulty),
                      const SizedBox(height: 12),
                      ExerciseWidgetFactory.build(
                        exercise: exercise,
                        answered: session.currentAnswered,
                        selection: session.currentSelection,
                        onSelectionChanged: notifier.updateSelection,
                        onSubmit: () {
                          final bool correct =
                              ExerciseWidgetFactory.isCorrect(exercise, session.currentSelection);
                          notifier.submitAnswer(answerIsCorrect: correct);
                        },
                      ),
                      if (!session.currentAnswered && exercise.hints.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _requestingHint
                                ? null
                                : () => _showHint(context, exercise, notifier),
                            icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                            label: const Text('Подсказка'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (session.currentAnswered)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final bool hasNext = notifier.advance();
                      if (!hasNext) {
                        await _completeLesson(context, ref, widget.lesson, session);
                      }
                    },
                    child: Text(session.isLastExercise ? 'Завершить урок' : 'Продолжить'),
                  ),
                ),
              ),
          ],
        ),
        if (_pendingLevelUp != null)
          LevelUpOverlay(
            newLevel: _pendingLevelUp!,
            onDismiss: () => setState(() => _pendingLevelUp = null),
          ),
      ],
    );
  }

  Future<void> _showHint(
    BuildContext context,
    Exercise exercise,
    LessonSessionNotifier notifier,
  ) async {
    setState(() => _requestingHint = true);
    try {
      final int hintsUsed =
          ref.read(lessonSessionProvider(widget.lesson)).hintsUsedByExercise[exercise.id] ?? 0;
      final List<String> previousHints = List<String>.generate(
        hintsUsed,
        (int i) => i < exercise.hints.length ? exercise.hints[i] : '',
      );
      final String hint = await ref.read(hintServiceProvider).getNextHint(
            question: exercise.question,
            codeSnippet: exercise.codeSnippet,
            authoredHints: exercise.hints,
            previousHints: previousHints,
          );
      notifier.registerHintUsed();
      if (context.mounted) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext ctx) => _HintSheet(hint: hint),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingHint = false);
    }
  }

  Future<void> _completeLesson(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    LessonSessionState session,
  ) async {
    final notifier = ref.read(userProgressProvider.notifier);
    await notifier.completeLesson(
      lessonId: lesson.id,
      topicId: lesson.topicId,
      courseId: lesson.courseId,
      wasPerfect: session.wasPerfect,
    );
    final ProgressEvent? event = notifier.lastEvent;
    notifier.clearEvent();
    if (event?.leveledUp == true && mounted) {
      setState(() => _pendingLevelUp = event!.newLevel);
    }
  }
}

class _DifficultyTag extends StatelessWidget {
  const _DifficultyTag({required this.difficulty});
  final ExerciseDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String label = switch (difficulty) {
      ExerciseDifficulty.easy => 'Легко',
      ExerciseDifficulty.medium => 'Средне',
      ExerciseDifficulty.hard => 'Сложно',
    };
    final Color color = switch (difficulty) {
      ExerciseDifficulty.easy => AppColors.success,
      ExerciseDifficulty.medium => AppColors.streakAmber,
      ExerciseDifficulty.hard => AppColors.error,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: text.labelSmall?.copyWith(color: color)),
      ),
    );
  }
}

class _HintSheet extends StatelessWidget {
  const _HintSheet({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.lightbulb_rounded, color: AppColors.accentIndigo),
              const SizedBox(width: 8),
              Text('Подсказка', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(hint, style: text.bodyLarge),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LessonComplete extends ConsumerWidget {
  const _LessonComplete({required this.lesson, required this.session});
  final Lesson lesson;
  final LessonSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final int correctCount = session.wasCorrectByExercise.values.where((bool v) => v).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[AppColors.accentIndigoMuted, AppColors.accentIndigo],
                ),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Урок завершён!', style: text.headlineMedium).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text(
              session.wasPerfect
                  ? 'Идеально — все ответы верны с первой попытки!'
                  : 'Правильно: $correctCount из ${session.totalExercises}',
              style: text.bodyMedium?.copyWith(color: semantic.textMuted),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: semantic.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, color: AppColors.accentIndigo),
                  const SizedBox(width: 6),
                  Text('+${session.xpEarned + lesson.xpReward} XP', style: text.titleMedium),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
