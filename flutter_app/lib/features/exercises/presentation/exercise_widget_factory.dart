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
  ///
  /// All string comparisons below trim whitespace (and lowercase where
  /// case isn't meaningful) before comparing. AI-generated content in
  /// particular can differ from the option/line text by incidental
  /// leading/trailing whitespace or indentation without that difference
  /// being a real wrong answer — an exact `==` there was marking genuinely
  /// correct taps as wrong.
  static bool isCorrect(Exercise exercise, Object? selection) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.codeCompletion:
        final String expected = (exercise.correctAnswer ?? '').trim();
        final String actual = (selection as String? ?? '').trim();
        return expected.isNotEmpty && expected == actual;
      case ExerciseType.findTheBug:
        final String expected = (exercise.correctAnswer ?? '').trim();
        final String actual = (selection as String? ?? '').trim();
        return expected.isNotEmpty && expected == actual;
      case ExerciseType.predictOutput:
        // Line-by-line so a multi-line expected output (e.g. one value
        // per loop iteration) isn't broken by a stray trailing space on
        // just one line while the rest of the answer is exactly right.
        final List<String> expectedOutLines = (exercise.correctAnswer ?? '')
            .split('\n')
            .map((String l) => l.trim().toLowerCase())
            .toList();
        final List<String> actualOutLines = (selection as String? ?? '')
            .split('\n')
            .map((String l) => l.trim().toLowerCase())
            .toList();
        return expectedOutLines.length == actualOutLines.length &&
            List.generate(expectedOutLines.length, (int i) => i)
                .every((int i) => expectedOutLines[i] == actualOutLines[i]);
      case ExerciseType.reorderLines:
        final List<String> expectedLines = (exercise.correctAnswer ?? '')
            .split('\n')
            .map((String l) => l.trim())
            .toList();
        final List<String> actualLines =
            (selection as String? ?? '').split('\n').map((String l) => l.trim()).toList();
        return expectedLines.length == actualLines.length &&
            List.generate(expectedLines.length, (int i) => i)
                .every((int i) => expectedLines[i] == actualLines[i]);
      case ExerciseType.matchPairs:
      case ExerciseType.writeCode:
      case ExerciseType.fixTheCode:
      case ExerciseType.practicalTask:
      case ExerciseType.miniChallenge:
        return true;
    }
  }
}
