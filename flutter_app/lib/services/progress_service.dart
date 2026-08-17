import '../core/constants/xp_constants.dart'; // includes StreakMultiplier
import '../models/course.dart';
import '../models/user_progress.dart';
import '../repositories/course_repository.dart';
import '../repositories/progress_repository.dart';
import 'gems_service.dart';

/// Outcome of an XP-awarding action, used by the UI layer to trigger the
/// right celebratory animation (XP popup vs full level-up sequence).
class XpAwardResult {
  const XpAwardResult({
    required this.progress,
    required this.xpGained,
    required this.leveledUp,
    this.newLevel,
    this.baseXp = 0,
  });

  final UserProgress progress;

  /// The actual XP added to `totalXp`, after the streak multiplier.
  final int xpGained;
  final bool leveledUp;
  final int? newLevel;

  /// The pre-multiplier XP amount, exposed so callers that also need to
  /// feed the pet companion or duel score can choose whether to use the
  /// boosted or base amount (both currently use [xpGained]).
  final int baseXp;
}

/// Outcome of [ProgressService.completeLesson]/`completeMiniProject`,
/// carrying the actual (post streak-multiplier) XP awarded alongside
/// the updated progress — needed so callers that also feed the pet
/// companion or duel score use the real amount, not a hardcoded guess.
class CompletionResult {
  const CompletionResult({required this.progress, required this.xpGained});
  final UserProgress progress;
  final int xpGained;
}

/// Encapsulates all XP / level / streak business rules on top of
/// [ProgressRepository]. UI and feature code should go through this
/// service rather than mutating [UserProgress] directly.
class ProgressService {
  ProgressService({
    required ProgressRepository repository,
    CourseRepository? courseRepository,
    GemsService? gemsService,
  })  : _repository = repository,
        _courseRepository = courseRepository ?? CourseRepository(),
        _gemsService = gemsService;

  final ProgressRepository _repository;
  final CourseRepository _courseRepository;

  /// Optional so existing tests/call sites that don't care about the
  /// streak-freeze perk keep working without wiring it up. When absent,
  /// a missed day always resets the streak (previous behavior).
  final GemsService? _gemsService;

  Future<UserProgress> loadProgress() => _repository.load();

  /// Awards [xp] to the user, updates streak based on today's date, and
  /// persists the result. Returns enough info for the UI to show the
  /// right animation.
  Future<XpAwardResult> awardXp(int xp, {UserProgress? current}) async {
    final UserProgress before = current ?? await _repository.load();
    final int previousLevel = before.level;

    final UserProgress withStreak = await _applyDailyStreak(before);
    final int multipliedXp = _applyStreakMultiplier(xp, withStreak.currentStreak);
    final UserProgress updated =
        withStreak.copyWith(totalXp: withStreak.totalXp + multipliedXp);

    await _repository.saveCore(updated);

    final int newLevel = updated.level;
    return XpAwardResult(
      progress: updated,
      xpGained: multipliedXp,
      leveledUp: newLevel > previousLevel,
      newLevel: newLevel > previousLevel ? newLevel : null,
      baseXp: xp,
    );
  }

  /// Scales [baseXp] by the current streak's XP multiplier (see
  /// [StreakMultiplier]), rounding to the nearest whole XP point.
  int _applyStreakMultiplier(int baseXp, int streakDays) {
    if (baseXp <= 0) return baseXp;
    final double multiplier = StreakMultiplier.forStreak(streakDays);
    if (multiplier == 1.0) return baseXp;
    return (baseXp * multiplier).round();
  }

  /// Updates streak counters based on [lastActivityDate] vs today, without
  /// awarding XP. Call this on app resume / home screen load so the streak
  /// reflects reality even before the user does anything today.
  Future<UserProgress> refreshStreakOnly() async {
    final UserProgress current = await _repository.load();
    final UserProgress updated = await _applyDailyStreak(current);
    if (updated.currentStreak != current.currentStreak) {
      await _repository.saveCore(updated);
    }
    return updated;
  }

  /// Applies the day-over-day streak transition. When one or more days
  /// were missed, first gives an available streak-freeze charge (see
  /// [GemsService.consumeStreakFreezeIfAvailable]) a chance to preserve
  /// the streak instead of resetting it — consuming the charge in the
  /// process so it only ever saves a single missed day.
  Future<UserProgress> _applyDailyStreak(UserProgress progress) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? last = progress.lastActivityDate;
    if (last == null) {
      return progress.copyWith(
        currentStreak: 1,
        longestStreak: progress.longestStreak < 1 ? 1 : progress.longestStreak,
        lastActivityDate: today,
      );
    }

    final DateTime lastDay = DateTime(last.year, last.month, last.day);
    final int dayDiff = today.difference(lastDay).inDays;

