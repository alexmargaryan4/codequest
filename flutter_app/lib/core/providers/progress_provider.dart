import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/achievement.dart';
import '../../models/user_progress.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../services/progress_service.dart';
import 'core_providers.dart';
import 'duel_provider.dart';
import 'pet_provider.dart';

/// One-shot XP/level-up event the UI can listen to for celebratory
/// animations, without that data living permanently in [UserProgress].
class ProgressEvent {
  const ProgressEvent({
    required this.xpGained,
    required this.leveledUp,
    this.newLevel,
    this.newlyUnlockedAchievements = const <Achievement>[],
  });

  final int xpGained;
  final bool leveledUp;
  final int? newLevel;
  final List<Achievement> newlyUnlockedAchievements;
}

class UserProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  UserProgressNotifier({
    required ProgressService progressService,
    required AchievementRepository achievementRepository,
    required ProgressRepository progressRepository,
    required Ref ref,
  })  : _progressService = progressService,
        _achievementRepository = achievementRepository,
        _progressRepository = progressRepository,
        _ref = ref,
        super(const AsyncValue<UserProgress>.loading()) {
    _load();
  }

  final ProgressService _progressService;
  final AchievementRepository _achievementRepository;
  final ProgressRepository _progressRepository;
  final Ref _ref;

  /// Latest one-shot event (XP gain / level up / achievement unlock),
  /// exposed for UI listeners to consume and clear.
  ProgressEvent? lastEvent;

  Future<void> _load() async {
    try {
      final UserProgress progress = await _progressService.refreshStreakOnly();
      state = AsyncValue<UserProgress>.data(progress);
    } catch (e, st) {
      state = AsyncValue<UserProgress>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> awardXp(int xp) async {
    final UserProgress? current = state.valueOrNull;
    final result = await _progressService.awardXp(xp, current: current);
    await _checkAchievements(result.progress);
    lastEvent = ProgressEvent(
      xpGained: result.xpGained,
      leveledUp: result.leveledUp,
      newLevel: result.newLevel,
    );
    state = AsyncValue<UserProgress>.data(result.progress);
    _onXpGained(result.xpGained);
  }

  Future<void> completeLesson({
    required String lessonId,
    required String topicId,
    required String courseId,
    required bool wasPerfect,
  }) async {
    final CompletionResult result = await _progressService.completeLesson(
      lessonId: lessonId,
      topicId: topicId,
      courseId: courseId,
      wasPerfect: wasPerfect,
    );
    final List<Achievement> unlocked = await _checkAchievements(result.progress);
    lastEvent = ProgressEvent(
      xpGained: result.xpGained,
      leveledUp: false,
      newlyUnlockedAchievements: unlocked,
    );
    state = AsyncValue<UserProgress>.data(result.progress);
    _onXpGained(result.xpGained);
  }

  Future<void> completeTopic({required String topicId, required String courseId}) async {
    final UserProgress updated =
        await _progressService.completeTopic(topicId: topicId, courseId: courseId);
    state = AsyncValue<UserProgress>.data(updated);
  }

  Future<void> completeMiniProject({required String projectId, required String topicId}) async {
    final CompletionResult result = await _progressService.completeMiniProject(
      projectId: projectId,
      topicId: topicId,
    );
    final List<Achievement> unlocked = await _checkAchievements(result.progress);
    lastEvent = ProgressEvent(
      xpGained: result.xpGained,
      leveledUp: false,
      newlyUnlockedAchievements: unlocked,
    );
    state = AsyncValue<UserProgress>.data(result.progress);
    _onXpGained(result.xpGained);
  }

  Future<void> recordExerciseAttempt({
    required String topicId,
    required bool wasCorrect,
    required bool usedHint,
    required int timeSeconds,
  }) async {
    await _progressService.recordExerciseAttempt(
      topicId: topicId,
      wasCorrect: wasCorrect,
      usedHint: usedHint,
      timeSeconds: timeSeconds,
    );
  }

  Future<void> setActiveCourse(String courseId) async {
    final UserProgress updated = await _progressService.setActiveCourse(courseId);
    state = AsyncValue<UserProgress>.data(updated);
  }

  Future<List<Achievement>> _checkAchievements(UserProgress progress) async {
    final List<Achievement> newlyUnlocked =
        await _achievementRepository.evaluateNewlyUnlocked(progress);
    for (final Achievement a in newlyUnlocked) {
      await _progressRepository.unlockAchievement(a.id);
    }
    return newlyUnlocked;
  }

  /// Fans an XP gain out to the pet companion (grows 1:1 with XP) and
  /// today's duel (counts toward the score race), so every XP-awarding
  /// action feeds both without each call site needing to remember to.
  /// Fire-and-forget: both own their state independently via their own
  /// providers, same pattern as gems/hearts refresh elsewhere.
  void _onXpGained(int xp) {
    if (xp <= 0) return;
    unawaited(_ref.read(petProvider.notifier).feed(xp));
    unawaited(_ref.read(duelProvider.notifier).addScore(xp));
  }

  void clearEvent() {
    lastEvent = null;
  }
}

final StateNotifierProvider<UserProgressNotifier, AsyncValue<UserProgress>>
    userProgressProvider =
    StateNotifierProvider<UserProgressNotifier, AsyncValue<UserProgress>>((Ref ref) {
  return UserProgressNotifier(
    progressService: ref.watch(progressServiceProvider),
    achievementRepository: ref.watch(achievementRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    ref: ref,
  );
});
