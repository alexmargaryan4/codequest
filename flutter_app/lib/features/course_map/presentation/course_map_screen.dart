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

/// The winding vertical course map: a centered, alternating-offset path
/// of [TopicNodeWidget]s connected by smooth curved segments (painted by
/// [_PathPainter]), matching the product spec's "path with nodes"
/// reference sketch. Each topic node opens the first lesson in that
/// topic the user hasn't completed yet, or the topic's mini-project once
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
          final Set<String> completedLessonIds =
              ref.watch(userProgressProvider).valueOrNull?.completedLessonIds ??
                  const <String>{};
          return _MapBody(course: course, completedLessonIds: completedLessonIds);
        },
      ),
    );
  }
}

/// Horizontal distance each node is nudged from the vertical center line
/// to create the winding path. Kept modest so nodes stay visually
/// centered on the screen rather than drifting toward one edge.
const double _kNodeOffset = 46.0;
const double _kNodeSize = 64.0;
const double _kConnectorHeight = 56.0;
const double _kRowHeight = _kNodeSize + _kConnectorHeight;

class _MapBody extends StatelessWidget {
  const _MapBody({required this.course, required this.completedLessonIds});
  final Course course;
  final Set<String> completedLessonIds;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.fromHex(course.colorSeed);
    final List<TopicNode> topics = List<TopicNode>.from(course.topics)
      ..sort((TopicNode a, TopicNode b) => a.orderIndex.compareTo(b.orderIndex));

    final double contentHeight = _kNodeSize + (topics.length - 1) * _kRowHeight + 56;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The path winds within a fixed lane centered on the available
        // width, so it always reads as centered regardless of screen size.
        final double centerX = constraints.maxWidth / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: constraints.maxWidth,
            height: contentHeight,
            child: Stack(
              children: <Widget>[
                // Connector lines drawn first so nodes sit visually on top.
                CustomPaint(
                  size: Size(constraints.maxWidth, contentHeight),
                  painter: _PathPainter(
                    nodeCount: topics.length,
                    centerX: centerX,
                    completedFlags: <bool>[
                      for (final TopicNode t in topics) t.status == TopicNodeStatus.completed,
                    ],
                    accent: accent,
                    inactiveColor: Theme.of(context)
                        .extension<AppSemanticColors>()!
                        .border,
                  ),
                ),
                for (int i = 0; i < topics.length; i++)
                  Positioned(
                    top: i * _kRowHeight,
                    left: centerX + _laneOffset(i) - _kNodeSize / 2,
                    width: _kNodeSize + 48,
                    child: Center(
                      child: TopicNodeWidget(
                        topic: topics[i],
                        accentColor: accent,
                        size: _kNodeSize,
                        onTap: () => _openTopic(context, topics[i]),
                      ),
                    ).animate().fadeIn(delay: (i * 60).ms, duration: 300.ms).slideY(begin: 0.08, end: 0),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Alternating left/right nudge, symmetric around the lane's own
  /// center, so the path winds evenly around the middle of the screen
  /// instead of drifting toward one edge.
  double _laneOffset(int index) => (index.isEven ? -1 : 1) * _kNodeOffset;

  void _openTopic(BuildContext context, TopicNode topic) {
    final String? nextLessonId = _firstIncompleteLessonId(topic);

    // A topic whose lessons are all done, but which still has an
    // un-started mini-project, opens the project directly.
    if (nextLessonId == null && topic.miniProjectId != null) {
      context.push(AppRoutes.miniProjectPath(topic.miniProjectId!, topicId: topic.id));
      return;
    }

    if (nextLessonId != null) {
      context.push(
        AppRoutes.lessonPath(nextLessonId, courseId: topic.courseId, topicId: topic.id),
      );
    } else if (topic.miniProjectId != null) {
      context.push(AppRoutes.miniProjectPath(topic.miniProjectId!, topicId: topic.id));
    }
  }

  /// The first lesson in [topic] the user hasn't completed yet, so
  /// re-opening a topic resumes progress instead of restarting lesson 1
  /// every time. Returns null once every lesson in the topic is done.
  String? _firstIncompleteLessonId(TopicNode topic) {
    for (final String lessonId in topic.lessonIds) {
      if (!completedLessonIds.contains(lessonId)) {
        return lessonId;
      }
    }
    return null;
  }
}

/// Paints the smooth connecting path between topic nodes, following the
/// same alternating offsets used to position the nodes themselves so
/// each segment visually starts and ends exactly at a node's center.
class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.nodeCount,
    required this.centerX,
    required this.completedFlags,
    required this.accent,
    required this.inactiveColor,
  });

  final int nodeCount;
  final double centerX;
  final List<bool> completedFlags;
  final Color accent;
  final Color inactiveColor;

  double _xFor(int index) => centerX + (index.isEven ? -1 : 1) * _kNodeOffset;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount < 2) return;

    for (int i = 0; i < nodeCount - 1; i++) {
      final Offset start = Offset(_xFor(i), i * _kRowHeight + _kNodeSize / 2);
      final Offset end = Offset(_xFor(i + 1), (i + 1) * _kRowHeight + _kNodeSize / 2);
      final bool completed = completedFlags[i];

      final Paint paint = Paint()
        ..color = completed ? accent : inactiveColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final Path path = Path()..moveTo(start.dx, start.dy);
      final double midY = (start.dy + end.dy) / 2;
      path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount ||
        oldDelegate.centerX != centerX ||
        oldDelegate.accent != accent ||
        oldDelegate.inactiveColor != inactiveColor ||
        !_listEquals(oldDelegate.completedFlags, completedFlags);
  }

  bool _listEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
