import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/course.dart';

final StateProvider<LearningTrack> selectedTrackProvider =
    StateProvider<LearningTrack>((Ref ref) => LearningTrack.programming);

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LearningTrack track = ref.watch(selectedTrackProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Learn', style: text.headlineMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _TrackSelector(
                track: track,
                onChanged: (LearningTrack t) => ref.read(selectedTrackProvider.notifier).state = t,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _CourseGrid(track: track),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({required this.track, required this.onChanged});

  final LearningTrack track;
  final ValueChanged<LearningTrack> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentButton(
              label: 'Programming',
              icon: Icons.code_rounded,
              selected: track == LearningTrack.programming,
              onTap: () => onChanged(LearningTrack.programming),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'AI',
              icon: Icons.auto_awesome_rounded,
              selected: track == LearningTrack.ai,
              onTap: () => onChanged(LearningTrack.ai),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: selected ? Colors.white : null),
            const SizedBox(width: 6),
            Text(
              label,
              style: text.labelLarge?.copyWith(color: selected ? Colors.white : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseGrid extends ConsumerWidget {
  const _CourseGrid({required this.track});

  final LearningTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Course>>(
      future: ref.read(courseRepositoryProvider).getCoursesForTrack(track),
      builder: (BuildContext context, AsyncSnapshot<List<Course>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Course> courses = snapshot.data!;
        if (courses.isEmpty) {
          return const Center(child: Text('Курсы скоро появятся'));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: courses.length,
          itemBuilder: (BuildContext context, int i) {
            return _CourseCard(course: courses[i])
                .animate()
                .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0);
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final Color accent = AppColors.fromHex(course.colorSeed);
    final bool locked = !course.isAvailable;

    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: locked ? null : () => context.push(AppRoutes.courseMapPath(course.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.terminal_rounded, color: accent, size: 24),
                ),
                const Spacer(),
                Text(course.title, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  course.comingSoon ? 'Скоро' : '${course.topics.length} тем',
                  style: text.labelSmall?.copyWith(color: semantic.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
