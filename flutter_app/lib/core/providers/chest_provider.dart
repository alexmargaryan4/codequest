import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/daily_chest.dart';
import '../../services/chest_service.dart';
import 'core_providers.dart';
import 'gems_provider.dart';
import 'progress_provider.dart';

class ChestNotifier extends StateNotifier<AsyncValue<DailyChestState>> {
  ChestNotifier({required ChestService chestService, required Ref ref})
      : _chestService = chestService,
        _ref = ref,
        super(const AsyncValue<DailyChestState>.loading()) {
    _load();
  }

  final ChestService _chestService;
  final Ref _ref;

  Future<void> _load() async {
    try {
      final DailyChestState state = await _chestService.loadState();
      this.state = AsyncValue<DailyChestState>.data(state);
    } catch (e, st) {
      state = AsyncValue<DailyChestState>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  /// Opens today's chest and returns the rolled reward, or null if it
  /// was already opened today. The reveal screen is responsible for
  /// showing [ChestRewardResult] to the user; this only handles state.
  Future<ChestRewardResult?> open() async {
    final ChestOpenResult result = await _chestService.openToday();
    if (!result.success) return null;

    state = AsyncValue<DailyChestState>.data(result.state);
    // Rewards can touch gems, XP, or perks — refresh the providers that
    // display those so balances stay in sync across the app.
    unawaited(_ref.read(gemsProvider.notifier).refresh());
    unawaited(_ref.read(userProgressProvider.notifier).refresh());
    return result.reward;
  }
}

final StateNotifierProvider<ChestNotifier, AsyncValue<DailyChestState>> chestProvider =
    StateNotifierProvider<ChestNotifier, AsyncValue<DailyChestState>>((Ref ref) {
  return ChestNotifier(chestService: ref.watch(chestServiceProvider), ref: ref);
});
