import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/achievement.dart';
import '../models/user_progress.dart';

/// Loads achievement definitions from bundled JSON and evaluates which
/// ones a given [UserProgress] has newly earned.
///
/// Adding a new achievement is a pure data change (edit
/// assets/data/achievements/achievements.json) as long as its unlock
/// condition fits one of the existing [AchievementTrigger] evaluators —
/// no Dart code changes required.
class AchievementRepository {
  AchievementRepository();

  List<Achievement>? _cache;

  Future<List<Achievement>> loadAll() async {
    if (_cache != null) return _cache!;
    final String raw =
        await rootBundle.loadString('assets/data/achievements/achievements.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((dynamic e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// Returns achievements that [progress] newly qualifies for but hasn't
  /// unlocked yet. Callers should unlock + award XP for each, then
  /// persist via ProgressRepository.unlockAchievement.
  Future<List<Achievement>> evaluateNewlyUnlocked(UserProgress progress) async {
    final List<Achievement> all = await loadAll();
    final List<Achievement> newlyUnlocked = <Achievement>[];

    for (final Achievement a in all) {
      if (progress.unlockedAchievementIds.contains(a.id)) continue;
      if (_isSatisfied(a, progress)) {
        newlyUnlocked.add(a);
      }
    }
    return newlyUnlocked;
  }

  bool _isSatisfied(Achievement a, UserProgress progress) {
    switch (a.trigger) {
      case AchievementTrigger.streakDays:
        return progress.currentStreak >= a.threshold;
      case AchievementTrigger.lessonsCompleted:
        return progress.lessonsCompleted >= a.threshold;
      case AchievementTrigger.projectsCompleted:
        return progress.projectsCompleted >= a.threshold;
      case AchievementTrigger.levelReached:
        return progress.level >= a.threshold;
      case AchievementTrigger.perfectLessons:
        // Approximated via lessonsCompleted for now; a dedicated counter
        // can be added to UserProgress if perfect-lesson tracking needs
        // to be exact rather than approximate.
        return false;
      case AchievementTrigger.topicMastered:
        return progress.masteredTopics.isNotEmpty;
      case AchievementTrigger.coursesStarted:
        return false;
      case AchievementTrigger.custom:
        return false;
    }
  }
}
