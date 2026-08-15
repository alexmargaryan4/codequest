import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/progress_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mini_project.dart';
import '../../exercises/presentation/widgets/exercise_common.dart';

/// Loads a [MiniProject] by id from the bundled per-course project data.
/// Mini projects are hand-authored content (not AI-generated per-request
/// like lessons) since they're meant to be the same fixed 5-20 minute
/// task described in the product spec, so a simple bundled-asset lookup
/// is sufficient — no AI/cache path needed here.
final FutureProviderFamily<MiniProject?, String> miniProjectProvider =
    FutureProvider.family<MiniProject?, String>((Ref ref, String projectId) async {
  try {
    final String raw = await rootBundle.loadString('assets/data/fallback_lessons/mini_projects.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    for (final dynamic e in decoded) {
      final MiniProject p = MiniProject.fromJson(e as Map<String, dynamic>);
      if (p.id == projectId) return p;
    }
  } catch (_) {
    // Falls through to null below.
  }
  return null;
});

class MiniProjectScreen extends ConsumerStatefulWidget {
  const MiniProjectScreen({required this.projectId, required this.topicId, super.key});

  final String projectId;
  final String topicId;

  @override
  ConsumerState<MiniProjectScreen> createState() => _MiniProjectScreenState();
}

class _MiniProjectScreenState extends ConsumerState<MiniProjectScreen> {
  late final TextEditingController _codeController;
  bool _initialized = false;
  bool _submitted = false;
  int? _hintIndex;
  int? _pendingLevelUp;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MiniProject?> projectAsync =
        ref.watch(miniProjectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Мини-проект')),
      body: SafeArea(
        child: projectAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка: $e')),
          data: (MiniProject? project) {
            if (project == null) {
              return const Center(child: Text('Проект не найден'));
            }
            if (!_initialized) {
              _codeController.text = project.starterCode;
              _initialized = true;
            }
            return _submitted
                ? _ProjectComplete(project: project)
                : _ProjectBody(
                    project: project,
                    codeController: _codeController,
                    hintIndex: _hintIndex,
                    onRequestHint: () => setState(() {
                      _hintIndex = ((_hintIndex ?? -1) + 1).clamp(0, project.hints.length - 1);
                    }),
                    onSubmit: () => _complete(project),
                  );
          },
        ),
      ),
    );
  }

  Future<void> _complete(MiniProject project) async {
    final notifier = ref.read(userProgressProvider.notifier);
    await notifier.completeMiniProject(projectId: project.id, topicId: widget.topicId);
    final ProgressEvent? event = notifier.lastEvent;
    notifier.clearEvent();
    setState(() {
      _submitted = true;
      if (event?.leveledUp == true) _pendingLevelUp = event!.newLevel;
    });
  }
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({
    required this.project,
    required this.codeController,
    required this.hintIndex,
    required this.onRequestHint,
    required this.onSubmit,
  });

  final MiniProject project;
  final TextEditingController codeController;
  final int? hintIndex;
  final VoidCallback onRequestHint;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.streakAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.streakAmber),
                    const SizedBox(width: 4),
                    Text('5–20 мин', style: text.labelSmall?.copyWith(color: AppColors.streakAmber)),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, color: AppColors.accentIndigo, size: 16),
                  Text(' +${project.xpReward} XP', style: text.labelLarge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(project.title, style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(project.description, style: text.bodyMedium?.copyWith(color: semantic.textMuted)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
            ),
            child: Text(project.instructions, style: text.bodyLarge),
          ),
          const SizedBox(height: 20),
          Text('Твой код', style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: codeController,
            maxLines: 12,
            minLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: semantic.surfaceRaised,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (project.hints.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (hintIndex ?? -1) >= project.hints.length - 1 ? null : onRequestHint,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: const Text('Подсказка'),
              ),
            ),
          if (hintIndex != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExerciseExplanationCard(text: project.hints[hintIndex!]),
            ).animate().fadeIn(duration: 250.ms),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: codeController.text.trim().isEmpty ? null : onSubmit,
            child: const Text('Завершить проект'),
          ),
        ],
      ),
    );
  }
}

class _ProjectComplete extends StatelessWidget {
  const _ProjectComplete({required this.project});
  final MiniProject project;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: <Color>[AppColors.success, AppColors.successMuted]),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 46),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Проект завершён!', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              project.title,
              style: text.bodyMedium?.copyWith(color: semantic.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: semantic.border),
              ),
              child: Text('+${project.xpReward} XP', style: text.titleMedium),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
