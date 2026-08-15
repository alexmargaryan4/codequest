import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/exercise.dart';
import 'exercise_common.dart';

/// matchPairs: tap a left item, then a right item, to connect them.
/// Matched pairs lock in place (green); a wrong tap briefly flashes red
/// and resets that selection so the user can try again — there's no
/// hard "fail" state mid-exercise, matching how matching games usually
/// feel.
///
/// State (which pairs are matched) is serialized to/from a JSON string
/// via [onSelectionChanged] so it fits the same `Object? selection`
/// plumbing every other exercise type uses.
class MatchPairsExercise extends StatefulWidget {
  const MatchPairsExercise({
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
  State<MatchPairsExercise> createState() => _MatchPairsExerciseState();
}

class _MatchPairsExerciseState extends State<MatchPairsExercise> {
  late final List<String> _rightShuffled = List<String>.from(
    widget.exercise.matchPairs.map((MatchPair p) => p.right),
  )..shuffle();

  final Set<String> _matchedLeft = <String>{};
  String? _selectedLeft;
  String? _wrongFlashRight;

  bool get _allMatched => _matchedLeft.length == widget.exercise.matchPairs.length;

  void _tapLeft(String left) {
    if (widget.answered || _matchedLeft.contains(left)) return;
    setState(() => _selectedLeft = _selectedLeft == left ? null : left);
  }

  void _tapRight(String right) {
    if (widget.answered || _selectedLeft == null) return;
    final MatchPair? pair = widget.exercise.matchPairs
        .where((MatchPair p) => p.left == _selectedLeft)
        .firstOrNull;
    if (pair != null && pair.right == right) {
      setState(() {
        _matchedLeft.add(_selectedLeft!);
        _selectedLeft = null;
      });
      widget.onSelectionChanged(jsonEncode(_matchedLeft.toList()));
      if (_allMatched) widget.onSubmit();
    } else {
      setState(() => _wrongFlashRight = right);
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongFlashRight = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.exercise.question, style: text.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Соедини понятие с объяснением',
          style: text.bodySmall?.copyWith(color: semantic.textMuted),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: widget.exercise.matchPairs.map((MatchPair p) {
                  final bool matched = _matchedLeft.contains(p.left);
                  final bool selected = _selectedLeft == p.left;
                  return _PairChip(
                    label: p.left,
                    matched: matched,
                    selected: selected,
                    onTap: () => _tapLeft(p.left),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: _rightShuffled.map((String right) {
                  final bool matched = widget.exercise.matchPairs
                      .any((MatchPair p) => p.right == right && _matchedLeft.contains(p.left));
                  final bool wrongFlash = _wrongFlashRight == right;
                  return _PairChip(
                    label: right,
                    matched: matched,
                    selected: false,
                    wrongFlash: wrongFlash,
                    onTap: () => _tapRight(right),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (_allMatched) ...<Widget>[
          const SizedBox(height: 16),
          const ExerciseResultBanner(wasCorrect: true).animate().fadeIn(duration: 250.ms),
        ],
      ],
    );
  }
}

class _PairChip extends StatelessWidget {
  const _PairChip({
    required this.label,
    required this.matched,
    required this.selected,
    required this.onTap,
    this.wrongFlash = false,
  });

  final String label;
  final bool matched;
  final bool selected;
  final bool wrongFlash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    Color border = semantic.border;
    Color bg = semantic.surfaceRaised;
    if (matched) {
      border = AppColors.success;
      bg = AppColors.success.withValues(alpha: 0.12);
    } else if (wrongFlash) {
      border = AppColors.error;
      bg = AppColors.error.withValues(alpha: 0.12);
    } else if (selected) {
      border = AppColors.accentIndigo;
      bg = AppColors.accentIndigo.withValues(alpha: 0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: matched ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected || matched ? 2 : 1),
          ),
          child: Text(
            label,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
