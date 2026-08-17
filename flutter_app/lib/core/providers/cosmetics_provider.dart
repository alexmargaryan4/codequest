import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/rewards_constants.dart';
import '../../models/cosmetics_state.dart';
import '../../services/cosmetics_service.dart';
import 'core_providers.dart';
import 'gems_provider.dart';

class CosmeticsNotifier extends StateNotifier<AsyncValue<CosmeticsState>> {
  CosmeticsNotifier({required CosmeticsService cosmeticsService, required Ref ref})
      : _cosmeticsService = cosmeticsService,
        _ref = ref,
        super(const AsyncValue<CosmeticsState>.loading()) {
    _load();
  }

  final CosmeticsService _cosmeticsService;
  final Ref _ref;

  Future<void> _load() async {
    try {
      final CosmeticsState state = await _cosmeticsService.loadState();
      this.state = AsyncValue<CosmeticsState>.data(state);
    } catch (e, st) {
      state = AsyncValue<CosmeticsState>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<CosmeticPurchaseResult> purchase(String cosmeticId) async {
    final CosmeticPurchaseResult result = await _cosmeticsService.purchase(cosmeticId);
    if (result.success) {
      state = AsyncValue<CosmeticsState>.data(result.state);
      unawaited(_ref.read(gemsProvider.notifier).refresh());
    }
    return result;
  }

  Future<void> equip(String cosmeticId) async {
    final CosmeticsState updated = await _cosmeticsService.equip(cosmeticId);
    state = AsyncValue<CosmeticsState>.data(updated);
  }

  Future<void> unequip(CosmeticCategory category) async {
    final CosmeticsState updated = await _cosmeticsService.unequip(category);
    state = AsyncValue<CosmeticsState>.data(updated);
  }
}

final StateNotifierProvider<CosmeticsNotifier, AsyncValue<CosmeticsState>> cosmeticsProvider =
    StateNotifierProvider<CosmeticsNotifier, AsyncValue<CosmeticsState>>((Ref ref) {
  return CosmeticsNotifier(cosmeticsService: ref.watch(cosmeticsServiceProvider), ref: ref);
});
