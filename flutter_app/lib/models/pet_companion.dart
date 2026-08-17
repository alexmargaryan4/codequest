import '../core/constants/rewards_constants.dart';

/// The user's pet companion — grows automatically as XP is earned
/// elsewhere in the app (no separate feeding/grinding loop). Purely a
/// warm, low-pressure presence on the home screen; has no gameplay
/// effect on lessons, hearts, or gems.
class PetCompanion {
  const PetCompanion({
    this.species = PetSpecies.ferret,
    this.xpFed = 0,
    this.name = 'Байт',
    this.lastFedAt,
  });

  final PetSpecies species;

  /// Cumulative XP the pet has "absorbed" — mirrors the user's total XP
  /// growth 1:1 unless a future feature decouples them.
  final int xpFed;
  final String name;
  final DateTime? lastFedAt;

  int get stage => PetConfig.stageForXp(xpFed);
  String get stageLabel => PetConfig.stageLabels[stage];
  bool get isMaxStage => PetConfig.isMaxStage(xpFed);
  int? get xpToNextStage => PetConfig.xpToNextStage(xpFed);

  double get stageProgressRatio {
    final int currentThreshold = PetConfig.stageThresholds[stage];
    if (isMaxStage) return 1.0;
    final int nextThreshold = PetConfig.stageThresholds[stage + 1];
    final int span = nextThreshold - currentThreshold;
    if (span <= 0) return 1.0;
    return ((xpFed - currentThreshold) / span).clamp(0.0, 1.0);
  }

  PetCompanion copyWith({
    PetSpecies? species,
    int? xpFed,
    String? name,
    DateTime? lastFedAt,
  }) {
    return PetCompanion(
      species: species ?? this.species,
      xpFed: xpFed ?? this.xpFed,
      name: name ?? this.name,
      lastFedAt: lastFedAt ?? this.lastFedAt,
    );
  }

  factory PetCompanion.fromJson(Map<String, dynamic> json) {
    return PetCompanion(
      species: PetSpecies.fromJson(json['species'] as String? ?? 'ferret'),
      xpFed: json['xpFed'] as int? ?? 0,
      name: json['name'] as String? ?? 'Байт',
      lastFedAt:
          json['lastFedAt'] != null ? DateTime.tryParse(json['lastFedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'species': species.toJson(),
        'xpFed': xpFed,
        'name': name,
        'lastFedAt': lastFedAt?.toIso8601String(),
      };
}
