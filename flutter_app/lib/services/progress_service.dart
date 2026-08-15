import '../core/constants/xp_constants.dart';
import '../models/user_progress.dart';
import '../repositories/progress_repository.dart';

/// Outcome of an XP-awarding action, used by the UI layer to trigger the
/// right celebratory animation (XP popup vs full level-up sequence).
class XpAwardResult {
  const XpAwardResult({
    required this.progress,
    required this.xpGained,
    required this.leveledUp,
    this.newLevel,
  });

  final UserProgress progress;
  final int xpGained;
  final bool leveledUp;
  final int? newLevel;
}

/// Encapsulates all XP / level / streak business rules on top of
/// [ProgressRepository]. UI and feature code should go through this
/// service rather than mutating [UserProgress] directly.
class ProgressService {
  ProgressService({required ProgressRepository repository}) : _repository = repository;

  final ProgressRepository _repository;

  Future<UserProgress> loadProgress() => _repository.load();

  /// Awards [xp] to the user, updates streak based on today's date, and
  /// persists the result. Returns enough info for the UI to show the
  /// right animation.
  Future<XpAwardResult> awardXp(int xp, {UserProgress? current}) async {
    final UserProgress before = current ?? await _repository.load();
    final int previousLevel = before.level;

    final UserProgress withStreak = _applyDailyStreak(before);
    final UserProgress updated = withStreak.copyWith(totalXp: withStreak.totalXp + xp);

    await _repository.saveCore(updated);

    final int newLevel = updated.level;
    return XpAwardResult(
      progress: updated,
      xpGained: xp,
      leveledUp: newLevel > previousLevel,
      newLevel: newLevel > previousLevel ? newLevel : null,
    );
  }

  /// Updates streak counters based on [lastActivityDate] vs today, without
  /// awarding XP. Call this on app resume / home screen load so the streak
  /// reflects reality even before the user does anything today.
  Future<UserProgress> refreshStreakOnly() async {
    final UserProgress current = await _repository.load();
    final UserProgress updated = _applyDailyStreak(current);
    if (updated.currentStreak != current.currentStreak) {
      await _repository.saveCore(updated);
    }
    return updated;
  }

  UserProgress _applyDailyStreak(UserProgress progress) {
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
      // Missed one or more days — streak resets.
      return progress.copyWith(currentStreak: 1, lastActivityDate: today);
    }
  }

  Future<UserProgress> completeLesson({
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

    final UserProgress withStreak = _applyDailyStreak(current);
    final UserProgress updated = withStreak.copyWith(
      totalXp: withStreak.totalXp + xp,
      lessonsCompleted: withStreak.lessonsCompleted + 1,
      completedLessonIds: <String>{...withStreak.completedLessonIds, lessonId},
    );
    await _repository.saveCore(updated);
    return updated;
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

  Future<UserProgress> completeMiniProject({
    required String projectId,
    required String topicId,
    int xpReward = XpRewards.miniProjectComplete,
  }) async {
    await _repository.markProjectCompleted(projectId: projectId, topicId: topicId);
    final UserProgress current = await _repository.load();
    final UserProgress withStreak = _applyDailyStreak(current);
    final UserProgress updated = withStreak.copyWith(
      totalXp: withStreak.totalXp + xpReward,
      projectsCompleted: withStreak.projectsCompleted + 1,
      completedProjectIds: <String>{...withStreak.completedProjectIds, projectId},
    );
    await _repository.saveCore(updated);
    return updated;
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
}
