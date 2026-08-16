import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/gems_wallet.dart';
import '../../services/gems_service.dart';
import 'core_providers.dart';

class GemsNotifier extends StateNotifier<AsyncValue<GemsWallet>> {
  GemsNotifier({required GemsService gemsService})
      : _gemsService = gemsService,
        super(const AsyncValue<GemsWallet>.loading()) {
    _load();
  }

  final GemsService _gemsService;

  Future<void> _load() async {
    try {
      final GemsWallet wallet = await _gemsService.loadWallet();
      state = AsyncValue<GemsWallet>.data(wallet);
    } catch (e, st) {
      state = AsyncValue<GemsWallet>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> earn(int amount) async {
    final GemsWallet updated = await _gemsService.earn(amount);
    state = AsyncValue<GemsWallet>.data(updated);
  }

  Future<GemsPurchaseResult> buyStreakFreeze() async {
    final GemsPurchaseResult result = await _gemsService.buyStreakFreeze();
    if (result.success) state = AsyncValue<GemsWallet>.data(result.wallet);
    return result;
  }

  Future<GemsPurchaseResult> buyXpBoost() async {
    final GemsPurchaseResult result = await _gemsService.buyXpBoost();
    if (result.success) state = AsyncValue<GemsWallet>.data(result.wallet);
    return result;
  }
}

final StateNotifierProvider<GemsNotifier, AsyncValue<GemsWallet>> gemsProvider =
    StateNotifierProvider<GemsNotifier, AsyncValue<GemsWallet>>((Ref ref) {
  return GemsNotifier(gemsService: ref.watch(gemsServiceProvider));
});
