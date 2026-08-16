import '../models/weekly_quest.dart';
import '../repositories/gems_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/weekly_quest_repository.dart';

/// One-shot result describing quests that just crossed their target as
/// a side effect of [QuestService.recordProgress], so the UI can show a
/// "quest complete" toast without polling.
class QuestProgressResult {
  const QuestProgressResult({required this.quests, required this.newlyCompleted});
  final List<WeeklyQuest> quests;
  final List<WeeklyQuest> newlyCompleted;
}

/// Encapsulates weekly-quest business rules: fetching this week's set,
/// incrementing progress against a metric, and claiming rewards.
/// Quest *completion* (crossing the target) is separate from *claiming*
/// (awarding gems/XP) so the UI can show a distinct "claim" moment
/// rather than silently crediting rewards in the background.
class QuestService {
  QuestService({
    required WeeklyQuestRepository repository,
    required GemsRepository gemsRepository,
    required ProgressRepository progressRepository,
  })  : _repository = repository,
        _gemsRepository = gemsRepository,
        _progressRepository = progressRepository;

  final WeeklyQuestRepository _repository;
  final GemsRepository _gemsRepository;
  final ProgressRepository _progressRepository;

  String get currentWeekKey => WeeklyQuestRepository.weekKeyFor(DateTime.now());

  Future<List<WeeklyQuest>> loadCurrentWeek() {
    return _repository.loadForWeek(currentWeekKey);
  }

  /// Increments progress for every active quest tracking [metric] by
  /// [amount]. Safe to call frequently (e.g. once per exercise) — quests
  /// that don't track this metric, or are already completed, are
  /// skipped cheaply.
  Future<QuestProgressResult> recordProgress({
    required QuestMetric metric,
    required int amount,
  }) async {
    if (amount <= 0) {
      final List<WeeklyQuest> quests = await loadCurrentWeek();
      return QuestProgressResult(quests: quests, newlyCompleted: const <WeeklyQuest>[]);
    }

    final List<WeeklyQuest> quests = await loadCurrentWeek();
    final List<WeeklyQuest> updated = <WeeklyQuest>[];
    final List<WeeklyQuest> newlyCompleted = <WeeklyQuest>[];

    for (final WeeklyQuest q in quests) {
      if (q.metric != metric || q.completed) {
        updated.add(q);
        continue;
      }
      final int newProgress = (q.progress + amount).clamp(0, q.target);
      final bool completedNow = newProgress >= q.target;
      final WeeklyQuest next = q.copyWith(progress: newProgress, completed: completedNow);
      await _repository.saveQuest(next);
      updated.add(next);
      if (completedNow) newlyCompleted.add(next);
    }

    return QuestProgressResult(quests: updated, newlyCompleted: newlyCompleted);
  }

  /// Claims a completed-but-unclaimed quest's rewards (gems + XP).
  /// Idempotent: claiming an already-claimed quest is a no-op that just
  /// returns the quest unchanged.
  Future<WeeklyQuest> claimReward(WeeklyQuest quest) async {
    if (!quest.completed || quest.isClaimed) return quest;

    if (quest.gemsReward > 0) {
      final gems = await _gemsRepository.load();
      await _gemsRepository.save(gems.copyWith(balance: gems.balance + quest.gemsReward));
    }
    if (quest.xpReward > 0) {
      final progress = await _progressRepository.load();
      await _progressRepository.saveCore(
        progress.copyWith(totalXp: progress.totalXp + quest.xpReward),
      );
    }

    final WeeklyQuest claimed = quest.copyWith(claimedAt: DateTime.now());
    await _repository.saveQuest(claimed);
    return claimed;
  }
}
