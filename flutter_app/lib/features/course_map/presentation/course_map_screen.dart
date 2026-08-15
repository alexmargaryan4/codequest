import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/course.dart';
import '../../../models/user_progress.dart';
import '../../../shared/widgets/topic_node_widget.dart';

/// Resolves a [Course] (with live topic statuses) for a given courseId,
/// re-computed whenever [userProgressProvider] changes.
final FutureProviderFamily<Course?, String> resolvedCourseProvider =
    FutureProvider.family<Course?, String>((Ref ref, String courseId) async {
  final UserProgress? progress = ref.watch(userProgressProvider).valueOrNull;
  if (progress == null) return null;
  final Course? course = await ref.watch(courseRepositoryProvider).getCourse(courseId);
  if (course == null) return null;
  return ref.watch(courseRepositoryProvider).resolveStatuses(course, progress);
});

/// The winding vertical course map: an alternating-offset column of
/// [TopicNodeWidget]s connected by [NodeConnector]s, matching the
/// product spec's "path with nodes" reference sketch. Each topic node
/// opens the next lesson in that topic, or the topic's mini-project if
/// all lessons are done.
class CourseMapScreen extends ConsumerWidget {
  const CourseMapScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Course?> courseAsync = ref.watch(resolvedCourseProvider(courseId));
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: courseAsync.valueOrNull != null
            ? Text(courseAsync.valueOrNull!.title)
            : const Text('Курс'),
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(child: Text('Не удалось загрузить курс: $e')),
        data: (Course? course) {
          if (course == null) {
            return const Center(child: Text('Курс не найден'));
          }
          if (course.topics.isEmpty) {
            return Center(
              child: Text('Темы скоро появятся', style: text.bodyLarge),
            );
          }
          return _MapBody(course: course);
        },
      ),
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.fromHex(course.colorSeed);
    final List<TopicNode> topics = List<TopicNode>.from(course.topics)
      ..sort((TopicNode a, TopicNode b) => a.orderIndex.compareTo(b.orderIndex));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: List<Widget>.generate(topics.length * 2 - 1, (int i) {
          if (i.isOdd) {
            final int prevIndex = i ~/ 2;
            return NodeConnector(completed: topics[prevIndex].status == TopicNodeStatus.completed);
          }
          final int topicIndex = i ~/ 2;
          final TopicNode topic = topics[topicIndex];
          // Alternate horizontal offset left/right for the "winding path"
          // look described in the product spec, without a heavy custom
          // painter.
          final double offset = (topicIndex.isEven ? -1 : 1) * 36.0;

          return Padding(
            padding: EdgeInsets.only(left: offset > 0 ? offset : 0, right: offset < 0 ? -offset : 0),
            child: TopicNodeWidget(
              topic: topic,
              accentColor: accent,
              onTap: () => _openTopic(context, topic),
            ),
          ).animate().fadeIn(delay: (topicIndex * 60).ms, duration: 300.ms).slideY(begin: 0.08, end: 0);
        }),
      ),
    );
  }

  void _openTopic(BuildContext context, TopicNode topic) {
    // A topic whose lessons are all done, but which still has an
    // un-started mini-project, opens the project directly.
    if (topic.miniProjectId != null && topic.status == TopicNodeStatus.available) {
      final bool allLessonsImplied = topic.lessonIds.isEmpty;
      if (allLessonsImplied) {
        context.push(AppRoutes.miniProjectPath(topic.miniProjectId!, topicId: topic.id));
        return;
      }
    }

    if (topic.lessonIds.isNotEmpty) {
      final String firstLessonId = topic.lessonIds.first;
      context.push(
        AppRoutes.lessonPath(firstLessonId, courseId: topic.courseId, topicId: topic.id),
      );
    } else if (topic.miniProjectId != null) {
      context.push(AppRoutes.miniProjectPath(topic.miniProjectId!, topicId: topic.id));
    }
  }
}
