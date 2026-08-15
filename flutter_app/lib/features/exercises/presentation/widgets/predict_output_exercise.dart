import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// predictOutput: shows a code snippet, the user predicts stdout. Uses
/// multiple-choice-style options when the AI/fallback content supplied
/// them (most common — easier to grade reliably); falls back to a free
/// text field when no options were generated.
class PredictOutputExercise extends StatefulWidget {
  const PredictOutputExercise({
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
  State<PredictOutputExercise> createState() => _PredictOutputExerciseState();
}

class _PredictOutputExerciseState extends State<PredictOutputExercise> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.selected ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasOptions => widget.exercise.options.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    // Line-by-line, case-insensitive — must match
    // ExerciseWidgetFactory.isCorrect exactly, or this banner can
    // disagree with the actual graded result.
    final List<String> expectedLines = (widget.exercise.correctAnswer ?? '')
        .split('\n')
        .map((String l) => l.trim().toLowerCase())
        .toList();
    final List<String> selectedLines =
        (widget.selected ?? '').split('\n').map((String l) => l.trim().toLowerCase()).toList();
    final bool wasCorrect = widget.answered &&
        expectedLines.length == selectedLines.length &&
        List<int>.generate(expectedLines.length, (int i) => i)
            .every((int i) => expectedLines[i] == selectedLines[i]);
    final String expected = (widget.exercise.correctAnswer ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.exercise.question, style: text.titleMedium),
        const SizedBox(height: 16),
        ExerciseCodeBlock(code: widget.exercise.codeSnippet ?? ''),
        const SizedBox(height: 20),
        Text('Что выведет этот код?', style: text.labelLarge?.copyWith(color: semantic.textMuted)),
        const SizedBox(height: 10),
        if (_hasOptions)
          ...widget.exercise.options.map((String option) {
            // Trim (and match wasCorrect's case-insensitivity) so this
            // highlight never disagrees with the actual graded result
            // above — see ExerciseWidgetFactory.isCorrect.
            final bool isSelected =
                option.trim().toLowerCase() == (widget.selected ?? '').trim().toLowerCase();
            final bool isCorrectOption = option.trim().toLowerCase() == expected.toLowerCase();
            Color borderColor = semantic.border;
            Color bgColor = semantic.surfaceRaised;
            double borderWidth = 1;
            if (widget.answered) {
              if (isCorrectOption) {
                borderColor = AppColors.success;
                bgColor = AppColors.success.withValues(alpha: 0.1);
                borderWidth = 2;
              } else if (isSelected) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withValues(alpha: 0.1);
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
                onTap: widget.answered ? null : () => widget.onSelectionChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  child: Text(option, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
            );
          })
        else
          TextField(
            controller: _controller,
            enabled: !widget.answered,
            onChanged: widget.onSelectionChanged,
            // Some expected outputs span multiple lines (e.g. a loop that
            // prints one value per line). A default single-line TextField
            // can't produce a '\n' at all, so a multi-line correct answer
            // would have been impossible to type — not just hard to match.
            maxLines: null,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: 'Введи ожидаемый вывод',
              border: OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 8),
        if (!widget.answered)
          ElevatedButton(
            onPressed: (widget.selected == null || widget.selected!.trim().isEmpty)
                ? null
                : widget.onSubmit,
            child: const Text('Проверить'),
          ),
        if (widget.answered) ...<Widget>[
          const SizedBox(height: 12),
          ExerciseResultBanner(wasCorrect: wasCorrect).animate().fadeIn(duration: 250.ms),
          if (widget.exercise.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ExerciseExplanationCard(text: widget.exercise.explanation),
            ).animate().fadeIn(duration: 250.ms, delay: 100.ms),
        ],
      ],
    );
  }
}
