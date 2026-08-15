import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/exercise.dart';
import '../../../models/lesson.dart';
import '../../../models/user_progress.dart';
import '../../../core/constants/xp_constants.dart';

/// Immutable snapshot of where the user is within a single lesson
/// attempt: which exercise they're on, what they've answered so far, and
/// running stats used for the "perfect lesson" bonus and for adaptive
/// tracking (attempts, hints used, time spent).
class LessonSessionState {
  const LessonSessionState({
    required this.lesson,
    required this.exerciseIndex,
    required this.answered,
    required this.wasCorrectByExercise,
    required this.hintsUsedByExercise,
    required this.xpEarned,
    required this.startedAt,
    this.currentSelection,
    this.revealExplanation = false,
    this.finished = false,
  });

  final Lesson lesson;
  final int exerciseIndex;

  /// Exercise ids the user has already submitted an answer for.
  final Set<String> answered;
  final Map<String, bool> wasCorrectByExercise;
  final Map<String, int> hintsUsedByExercise;
  final int xpEarned;
  final DateTime startedAt;

  /// Transient in-progress answer for the current exercise (e.g. the
  /// selected option, or reordered lines), cleared on submit.
  final Object? currentSelection;
  final bool revealExplanation;
  final bool finished;

  Exercise get currentExercise => lesson.exercises[exerciseIndex];
  int get totalExercises => lesson.exercises.length;
  bool get isLastExercise => exerciseIndex == totalExercises - 1;
  bool get currentAnswered => answered.contains(currentExercise.id);

  bool get wasPerfect =>
      wasCorrectByExercise.values.every((bool v) => v) &&
      hintsUsedByExercise.values.every((int v) => v == 0);

  LessonSessionState copyWith({
    int? exerciseIndex,
    Set<String>? answered,
    Map<String, bool>? wasCorrectByExercise,
    Map<String, int>? hintsUsedByExercise,
    int? xpEarned,
    Object? currentSelection,
    bool clearSelection = false,
    bool? revealExplanation,
    bool? finished,
  }) {
    return LessonSessionState(
      lesson: lesson,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      answered: answered ?? this.answered,
      wasCorrectByExercise: wasCorrectByExercise ?? this.wasCorrectByExercise,
      hintsUsedByExercise: hintsUsedByExercise ?? this.hintsUsedByExercise,
      xpEarned: xpEarned ?? this.xpEarned,
      startedAt: startedAt,
      currentSelection: clearSelection ? null : (currentSelection ?? this.currentSelection),
      revealExplanation: revealExplanation ?? this.revealExplanation,
      finished: finished ?? this.finished,
    );
  }
}

/// One-shot feedback event for the current exercise submission, consumed
/// by the UI to trigger the correct/incorrect animation.
class ExerciseFeedback {
  const ExerciseFeedback({required this.wasCorrect, required this.xpGained});
  final bool wasCorrect;
  final int xpGained;
}

class LessonSessionNotifier extends StateNotifier<LessonSessionState> {
  LessonSessionNotifier({required Lesson lesson, required this.ref})
      : super(
          LessonSessionState(
            lesson: lesson,
            exerciseIndex: 0,
            answered: const <String>{},
            wasCorrectByExercise: const <String, bool>{},
            hintsUsedByExercise: const <String, int>{},
            xpEarned: 0,
            startedAt: DateTime.now(),
          ),
        );

  final Ref ref;
  ExerciseFeedback? lastFeedback;

  void updateSelection(Object? selection) {
    state = state.copyWith(currentSelection: selection);
  }

  /// Submits [answerIsCorrect] for the current exercise, awards XP, and
  /// records the attempt for the adaptive engine. Open-ended exercise
  /// types (writeCode/practicalTask/miniChallenge) pass `true` once the
  /// user has self-assessed or received AI feedback, since they have no
  /// single strict correct answer.
  void submitAnswer({required bool answerIsCorrect}) {
    final Exercise exercise = state.currentExercise;
    if (state.currentAnswered) return;

    final int hintsUsed = state.hintsUsedByExercise[exercise.id] ?? 0;
    final int xp = answerIsCorrect
        ? (hintsUsed > 0 ? XpRewards.correctAnswerAfterHint : XpRewards.correctAnswerFirstTry)
        : 0;

    state = state.copyWith(
      answered: <String>{...state.answered, exercise.id},
      wasCorrectByExercise: <String, bool>{...state.wasCorrectByExercise, exercise.id: answerIsCorrect},
      xpEarned: state.xpEarned + xp,
      revealExplanation: true,
    );
    lastFeedback = ExerciseFeedback(wasCorrect: answerIsCorrect, xpGained: xp);

    ref.read(progressServiceProvider).recordExerciseAttempt(
          topicId: state.lesson.topicId,
          wasCorrect: answerIsCorrect,
          usedHint: hintsUsed > 0,
          timeSeconds: DateTime.now().difference(state.startedAt).inSeconds,
        );
  }

  void registerHintUsed() {
    final Exercise exercise = state.currentExercise;
    final int current = state.hintsUsedByExercise[exercise.id] ?? 0;
    state = state.copyWith(
      hintsUsedByExercise: <String, int>{...state.hintsUsedByExercise, exercise.id: current + 1},
    );
  }

  bool advance() {
    if (state.isLastExercise) {
      state = state.copyWith(finished: true);
      return false;
    }
    state = state.copyWith(
      exerciseIndex: state.exerciseIndex + 1,
      clearSelection: true,
      revealExplanation: false,
    );
    return true;
  }
}

final StateNotifierProviderFamily<LessonSessionNotifier, LessonSessionState, Lesson>
    lessonSessionProvider =
    StateNotifierProvider.family<LessonSessionNotifier, LessonSessionState, Lesson>(
  (Ref ref, Lesson lesson) => LessonSessionNotifier(lesson: lesson, ref: ref),
);
