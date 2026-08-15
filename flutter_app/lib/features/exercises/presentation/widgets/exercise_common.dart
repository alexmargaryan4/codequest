import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Monospace code display box, shared by every exercise type that shows
/// a code snippet (findTheBug, predictOutput, fixTheCode, codeCompletion).
class ExerciseCodeBlock extends StatelessWidget {
  const ExerciseCodeBlock({required this.code, super.key, this.highlightLine});

  final String code;

  /// 0-based line index to visually highlight (used by findTheBug once
  /// the user has made a selection), or null for no highlight.
  final int? highlightLine;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final List<String> lines = code.split('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(lines.length, (int i) {
          final bool highlighted = highlightLine == i;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 1),
            color: highlighted ? AppColors.accentIndigo.withValues(alpha: 0.15) : null,
            child: Text(
              lines[i].isEmpty ? ' ' : lines[i],
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
            ),
          );
        }),
      ),
    );
  }
}

/// Post-answer explanation banner, shared by every exercise type.
class ExerciseExplanationCard extends StatelessWidget {
  const ExerciseExplanationCard({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentIndigo, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Result banner shown after submission (correct/incorrect), shared by
/// free-form exercise types (writeCode, findTheBug, predictOutput,
/// fixTheCode) that don't have per-option highlighting.
class ExerciseResultBanner extends StatelessWidget {
  const ExerciseResultBanner({required this.wasCorrect, super.key});
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = wasCorrect ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            wasCorrect ? 'Правильно!' : 'Не совсем',
            style: text.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
