import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// findTheBug: the user taps the line of code containing the bug.
/// [Exercise.correctAnswer] holds the exact text of the buggy line.
class FindTheBugExercise extends StatelessWidget {
  const FindTheBugExercise({
    required this.exercise,
    required this.answered,
    required this.onSelectionChanged,
    required this.onSubmit,
    this.selected,
    super.key,
  });

  final Exercise exercise;
  final bool answered;
  final String? selected;
  final ValueChanged<String> onSelectionChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> lines = (exercise.codeSnippet ?? '').split('\n');
    final bool wasCorrect = answered && selected == exercise.correctAnswer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(exercise.question, style: text.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Нажми на строку с ошибкой',
          style: text.bodySmall?.copyWith(color: semantic.textMuted),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: semantic.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: semantic.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(lines.length, (int i) {
              final String line = lines[i];
              final bool isSelected = line == selected;
              final bool isCorrectLine = line.trim() == (exercise.correctAnswer ?? '').trim();

              Color? bg;
              if (answered && isCorrectLine) {
                bg = AppColors.success.withValues(alpha: 0.18);
              } else if (answered && isSelected && !isCorrectLine) {
                bg = AppColors.error.withValues(alpha: 0.18);
              } else if (!answered && isSelected) {
                bg = AppColors.accentIndigo.withValues(alpha: 0.18);
              }

              return InkWell(
                onTap: answered || line.trim().isEmpty ? null : () => onSelectionChanged(line),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  color: bg,
                  child: Text(
                    line.isEmpty ? ' ' : line,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        if (!answered)
          ElevatedButton(
            onPressed: selected == null ? null : onSubmit,
            child: const Text('Проверить'),
          ),
        if (answered) ...<Widget>[
          ExerciseResultBanner(wasCorrect: wasCorrect).animate().fadeIn(duration: 250.ms),
          if (exercise.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ExerciseExplanationCard(text: exercise.explanation),
            ).animate().fadeIn(duration: 250.ms, delay: 100.ms),
        ],
      ],
    );
  }
}
