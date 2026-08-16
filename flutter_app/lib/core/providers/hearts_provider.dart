import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/hearts_state.dart';
import '../../services/hearts_service.dart';
import 'core_providers.dart';
import 'gems_provider.dart';

/// Holds the live [HeartsState] and refreshes it every second so any UI
/// showing a "next heart in mm:ss" countdown updates smoothly without
/// each widget needing its own [Timer].
class HeartsNotifier extends StateNotifier<AsyncValue<HeartsState>> {
  HeartsNotifier({required HeartsService heartsService, required Ref ref})
      : _heartsService = heartsService,
        _ref = ref,
        super(const AsyncValue<HeartsState>.loading()) {
    _load();
    // Ticks once a second purely to re-derive `currentHearts()` /
    // `timeUntilNextHeart()` against "now" for the countdown UI. This
    // never writes to storage on its own — only actual heart loss/gain
    // does that (see HeartsState.normalized persistence in the service).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final HeartsService _heartsService;
  final Ref _ref;
  Timer? _ticker;

  Future<void> _load() async {
    try {
      final HeartsState hearts = await _heartsService.loadCurrent();
      state = AsyncValue<HeartsState>.data(hearts);
    } catch (e, st) {
      state = AsyncValue<HeartsState>.error(e, st);
    }
  }

  void _tick() {
    final HeartsState? current = state.valueOrNull;
    if (current == null) return;
    // Only bump state when the derived "live" value actually changes,
    // so we're not rebuilding listeners every second for no reason.
    final HeartsState normalized = current.normalized();
    if (normalized.current != current.current || normalized.lastLostAt != current.lastLostAt) {
      state = AsyncValue<HeartsState>.data(normalized);
    } else if (normalized.timeUntilNextHeart() != current.timeUntilNextHeart()) {
      // Countdown text needs a rebuild even though stored fields didn't
      // change — force a new (equal-but-distinct) instance.
      state = AsyncValue<HeartsState>.data(
        HeartsState(current: normalized.current, lastLostAt: normalized.lastLostAt),
      );
    }
  }

  Future<void> refresh() => _load();

  /// Returns false (and leaves state unchanged) if hearts are already at
  /// zero, so callers can distinguish "should block this action" from a
  /// normal loss.
  Future<bool> loseHeart() async {
    final HeartsState? before = state.valueOrNull;
    if (before != null && before.currentHearts() <= 0) return false;

    final HeartsState updated = await _heartsService.loseHeart();
    state = AsyncValue<HeartsState>.data(updated);
    return true;
  }

  Future<HeartsPurchaseResult> refillWithGems() async {
    final HeartsPurchaseResult result = await _heartsService.refillWithGems();
    if (result.success) {
      state = AsyncValue<HeartsState>.data(result.hearts);
      // Spending gems here happens inside HeartsService (it owns both
      // repositories for this transaction) — refresh the gems provider
      // so the balance shown elsewhere in the UI stays in sync.
      unawaited(_ref.read(gemsProvider.notifier).refresh());
    }
    return result;
  }

  Future<HeartsPurchaseResult> buySingleHeart() async {
    final HeartsPurchaseResult result = await _heartsService.buySingleHeart();
    if (result.success) {
      state = AsyncValue<HeartsState>.data(result.hearts);
      unawaited(_ref.read(gemsProvider.notifier).refresh());
    }
    return result;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<HeartsNotifier, AsyncValue<HeartsState>> heartsProvider =
    StateNotifierProvider<HeartsNotifier, AsyncValue<HeartsState>>((Ref ref) {
  return HeartsNotifier(heartsService: ref.watch(heartsServiceProvider), ref: ref);
});
