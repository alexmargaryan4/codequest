import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../models/course.dart';
import '../../../models/user_progress.dart';

/// Resolves the user's currently active course (with live topic statuses)
/// for display on the home screen's "continue learning" map preview.
final FutureProvider<Course?> activeCourseProvider = FutureProvider<Course?>((Ref ref) async {
  final UserProgress? progress = ref.watch(userProgressProvider).valueOrNull;
  if (progress == null) return null;

  final Course? course =
      await ref.watch(courseRepositoryProvider).getCourse(progress.activeCourseId);
  if (course == null) return null;

  return ref.watch(courseRepositoryProvider).resolveStatuses(course, progress);
});

/// The next lesson-worthy topic node (first "available" status) in the
/// active course — surfaced as the home screen's primary "continue"
/// call-to-action.
final FutureProvider<TopicNode?> nextTopicProvider = FutureProvider<TopicNode?>((Ref ref) async {
  final Course? course = await ref.watch(activeCourseProvider.future);
  if (course == null || course.topics.isEmpty) return null;
  for (final TopicNode t in course.topics) {
    if (t.status == TopicNodeStatus.available || t.status == TopicNodeStatus.inProgress) {
      return t;
    }
  }
  return null;
});
