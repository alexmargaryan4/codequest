import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../models/course.dart';
import '../../../models/lesson.dart';
import '../../../models/user_progress.dart';
import '../../../repositories/course_repository.dart';

class LessonRequest {
  const LessonRequest({required this.lessonId, required this.courseId, required this.topicId});
  final String lessonId;
  final String courseId;
  final String topicId;

  @override
  bool operator ==(Object other) =>
      other is LessonRequest &&
      other.lessonId == lessonId &&
      other.courseId == courseId &&
      other.topicId == topicId;

  @override
  int get hashCode => Object.hash(lessonId, courseId, topicId);
}

/// Resolves the [Lesson] to display for a given request: goes through
/// [LessonRepository] (cache → AI → bundled fallback per the product
/// spec) with the course title and topic title looked up from the
/// course map so the AI prompt has real context.
final FutureProviderFamily<Lesson, LessonRequest> lessonProvider =
    FutureProvider.family<Lesson, LessonRequest>((Ref ref, LessonRequest request) async {
  final CourseRepository courseRepo = ref.watch(courseRepositoryProvider);
  final Course? course = await courseRepo.getCourse(request.courseId);
  final String courseTitle = course?.title ?? request.courseId;
  final String topicTitle = course?.topics
          .where((TopicNode t) => t.id == request.topicId)
          .map((TopicNode t) => t.title)
          .firstOrNull ??
      request.topicId;

  final UserProgress progress =
      ref.watch(userProgressProvider).valueOrNull ?? const UserProgress();

  return ref.watch(lessonRepositoryProvider).getLesson(
        courseId: request.courseId,
        courseTitle: courseTitle,
        topicId: request.topicId,
        topicTitle: topicTitle,
        baseDifficulty: LessonDifficulty.beginner,
        userProgress: progress,
      );
});
