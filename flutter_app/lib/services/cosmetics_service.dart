import '../core/constants/rewards_constants.dart';
import '../models/cosmetics_state.dart';
import '../models/gems_wallet.dart';
import '../repositories/cosmetics_repository.dart';
import '../repositories/gems_repository.dart';

class CosmeticPurchaseResult {
  const CosmeticPurchaseResult({required this.success, required this.state, this.message});
  final bool success;
  final CosmeticsState state;
  final String? message;
}

/// Encapsulates cosmetics business rules: buying items with gems and
/// equipping owned ones. Purchases are permanent (no consumable
/// cosmetics), so this is intentionally simpler than [GemsService]'s
/// time-limited perks.
class CosmeticsService {
  CosmeticsService({
    required CosmeticsRepository repository,
    required GemsRepository gemsRepository,
  })  : _repository = repository,
        _gemsRepository = gemsRepository;

  final CosmeticsRepository _repository;
  final GemsRepository _gemsRepository;

  Future<CosmeticsState> loadState() => _repository.load();

  Future<CosmeticPurchaseResult> purchase(String cosmeticId) async {
    final CosmeticItem? item = CosmeticsCatalog.byId(cosmeticId);
    if (item == null) {
      final CosmeticsState state = await _repository.load();
      return CosmeticPurchaseResult(success: false, state: state, message: 'Товар не найден');
    }

    final CosmeticsState state = await _repository.load();
    if (state.owns(cosmeticId)) {
      return CosmeticPurchaseResult(success: false, state: state, message: 'Уже куплено');
    }

    final GemsWallet wallet = await _gemsRepository.load();
    if (wallet.balance < item.priceGems) {
      return CosmeticPurchaseResult(success: false, state: state, message: 'Недостаточно гемов');
    }

    await _gemsRepository.save(wallet.copyWith(balance: wallet.balance - item.priceGems));
    await _repository.purchase(cosmeticId);

    final CosmeticsState updated = state.copyWith(
      ownedIds: <String>{...state.ownedIds, cosmeticId},
    );
    return CosmeticPurchaseResult(success: true, state: updated);
  }

  Future<CosmeticsState> equip(String cosmeticId) async {
    final CosmeticItem? item = CosmeticsCatalog.byId(cosmeticId);
    final CosmeticsState state = await _repository.load();
    if (item == null || !state.owns(cosmeticId)) return state;

    final CosmeticsState updated = switch (item.category) {
      CosmeticCategory.avatarFrame => state.copyWith(equippedAvatarFrameId: cosmeticId),
      CosmeticCategory.iconTheme => state.copyWith(equippedIconThemeId: cosmeticId),
    };

    await _repository.saveEquipped(
      avatarFrameId: updated.equippedAvatarFrameId,
      iconThemeId: updated.equippedIconThemeId,
    );
    return updated;
  }

  Future<CosmeticsState> unequip(CosmeticCategory category) async {
    final CosmeticsState state = await _repository.load();
    final CosmeticsState updated = switch (category) {
      CosmeticCategory.avatarFrame => state.copyWith(clearAvatarFrame: true),
      CosmeticCategory.iconTheme => state.copyWith(clearIconTheme: true),
    };
    await _repository.saveEquipped(
      avatarFrameId: updated.equippedAvatarFrameId,
      iconThemeId: updated.equippedIconThemeId,
    );
    return updated;
  }
}
