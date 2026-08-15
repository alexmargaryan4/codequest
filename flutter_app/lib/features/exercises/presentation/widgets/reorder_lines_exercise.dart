import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// reorderLines: user arranges shuffled code lines into the correct
/// order. Implemented as a ReorderableListView (drag handles) rather
/// than raw drag targets, for reliable behavior on both Android and iOS
/// touch input.
class ReorderLinesExercise extends StatefulWidget {
  const ReorderLinesExercise({
    required this.exercise,
    required this.answered,
    required this.onSelectionChanged,
    required this.onSubmit,
    super.key,
  });

  final Exercise exercise;
  final bool answered;
  final ValueChanged<String> onSelectionChanged;
  final VoidCallback onSubmit;

  @override
  State<ReorderLinesExercise> createState() => _ReorderLinesExerciseState();
}

class _ReorderLinesExerciseState extends State<ReorderLinesExercise> {
  final List<String> _order = List<String>.from(widget.exercise.options);

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> correctOrder = (widget.exercise.correctAnswer ?? '').split('\n');
    final bool wasCorrect = widget.answered && _order.join('\n') == correctOrder.join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.exercise.question, style: text.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Перетащи строки в правильном порядке',
          style: text.bodySmall?.copyWith(color: semantic.textMuted),
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !widget.answered,
          itemCount: _order.length,
          onReorder: (int oldIndex, int newIndex) {
            if (widget.answered) return;
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final String item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
            widget.onSelectionChanged(_order.join('\n'));
          },
          itemBuilder: (BuildContext context, int i) {
            final String line = _order[i];
            final bool lineCorrectPosition = widget.answered && i < correctOrder.length && line == correctOrder[i];
            return Container(
              key: ValueKey<String>('$line-$i'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.answered
                    ? (lineCorrectPosition
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12))
                    : semantic.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: widget.answered
                      ? (lineCorrectPosition ? AppColors.success : AppColors.error)
                      : semantic.border,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Text('${i + 1}.', style: text.labelMedium?.copyWith(color: semantic.textMuted)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                  ),
                  if (!widget.answered) Icon(Icons.drag_handle_rounded, color: semantic.textMuted),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (!widget.answered)
          ElevatedButton(onPressed: widget.onSubmit, child: const Text('Проверить')),
        if (widget.answered) ...<Widget>[
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
