import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// Renders multipleChoice and codeCompletion exercises identically: a
/// question (with optional code snippet), a vertical list of tappable
/// option cards, and a submit button. codeCompletion differs only in
/// that [Exercise.codeSnippet] typically contains a blank ("____") the
/// options fill in — the interaction is otherwise the same.
class MultipleChoiceExercise extends StatelessWidget {
  const MultipleChoiceExercise({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(exercise.question, style: text.titleMedium),
        if (exercise.codeSnippet != null) ...<Widget>[
          const SizedBox(height: 16),
          ExerciseCodeBlock(code: exercise.codeSnippet!),
        ],
        const SizedBox(height: 20),
        ...exercise.options.map((String option) {
          final bool isSelected = option == selected;
          final bool isCorrectOption = option == exercise.correctAnswer;

          Color borderColor = semantic.border;
          Color bgColor = semantic.surfaceRaised;
          Widget? trailing;
          double borderWidth = 1;

          if (answered) {
            if (isCorrectOption) {
              borderColor = AppColors.success;
              bgColor = AppColors.success.withValues(alpha: 0.1);
              trailing = const Icon(Icons.check_circle_rounded, color: AppColors.success);
              borderWidth = 2;
            } else if (isSelected) {
              borderColor = AppColors.error;
              bgColor = AppColors.error.withValues(alpha: 0.1);
              trailing = const Icon(Icons.cancel_rounded, color: AppColors.error);
              borderWidth = 2;
            }
          } else if (isSelected) {
            borderColor = AppColors.accentIndigo;
            bgColor = AppColors.accentIndigo.withValues(alpha: 0.08);
            borderWidth = 2;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: answered ? null : () => onSelectionChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(option, style: text.bodyLarge?.copyWith(fontFamily: 'monospace')),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (!answered)
          ElevatedButton(
            onPressed: selected == null ? null : onSubmit,
            child: const Text('Проверить'),
          ),
        if (answered && exercise.explanation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ExerciseExplanationCard(text: exercise.explanation),
          ).animate().fadeIn(duration: 250.ms),
      ],
    );
  }
}
