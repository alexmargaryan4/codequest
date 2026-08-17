import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/achievement_repository.dart';
import '../../repositories/cosmetics_repository.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/daily_challenge_repository.dart';
import '../../repositories/daily_chest_repository.dart';
import '../../repositories/duel_repository.dart';
import '../../repositories/gems_repository.dart';
import '../../repositories/hearts_repository.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/pet_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/weekly_quest_repository.dart';
import '../../repositories/weekly_report_repository.dart';
import '../../services/adaptive_engine.dart';
import '../../services/ai/ai_service.dart';
import '../../services/chest_service.dart';
import '../../services/cosmetics_service.dart';
import '../../services/duel_service.dart';
import '../../services/gems_service.dart';
import '../../services/hearts_service.dart';
import '../../services/lesson_engine/hint_service.dart';
import '../../services/pet_service.dart';
import '../../services/progress_service.dart';
import '../../services/quest_service.dart';
import '../../services/weekly_report_service.dart';

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
  return ProgressService(
    repository: ref.watch(progressRepositoryProvider),
    courseRepository: ref.watch(courseRepositoryProvider),
    gemsService: ref.watch(gemsServiceProvider),
  );
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

final Provider<HeartsRepository> heartsRepositoryProvider = Provider<HeartsRepository>((Ref ref) {
  return HeartsRepository();
});

final Provider<GemsRepository> gemsRepositoryProvider = Provider<GemsRepository>((Ref ref) {
  return GemsRepository();
});

final Provider<WeeklyQuestRepository> weeklyQuestRepositoryProvider =
    Provider<WeeklyQuestRepository>((Ref ref) {
  return WeeklyQuestRepository();
});

final Provider<HeartsService> heartsServiceProvider = Provider<HeartsService>((Ref ref) {
  return HeartsService(
    repository: ref.watch(heartsRepositoryProvider),
    gemsRepository: ref.watch(gemsRepositoryProvider),
  );
});

final Provider<GemsService> gemsServiceProvider = Provider<GemsService>((Ref ref) {
  return GemsService(repository: ref.watch(gemsRepositoryProvider));
});

final Provider<QuestService> questServiceProvider = Provider<QuestService>((Ref ref) {
  return QuestService(
    repository: ref.watch(weeklyQuestRepositoryProvider),
    gemsRepository: ref.watch(gemsRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});

final Provider<DailyChestRepository> dailyChestRepositoryProvider =
    Provider<DailyChestRepository>((Ref ref) {
  return DailyChestRepository();
});

final Provider<ChestService> chestServiceProvider = Provider<ChestService>((Ref ref) {
  return ChestService(
    repository: ref.watch(dailyChestRepositoryProvider),
    gemsRepository: ref.watch(gemsRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});

final Provider<PetRepository> petRepositoryProvider = Provider<PetRepository>((Ref ref) {
  return PetRepository();
});

final Provider<PetService> petServiceProvider = Provider<PetService>((Ref ref) {
  return PetService(repository: ref.watch(petRepositoryProvider));
});

final Provider<DuelRepository> duelRepositoryProvider = Provider<DuelRepository>((Ref ref) {
  return DuelRepository();
});

final Provider<DuelService> duelServiceProvider = Provider<DuelService>((Ref ref) {
  return DuelService(
    repository: ref.watch(duelRepositoryProvider),
    gemsRepository: ref.watch(gemsRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});

final Provider<CosmeticsRepository> cosmeticsRepositoryProvider =
    Provider<CosmeticsRepository>((Ref ref) {
  return CosmeticsRepository();
});

final Provider<CosmeticsService> cosmeticsServiceProvider = Provider<CosmeticsService>((Ref ref) {
  return CosmeticsService(
    repository: ref.watch(cosmeticsRepositoryProvider),
    gemsRepository: ref.watch(gemsRepositoryProvider),
  );
});

final Provider<WeeklyReportRepository> weeklyReportRepositoryProvider =
    Provider<WeeklyReportRepository>((Ref ref) {
  return WeeklyReportRepository();
});

final Provider<WeeklyReportService> weeklyReportServiceProvider =
    Provider<WeeklyReportService>((Ref ref) {
  return WeeklyReportService(
    repository: ref.watch(weeklyReportRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});
