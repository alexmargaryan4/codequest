import '../core/constants/game_economy_constants.dart';
import '../models/hearts_state.dart';
import '../repositories/gems_repository.dart';
import '../repositories/hearts_repository.dart';

/// Result of an attempt to spend gems refilling hearts — lets the UI
/// distinguish "not enough gems" from a normal success without throwing.
class HeartsPurchaseResult {
  const HeartsPurchaseResult({required this.success, required this.hearts, this.message});
  final bool success;
  final HeartsState hearts;
  final String? message;
}

/// Encapsulates all hearts (lives) business rules on top of
/// [HeartsRepository]: losing a heart on a wrong answer, lazily
/// regenerating over time, and spending gems to refill.
class HeartsService {
  HeartsService({required HeartsRepository repository, required GemsRepository gemsRepository})
      : _repository = repository,
        _gemsRepository = gemsRepository;

  final HeartsRepository _repository;
  final GemsRepository _gemsRepository;

  /// Loads hearts, applying any regeneration accrued since the last
  /// read, and persists the normalized value so storage never drifts.
  Future<HeartsState> loadCurrent() async {
    final HeartsState stored = await _repository.load();
    final HeartsState normalized = stored.normalized();
    if (normalized.current != stored.current || normalized.lastLostAt != stored.lastLostAt) {
      await _repository.save(normalized);
    }
    return normalized;
  }

  /// Call when the user answers an exercise incorrectly. No-ops (returns
  /// the current state unchanged) if hearts are already at zero — the UI
  /// is expected to block starting new exercises before that happens.
  Future<HeartsState> loseHeart() async {
    final HeartsState current = await loadCurrent();
    final HeartsState updated = current.loseOne();
    await _repository.save(updated);
    return updated;
  }

  /// Instantly refills to full by spending [HeartsConfig.refillCostGems].
  Future<HeartsPurchaseResult> refillWithGems() async {
    final gems = await _gemsRepository.load();
    if (gems.balance < HeartsConfig.refillCostGems) {
      final HeartsState hearts = await loadCurrent();
      return HeartsPurchaseResult(success: false, hearts: hearts, message: 'Недостаточно гемов');
    }
    await _gemsRepository.save(gems.copyWith(balance: gems.balance - HeartsConfig.refillCostGems));
    final HeartsState refilled = const HeartsState().refillAll();
    await _repository.save(refilled);
    return HeartsPurchaseResult(success: true, hearts: refilled);
  }

  /// Buys exactly one heart for [HeartsConfig.singleHeartCostGems].
  Future<HeartsPurchaseResult> buySingleHeart() async {
    final HeartsState current = await loadCurrent();
    if (current.isFull) {
      return HeartsPurchaseResult(success: false, hearts: current, message: 'Жизни уже полные');
    }
    final gems = await _gemsRepository.load();
    if (gems.balance < HeartsConfig.singleHeartCostGems) {
      return HeartsPurchaseResult(success: false, hearts: current, message: 'Недостаточно гемов');
    }
    await _gemsRepository
        .save(gems.copyWith(balance: gems.balance - HeartsConfig.singleHeartCostGems));
    final HeartsState updated = current.addOne();
    await _repository.save(updated);
    return HeartsPurchaseResult(success: true, hearts: updated);
  }
}
