import 'dart:math';

import '../core/constants/rewards_constants.dart';
import '../models/daily_chest.dart';
import '../models/gems_wallet.dart';
import '../repositories/daily_chest_repository.dart';
import '../repositories/gems_repository.dart';
import '../repositories/progress_repository.dart';

/// Result of attempting to open today's chest: either the rolled reward
/// plus updated state, or a rejection because it was already opened.
class ChestOpenResult {
  const ChestOpenResult({required this.success, required this.state, this.reward});
  final bool success;
  final DailyChestState state;
  final ChestRewardResult? reward;
}

/// Encapsulates the daily-chest business rules: one open per calendar
/// day, a weighted-random reward roll, and applying that reward to the
/// relevant wallet/progress/perk state.
class ChestService {
  ChestService({
    required DailyChestRepository repository,
    required GemsRepository gemsRepository,
    required ProgressRepository progressRepository,
    Random? random,
  })  : _repository = repository,
        _gemsRepository = gemsRepository,
        _progressRepository = progressRepository,
        _random = random ?? Random();

  final DailyChestRepository _repository;
  final GemsRepository _gemsRepository;
  final ProgressRepository _progressRepository;
  final Random _random;

  Future<DailyChestState> loadState() => _repository.load();

  Future<ChestOpenResult> openToday() async {
    final DailyChestState state = await _repository.load();
    if (!state.isAvailableToday) {
      return ChestOpenResult(success: false, state: state);
    }

    final ChestRewardResult reward = _rollReward();
    await _applyReward(reward);

    final String todayKey = _todayKey();
    final bool openedYesterday = _wasYesterday(state.lastOpenedDateKey, todayKey);
    final DailyChestState updated = state.copyWith(
      lastOpenedDateKey: todayKey,
      openStreak: openedYesterday ? state.openStreak + 1 : 1,
    );
    await _repository.save(updated);

    return ChestOpenResult(success: true, state: updated, reward: reward);
  }

  ChestRewardResult _rollReward() {
    final int totalWeight =
        ChestConfig.weightedRewards.fold<int>(0, (int sum, (ChestRewardType, int, int, int) r) => sum + r.$2);
    int roll = _random.nextInt(totalWeight);

    for (final (ChestRewardType type, int weight, int min, int max) in ChestConfig.weightedRewards) {
      if (roll < weight) {
        final int amount = min == max ? min : (min + _random.nextInt(max - min + 1));
        return ChestRewardResult(type: type, amount: amount);
      }
      roll -= weight;
    }
    // Fallback (unreachable given weights sum correctly), but keeps the
    // function total.
    return const ChestRewardResult(type: ChestRewardType.gems, amount: 10);
  }

  Future<void> _applyReward(ChestRewardResult reward) async {
    switch (reward.type) {
      case ChestRewardType.gems:
        final GemsWallet wallet = await _gemsRepository.load();
        await _gemsRepository.save(wallet.copyWith(balance: wallet.balance + reward.amount));
      case ChestRewardType.xp:
        final progress = await _progressRepository.load();
        await _progressRepository.saveCore(
          progress.copyWith(totalXp: progress.totalXp + reward.amount),
        );
      case ChestRewardType.streakFreeze:
        final GemsWallet wallet = await _gemsRepository.load();
        if (!wallet.streakFreezeAvailable) {
          await _gemsRepository.save(wallet.copyWith(streakFreezeAvailable: true));
        } else {
          // Already holding a freeze — fall back to a small gem grant
          // so the reward is never wasted.
          await _gemsRepository.save(wallet.copyWith(balance: wallet.balance + 15));
        }
      case ChestRewardType.xpBoost:
        final GemsWallet wallet = await _gemsRepository.load();
        final DateTime now = DateTime.now();
        final DateTime baseline = wallet.hasActiveXpBoost ? wallet.xpBoostActiveUntil! : now;
        await _gemsRepository.save(
          wallet.copyWith(xpBoostActiveUntil: baseline.add(ChestConfig.chestXpBoostDuration)),
        );
    }
  }

  String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool _wasYesterday(String? lastKey, String todayKey) {
    if (lastKey == null) return false;
    final DateTime? last = DateTime.tryParse(lastKey);
    final DateTime? today = DateTime.tryParse(todayKey);
    if (last == null || today == null) return false;
    return today.difference(last).inDays == 1;
  }
}
