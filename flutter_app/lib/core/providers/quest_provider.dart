import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/weekly_quest.dart';
import '../../services/quest_service.dart';
import 'core_providers.dart';
import 'gems_provider.dart';
import 'progress_provider.dart';

class QuestsNotifier extends StateNotifier<AsyncValue<List<WeeklyQuest>>> {
  QuestsNotifier({required QuestService questService, required Ref ref})
      : _questService = questService,
        _ref = ref,
        super(const AsyncValue<List<WeeklyQuest>>.loading()) {
    _load();
  }

  final QuestService _questService;
  final Ref _ref;

  Future<void> _load() async {
    try {
      final List<WeeklyQuest> quests = await _questService.loadCurrentWeek();
      state = AsyncValue<List<WeeklyQuest>>.data(quests);
    } catch (e, st) {
      state = AsyncValue<List<WeeklyQuest>>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  /// Most-recently-completed quests from the last [recordProgress] call,
  /// exposed for the UI to show a one-shot "quest complete!" toast.
  List<WeeklyQuest> lastNewlyCompleted = const <WeeklyQuest>[];

  Future<void> recordProgress({required QuestMetric metric, required int amount}) async {
    final QuestProgressResult result =
        await _questService.recordProgress(metric: metric, amount: amount);
    state = AsyncValue<List<WeeklyQuest>>.data(result.quests);
    lastNewlyCompleted = result.newlyCompleted;
  }

  void clearNewlyCompleted() {
    lastNewlyCompleted = const <WeeklyQuest>[];
  }

  Future<void> claimReward(WeeklyQuest quest) async {
    final WeeklyQuest claimed = await _questService.claimReward(quest);
    final List<WeeklyQuest>? current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue<List<WeeklyQuest>>.data(<WeeklyQuest>[
        for (final WeeklyQuest q in current)
          if (q.id == claimed.id) claimed else q,
      ]);
    }
    // Claiming awards gems (and sometimes XP) directly via the
    // repositories inside QuestService — refresh the dependent
    // providers so balances/XP shown elsewhere stay accurate.
    unawaited(_ref.read(gemsProvider.notifier).refresh());
    unawaited(_ref.read(userProgressProvider.notifier).refresh());
  }
}

final StateNotifierProvider<QuestsNotifier, AsyncValue<List<WeeklyQuest>>> weeklyQuestsProvider =
    StateNotifierProvider<QuestsNotifier, AsyncValue<List<WeeklyQuest>>>((Ref ref) {
  return QuestsNotifier(questService: ref.watch(questServiceProvider), ref: ref);
});
