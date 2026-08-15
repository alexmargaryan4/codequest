import 'package:flutter/material.dart';

import '../../../models/exercise.dart';
import 'widgets/find_the_bug_exercise.dart';
import 'widgets/match_pairs_exercise.dart';
import 'widgets/multiple_choice_exercise.dart';
import 'widgets/predict_output_exercise.dart';
import 'widgets/reorder_lines_exercise.dart';
import 'widgets/write_code_exercise.dart';

/// Routes an [Exercise] to the widget that knows how to render its
/// [ExerciseType]. This is the ONLY place that needs to change when a
/// new exercise type is added (per the architecture note in
/// [ExerciseType] itself).
class ExerciseWidgetFactory {
  const ExerciseWidgetFactory._();

  static Widget build({
    required Exercise exercise,
    required bool answered,
    required Object? selection,
    required ValueChanged<Object?> onSelectionChanged,
    required VoidCallback onSubmit,
  }) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.codeCompletion:
        return MultipleChoiceExercise(
          exercise: exercise,
          answered: answered,
          selected: selection as String?,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
      case ExerciseType.findTheBug:
        return FindTheBugExercise(
          exercise: exercise,
          answered: answered,
          selected: selection as String?,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
      case ExerciseType.reorderLines:
        return ReorderLinesExercise(
          exercise: exercise,
          answered: answered,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
      case ExerciseType.predictOutput:
        return PredictOutputExercise(
          exercise: exercise,
          answered: answered,
          selected: selection as String?,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
      case ExerciseType.matchPairs:
        return MatchPairsExercise(
          exercise: exercise,
          answered: answered,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
      case ExerciseType.writeCode:
      case ExerciseType.fixTheCode:
      case ExerciseType.practicalTask:
      case ExerciseType.miniChallenge:
        return WriteCodeExercise(
          exercise: exercise,
          answered: answered,
          initialValue: selection as String?,
          onSelectionChanged: (String v) => onSelectionChanged(v),
          onSubmit: onSubmit,
        );
    }
  }

  /// Whether [selection] counts as correct for [exercise], per its type's
  /// grading rule. Open-ended types (writeCode/fixTheCode/practicalTask/
  /// miniChallenge/matchPairs) are always treated as "correct" on
  /// submit — they're self-assessed or completion-graded rather than
  /// strictly matched, since there's no single right answer to compare
  /// against.
  static bool isCorrect(Exercise exercise, Object? selection) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.codeCompletion:
      case ExerciseType.findTheBug:
        return selection == exercise.correctAnswer;
      case ExerciseType.predictOutput:
        final String expected = (exercise.correctAnswer ?? '').trim().toLowerCase();
        final String actual = (selection as String? ?? '').trim().toLowerCase();
        return expected == actual;
      case ExerciseType.reorderLines:
        final String expected = (exercise.correctAnswer ?? '').trim();
        final String actual = (selection as String? ?? '').trim();
        return expected == actual;
      case ExerciseType.matchPairs:
      case ExerciseType.writeCode:
      case ExerciseType.fixTheCode:
      case ExerciseType.practicalTask:
      case ExerciseType.miniChallenge:
        return true;
    }
  }
}
