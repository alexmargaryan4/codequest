import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/achievement_repository.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/daily_challenge_repository.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../services/adaptive_engine.dart';
import '../../services/ai/ai_service.dart';
import '../../services/lesson_engine/hint_service.dart';
import '../../services/progress_service.dart';

/// Single shared [AIService] instance — owns provider fallback state
/// (cooldowns, health tracking) for the whole app lifetime.
final Provider<AIService> aiServiceProvider = Provider<AIService>((Ref ref) {
  return AIService();
});

final Provider<AdaptiveEngine> adaptiveEngineProvider = Provider<AdaptiveEngine>((Ref ref) {
  return const AdaptiveEngine();
});

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>((Ref ref) {
  return ProgressRepository();
});

final Provider<ProgressService> progressServiceProvider = Provider<ProgressService>((Ref ref) {
  return ProgressService(repository: ref.watch(progressRepositoryProvider));
});

final Provider<LessonRepository> lessonRepositoryProvider = Provider<LessonRepository>((Ref ref) {
  return LessonRepository(
    aiService: ref.watch(aiServiceProvider),
    adaptiveEngine: ref.watch(adaptiveEngineProvider),
  );
});

final Provider<HintService> hintServiceProvider = Provider<HintService>((Ref ref) {
  return HintService(aiService: ref.watch(aiServiceProvider));
});

final Provider<CourseRepository> courseRepositoryProvider = Provider<CourseRepository>((Ref ref) {
  return CourseRepository();
});

final Provider<LeaderboardRepository> leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((Ref ref) {
  return const LeaderboardRepository();
});

final Provider<AchievementRepository> achievementRepositoryProvider =
    Provider<AchievementRepository>((Ref ref) {
  return AchievementRepository();
});

final Provider<DailyChallengeRepository> dailyChallengeRepositoryProvider =
    Provider<DailyChallengeRepository>((Ref ref) {
  return DailyChallengeRepository(aiService: ref.watch(aiServiceProvider));
});
