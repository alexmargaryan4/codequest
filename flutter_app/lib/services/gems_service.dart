import '../core/constants/game_economy_constants.dart';
import '../models/gems_wallet.dart';
import '../repositories/gems_repository.dart';

class GemsPurchaseResult {
  const GemsPurchaseResult({required this.success, required this.wallet, this.message});
  final bool success;
  final GemsWallet wallet;
  final String? message;
}

/// Encapsulates gem-earning and gem-spending business rules on top of
/// [GemsRepository]. Hearts-related spends live in [HeartsService]
/// instead, since those also need to touch [HeartsRepository]; this
/// service owns the gem-only purchases (streak freeze, XP boost) plus
/// all gem-earning.
class GemsService {
  GemsService({required GemsRepository repository}) : _repository = repository;

  final GemsRepository _repository;

  Future<GemsWallet> loadWallet() => _repository.load();

  Future<GemsWallet> earn(int amount) async {
    if (amount <= 0) return _repository.load();
    final GemsWallet wallet = await _repository.load();
    final GemsWallet updated = wallet.copyWith(balance: wallet.balance + amount);
    await _repository.save(updated);
    return updated;
  }

  Future<GemsPurchaseResult> buyStreakFreeze() async {
    final GemsWallet wallet = await _repository.load();
    if (wallet.streakFreezeAvailable) {
      return GemsPurchaseResult(
        success: false,
        wallet: wallet,
        message: 'У тебя уже есть заморозка стрика',
      );
    }
    if (wallet.balance < GemsConfig.streakFreezeCost) {
      return GemsPurchaseResult(success: false, wallet: wallet, message: 'Недостаточно гемов');
    }
    final GemsWallet updated = wallet.copyWith(
      balance: wallet.balance - GemsConfig.streakFreezeCost,
      streakFreezeAvailable: true,
    );
    await _repository.save(updated);
    return GemsPurchaseResult(success: true, wallet: updated);
  }

  /// Consumes the streak-freeze charge (called by [ProgressService] when
  /// a day was about to be missed). Returns true if a freeze was
  /// consumed and the streak should be preserved instead of reset.
  Future<bool> consumeStreakFreezeIfAvailable() async {
    final GemsWallet wallet = await _repository.load();
    if (!wallet.streakFreezeAvailable) return false;
    await _repository.save(wallet.copyWith(streakFreezeAvailable: false));
    return true;
  }

  Future<GemsPurchaseResult> buyXpBoost() async {
    final GemsWallet wallet = await _repository.load();
    if (wallet.balance < GemsConfig.xpBoostCost) {
      return GemsPurchaseResult(success: false, wallet: wallet, message: 'Недостаточно гемов');
    }
    final DateTime now = DateTime.now();
    final DateTime baseline =
        wallet.hasActiveXpBoost ? wallet.xpBoostActiveUntil! : now;
    final GemsWallet updated = wallet.copyWith(
      balance: wallet.balance - GemsConfig.xpBoostCost,
      xpBoostActiveUntil: baseline.add(GemsConfig.xpBoostDuration),
    );
    await _repository.save(updated);
    return GemsPurchaseResult(success: true, wallet: updated);
  }
}
