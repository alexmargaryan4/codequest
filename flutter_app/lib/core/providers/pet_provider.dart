import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pet_companion.dart';
import '../../core/constants/rewards_constants.dart';
import '../../services/pet_service.dart';
import 'core_providers.dart';

class PetNotifier extends StateNotifier<AsyncValue<PetCompanion>> {
  PetNotifier({required PetService petService})
      : _petService = petService,
        super(const AsyncValue<PetCompanion>.loading()) {
    _load();
  }

  final PetService _petService;

  /// Set for one build cycle when a [feed] call crosses a stage
  /// threshold, so the home screen can show a "leveled up!" celebration
  /// then clear it.
  bool lastFeedStagedUp = false;

  Future<void> _load() async {
    try {
      final PetCompanion pet = await _petService.loadPet();
      state = AsyncValue<PetCompanion>.data(pet);
    } catch (e, st) {
      state = AsyncValue<PetCompanion>.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> feed(int xp) async {
    final PetFeedResult result = await _petService.feed(xp);
    lastFeedStagedUp = result.stagedUp;
    state = AsyncValue<PetCompanion>.data(result.pet);
  }

  void clearStagedUpFlag() {
    lastFeedStagedUp = false;
  }

  Future<void> rename(String name) async {
    final PetCompanion updated = await _petService.rename(name);
    state = AsyncValue<PetCompanion>.data(updated);
  }

  Future<void> chooseSpecies(PetSpecies species) async {
    final PetCompanion updated = await _petService.chooseSpecies(species);
    state = AsyncValue<PetCompanion>.data(updated);
  }
}

final StateNotifierProvider<PetNotifier, AsyncValue<PetCompanion>> petProvider =
    StateNotifierProvider<PetNotifier, AsyncValue<PetCompanion>>((Ref ref) {
  return PetNotifier(petService: ref.watch(petServiceProvider));
});
