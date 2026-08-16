import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../models/course.dart';
import '../../../models/daily_challenge.dart';
import '../../../models/user_progress.dart';
import '../../../repositories/course_repository.dart';

/// Resolves today's [DailyChallenge], picking a focus topic from the
/// user's active course (preferring a struggling topic if the adaptive
/// engine has flagged one, otherwise the current/next topic) so the
/// challenge feels relevant rather than random.
///
/// Note: this re-runs whenever [userProgressProvider] emits (e.g. after
/// `awardXp`), but [DailyChallengeRepository.getTodayChallenge] serves
/// from its local cache once today's challenge has been generated, so a
/// re-run after the first resolve is a cheap cache hit rather than a
/// fresh AI call or a visible reload.
final FutureProvider<DailyChallenge> dailyChallengeProvider =
    FutureProvider<DailyChallenge>((Ref ref) async {
  final UserProgress progress = ref.watch(userProgressProvider).valueOrNull ?? const UserProgress();

  final CourseRepository courseRepo = ref.watch(courseRepositoryProvider);
  final Course? course = await courseRepo.getCourse(progress.activeCourseId);
  final Course? resolved = course != null ? courseRepo.resolveStatuses(course, progress) : null;

  String topicId = progress.activeCourseId;
  String topicTitle = course?.title ?? 'Programming';

  if (resolved != null && resolved.topics.isNotEmpty) {
    if (progress.strugglingTopics.isNotEmpty) {
      final String struggling = progress.strugglingTopics.first;
      final TopicNode? match =
          resolved.topics.firstWhereOrNull((TopicNode t) => t.id == struggling);
      if (match != null) {
        topicId = match.id;
        topicTitle = match.title;
      }
    } else {
      final TopicNode? current = resolved.topics.firstWhereOrNull(
        (TopicNode t) =>
            t.status == TopicNodeStatus.available || t.status == TopicNodeStatus.inProgress,
      );
      if (current != null) {
        topicId = current.id;
        topicTitle = current.title;
      }
    }
  }

  return ref.watch(dailyChallengeRepositoryProvider).getTodayChallenge(
        userProgress: progress,
        topicTitle: topicTitle,
        topicId: topicId,
      );
});