    if (dayDiff == 0) {
      // Already active today — no streak change.
      return progress;
    } else if (dayDiff == 1) {
      final int newStreak = progress.currentStreak + 1;
      return progress.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > progress.longestStreak ? newStreak : progress.longestStreak,
        lastActivityDate: today,
      );
    } else {
      // Missed one or more days — try to spend a streak freeze before
      // resetting. A freeze covers the gap and continues the streak as
      // if today were the very next day.
      final bool saved = _gemsService != null &&
          await _gemsService.consumeStreakFreezeIfAvailable();
      if (saved) {
        final int newStreak = progress.currentStreak + 1;
        return progress.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > progress.longestStreak ? newStreak : progress.longestStreak,
          lastActivityDate: today,
        );
      }
      return progress.copyWith(currentStreak: 1, lastActivityDate: today);
    }
  }

  Future<CompletionResult> completeLesson({
    required String lessonId,
    required String topicId,
    required String courseId,
    required bool wasPerfect,
  }) async {
    await _repository.markLessonCompleted(
      lessonId: lessonId,
      topicId: topicId,
      courseId: courseId,
      wasPerfect: wasPerfect,
    );

    final UserProgress current = await _repository.load();
    int xp = XpRewards.lessonComplete;
    if (wasPerfect) xp += XpRewards.perfectLessonBonus;

    final UserProgress withStreak = await _applyDailyStreak(current);
    final int multipliedXp = _applyStreakMultiplier(xp, withStreak.currentStreak);
    final UserProgress updated = withStreak.copyWith(
      totalXp: withStreak.totalXp + multipliedXp,
      lessonsCompleted: withStreak.lessonsCompleted + 1,
      completedLessonIds: <String>{...withStreak.completedLessonIds, lessonId},
    );
    await _repository.saveCore(updated);
    final UserProgress finalProgress =
        await _maybeCompleteTopic(topicId: topicId, courseId: courseId, progress: updated);
    return CompletionResult(progress: finalProgress, xpGained: multipliedXp);
  }

  Future<UserProgress> completeTopic({required String topicId, required String courseId}) async {
    await _repository.markTopicCompleted(topicId: topicId, courseId: courseId);
    final UserProgress current = await _repository.load();
    final UserProgress updated = current.copyWith(
      completedTopicIds: <String>{...current.completedTopicIds, topicId},
    );
    await _repository.saveCore(updated);
    return updated;
  }

  Future<CompletionResult> completeMiniProject({
    required String projectId,
    required String topicId,
    int xpReward = XpRewards.miniProjectComplete,
  }) async {
    await _repository.markProjectCompleted(projectId: projectId, topicId: topicId);
    final UserProgress current = await _repository.load();
    final UserProgress withStreak = await _applyDailyStreak(current);
    final int multipliedXp = _applyStreakMultiplier(xpReward, withStreak.currentStreak);
    final UserProgress updated = withStreak.copyWith(
      totalXp: withStreak.totalXp + multipliedXp,
      projectsCompleted: withStreak.projectsCompleted + 1,
      completedProjectIds: <String>{...withStreak.completedProjectIds, projectId},
    );
    await _repository.saveCore(updated);
    final TopicNode? topic = await _findTopic(topicId);
    final UserProgress finalProgress = await _maybeCompleteTopic(
      topicId: topicId,
      courseId: topic?.courseId ?? '',
      progress: updated,
    );
    return CompletionResult(progress: finalProgress, xpGained: multipliedXp);
  }

  Future<void> recordExerciseAttempt({
    required String topicId,
    required bool wasCorrect,
    required bool usedHint,
    required int timeSeconds,
  }) {
    return _repository.recordExerciseAttempt(
      topicId: topicId,
      wasCorrect: wasCorrect,
      usedHint: usedHint,
      timeSeconds: timeSeconds,
    );
  }

  Future<UserProgress> setActiveCourse(String courseId) async {
    final UserProgress current = await _repository.load();
    final UserProgress updated = current.copyWith(activeCourseId: courseId);
    await _repository.saveCore(updated);
    return updated;
  }

  /// Looks up a topic by id across every bundled course.
  Future<TopicNode?> _findTopic(String topicId) async {
    final Course? course = await _courseRepository.getCourseForTopic(topicId);
    if (course == null) return null;
    for (final TopicNode t in course.topics) {
      if (t.id == topicId) return t;
    }
    return null;
  }

  /// Marks [topicId] as completed once every lesson AND the mini-project
  /// (when the topic has one) it owns are done. This is what actually
  /// unlocks the next topic on the course map — without it, topics with
  /// [prerequisiteTopicIds] set stay locked forever, and a topic with a
  /// single lesson looks like it "restarts" because it never advances
  /// past itself.
  Future<UserProgress> _maybeCompleteTopic({
    required String topicId,
    required String courseId,
    required UserProgress progress,
  }) async {
    if (progress.completedTopicIds.contains(topicId)) return progress;

    final TopicNode? topic = await _findTopic(topicId);
    if (topic == null) return progress;

    final bool allLessonsDone =
        topic.lessonIds.every(progress.completedLessonIds.contains);
    final bool projectDone = topic.miniProjectId == null ||
        progress.completedProjectIds.contains(topic.miniProjectId);

    if (!allLessonsDone || !projectDone) return progress;

    await _repository.markTopicCompleted(topicId: topicId, courseId: topic.courseId);
    final UserProgress reloaded = await _repository.load();
    final UserProgress updated = reloaded.copyWith(
      completedTopicIds: <String>{...reloaded.completedTopicIds, topicId},
    );
    await _repository.saveCore(updated);
    return updated;
  }
}
