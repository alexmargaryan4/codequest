import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/duel.dart';
import '../../services/duel_service.dart';
import 'core_providers.dart';
import 'gems_provider.dart';

class DuelNotifier extends StateNotifier<AsyncValue<Duel>> {
  DuelNotifier({required DuelService duelService, required Ref ref})
      : _duelService = duelService,
        _ref = ref,
        super(const AsyncValue<Duel>.loading()) {
    _load();
  }

  final DuelService _duelService;
  final Ref _ref;

  /// Set for one build cycle right after [addScore] causes the duel to
  /// be won, so the UI can show a one-shot "you won!" celebration.
  bool lastScoreCrossedWin = false;

  Future<void> _load() async {
    try {
      final Duel duel = await _duelService.loadOrCreateToday();
      await _duelService.settleIfExpired(duel);
      state = AsyncValue<Duel>.data(duel);
    } catch (e, st) {
      state = AsyncValue<Duel>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addScore(int points) async {
    final Duel? before = state.valueOrNull;
    final Duel updated = await _duelService.addScore(points);
    state = AsyncValue<Duel>.data(updated);
    lastScoreCrossedWin = (before?.won != true) && updated.won == true;
  }

  void clearWinFlag() {
    lastScoreCrossedWin = false;
  }

  Future<List<Duel>> loadHistory() => _duelService.loadHistory();

  Future<void> claimReward() async {
    final Duel? current = state.valueOrNull;
    if (current == null) return;
    final Duel claimed = await _duelService.claimReward(current);
    state = AsyncValue<Duel>.data(claimed);
    unawaited(_ref.read(gemsProvider.notifier).refresh());
  }
}

final StateNotifierProvider<DuelNotifier, AsyncValue<Duel>> duelProvider =
    StateNotifierProvider<DuelNotifier, AsyncValue<Duel>>((Ref ref) {
  return DuelNotifier(duelService: ref.watch(duelServiceProvider), ref: ref);
});
