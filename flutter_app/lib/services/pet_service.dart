import '../core/constants/rewards_constants.dart';
import '../models/pet_companion.dart';
import '../repositories/pet_repository.dart';

/// One-shot result of [PetService.feed], used by the UI to show a
/// "leveled up" celebration when the pet crosses into a new stage.
class PetFeedResult {
  const PetFeedResult({required this.pet, required this.stagedUp});
  final PetCompanion pet;
  final bool stagedUp;
}

/// Encapsulates pet-companion business rules on top of [PetRepository].
/// The pet grows purely by mirroring XP the user earns elsewhere — this
/// service is called alongside XP awards, not as a separate action the
/// user has to remember to do.
class PetService {
  PetService({required PetRepository repository}) : _repository = repository;

  final PetRepository _repository;

  Future<PetCompanion> loadPet() => _repository.load();

  /// Feeds the pet [xp] worth of growth. Safe to call with 0/negative
  /// (no-op) so callers can pass through XP-award amounts unconditionally.
  Future<PetFeedResult> feed(int xp) async {
    final PetCompanion current = await _repository.load();
    if (xp <= 0) return PetFeedResult(pet: current, stagedUp: false);

    final int previousStage = current.stage;
    final PetCompanion updated = current.copyWith(
      xpFed: current.xpFed + xp,
      lastFedAt: DateTime.now(),
    );
    await _repository.save(updated);

    return PetFeedResult(pet: updated, stagedUp: updated.stage > previousStage);
  }

  Future<PetCompanion> rename(String name) async {
    final PetCompanion current = await _repository.load();
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return current;
    final PetCompanion updated = current.copyWith(name: trimmed);
    await _repository.save(updated);
    return updated;
  }

  Future<PetCompanion> chooseSpecies(PetSpecies species) async {
    final PetCompanion current = await _repository.load();
    final PetCompanion updated = current.copyWith(species: species);
    await _repository.save(updated);
    return updated;
  }
}
