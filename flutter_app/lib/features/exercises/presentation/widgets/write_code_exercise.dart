import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// Open-ended exercise types with no single strict-equality correct
/// answer: writeCode, fixTheCode, practicalTask, miniChallenge.
///
/// The user writes their solution in a code-styled text field, then
/// self-assesses against a reference explanation/solution shown after
/// submit (rather than a strict string match, which would be far too
/// brittle for free-form code). This mirrors how the mini-project
/// screen handles grading, minus AI-assisted feedback (kept simple here
/// since these are quick in-lesson exercises, not full projects).
class WriteCodeExercise extends StatefulWidget {
  const WriteCodeExercise({
    required this.exercise,
    required this.answered,
    required this.onSelectionChanged,
    required this.onSubmit,
    this.initialValue,
    super.key,
  });

  final Exercise exercise;
  final bool answered;
  final String? initialValue;
  final ValueChanged<String> onSelectionChanged;
  final VoidCallback onSubmit;

  @override
  State<WriteCodeExercise> createState() => _WriteCodeExerciseState();
}

class _WriteCodeExerciseState extends State<WriteCodeExercise> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.exercise.question, style: text.titleMedium),
        if (widget.exercise.codeSnippet != null) ...<Widget>[
          const SizedBox(height: 16),
          ExerciseCodeBlock(code: widget.exercise.codeSnippet!),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          enabled: !widget.answered,
          onChanged: widget.onSelectionChanged,
          maxLines: 6,
          minLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Напиши свой код здесь...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: semantic.surfaceRaised,
          ),
        ),
        const SizedBox(height: 12),
        if (!widget.answered)
          ElevatedButton(
            onPressed: _controller.text.trim().isEmpty ? null : widget.onSubmit,
            child: const Text('Готово'),
          ),
        if (widget.answered) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Засчитано! Сравни с примером ниже.', style: text.titleMedium?.copyWith(color: AppColors.success)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms),
          if (widget.exercise.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ExerciseExplanationCard(text: widget.exercise.explanation),
            ).animate().fadeIn(duration: 250.ms, delay: 100.ms),
          if (widget.exercise.correctAnswer != null && widget.exercise.correctAnswer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Пример решения', style: text.labelLarge?.copyWith(color: semantic.textMuted)),
                  const SizedBox(height: 8),
                  ExerciseCodeBlock(code: widget.exercise.correctAnswer!),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms, delay: 150.ms),
        ],
      ],
    );
  }
}
