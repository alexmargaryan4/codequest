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

  // Intentionally `ref.read`, not `ref.watch`: this provider must resolve
  // once per lesson attempt and then stay stable for the lifetime of that
  // attempt. Completing the lesson updates userProgressProvider (XP,
  // completedLessonIds, streak...); if we watched it here, that update
  // would rebuild this FutureProvider mid-completion, hand LessonScreen a
  // brand-new Lesson instance, and — since lessonSessionProvider is keyed
  // by that Lesson object's identity — silently spin up a fresh session
  // with exerciseIndex back at 0. That's what made a just-finished lesson
  // appear to "restart" instead of showing the completion screen. Reading
  // the progress snapshot here (for adaptive difficulty) doesn't need a
  // live subscription — it's only used the moment the lesson is built.
  final UserProgress progress =
      ref.read(userProgressProvider).valueOrNull ?? const UserProgress();

  return ref.watch(lessonRepositoryProvider).getLesson(
        courseId: request.courseId,
        courseTitle: courseTitle,
        topicId: request.topicId,
        topicTitle: topicTitle,
        baseDifficulty: LessonDifficulty.beginner,
        userProgress: progress,
      );
});
