import 'dart:math';

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
  late final List<String> _order = _initialOrder();

  /// Shuffles [Exercise.options] into a stable-but-scrambled starting
  /// order. Bundled/AI content isn't guaranteed to arrive pre-shuffled
  /// (some sources list the lines already in correct order), so without
  /// this the exercise could trivially start "solved" and give no
  /// actual reordering practice.
  ///
  /// Deterministic seed (based on the exercise id) rather than pure
  /// `..shuffle()`: avoids the rare but real chance of shuffling back
  /// into the exact correct order on some rebuilds, and keeps the
  /// starting layout stable if the widget rebuilds without the state
  /// being recreated.
  List<String> _initialOrder() {
    final List<String> lines = List<String>.from(widget.exercise.options);
    final List<String> correct =
        (widget.exercise.correctAnswer ?? '').split('\n').map((String l) => l.trim()).toList();
    if (lines.length < 2) return lines;

    final int seed = widget.exercise.id.hashCode;
    final List<String> shuffled = List<String>.from(lines)..shuffle(Random(seed));

    // If the shuffle happened to land on the already-correct order,
    // swap the first two lines so the user actually has something to
    // reorder.
    final List<String> shuffledTrimmed = shuffled.map((String l) => l.trim()).toList();
    if (shuffledTrimmed.length == correct.length &&
        List<int>.generate(shuffledTrimmed.length, (int i) => i)
            .every((int i) => shuffledTrimmed[i] == correct[i])) {
      final String tmp = shuffled[0];
      shuffled[0] = shuffled[1];
      shuffled[1] = tmp;
    }
    return shuffled;
  }

  @override
  void initState() {
    super.initState();
    // Report the starting order immediately, not just after the first
    // drag. Without this, a user who submits without ever reordering
    // (e.g. the shuffle already looks right to them, or they just tap
    // "Проверить" first) would be graded against a null/empty
    // selection instead of what's actually on screen — always wrong
    // regardless of whether their answer was actually correct.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSelectionChanged(_order.join('\n'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    // Trim each line individually before comparing — see
    // ExerciseWidgetFactory.isCorrect. Comparing the whole joined string
    // only strips the outer edges, so per-line indentation differences
    // from AI-generated content could still make a correct order compare
    // unequal.
    final List<String> correctOrder =
        (widget.exercise.correctAnswer ?? '').split('\n').map((String l) => l.trim()).toList();
    final List<String> currentOrder = _order.map((String l) => l.trim()).toList();
    final bool wasCorrect = widget.answered &&
        currentOrder.length == correctOrder.length &&
        List<int>.generate(currentOrder.length, (int i) => i)
            .every((int i) => currentOrder[i] == correctOrder[i]);

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
            final bool lineCorrectPosition =
                widget.answered && i < correctOrder.length && line.trim() == correctOrder[i];
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
