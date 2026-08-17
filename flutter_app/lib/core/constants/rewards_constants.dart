/// Tuning constants for the daily chest, pet companion, duels, and
/// cosmetics systems. Kept alongside [GemsConfig]/[XpRewards] so all
/// game-balance numbers live in one predictable place.
library;

/// Possible reward kinds a daily chest can roll. Weighted so gems are
/// the common case and rarer perks (streak freeze, XP boost) feel like
/// a genuine bonus rather than the norm.
enum ChestRewardType { gems, xp, streakFreeze, xpBoost }

class ChestConfig {
  const ChestConfig._();

  /// (reward type, relative weight, min amount, max amount). Amount is
  /// ignored for streakFreeze/xpBoost (those grant a fixed perk charge).
  static const List<(ChestRewardType, int, int, int)> weightedRewards = <(ChestRewardType, int, int, int)>[
    (ChestRewardType.gems, 55, 8, 20),
    (ChestRewardType.xp, 30, 15, 40),
    (ChestRewardType.streakFreeze, 8, 1, 1),
    (ChestRewardType.xpBoost, 7, 1, 1),
  ];

  /// XP-boost duration granted by a chest roll — shorter than the shop
  /// version so it stays a nice bonus without undercutting the shop item.
  static const Duration chestXpBoostDuration = Duration(minutes: 10);
}

/// Pet companion tuning. The pet has no gameplay effect on its own —
/// it's a light, low-pressure Tamagotchi-style companion that grows
/// purely from XP already being earned elsewhere, so there's nothing
/// new to grind for it.
class PetConfig {
  const PetConfig._();

  /// XP-fed thresholds a pet must cross to advance to the next stage.
  /// Index = stage (0-based): egg -> hatchling -> juvenile -> adult -> elder.
  static const List<int> stageThresholds = <int>[0, 150, 500, 1500, 4000];

  static const List<String> stageLabels = <String>[
    'Яйцо',
    'Малыш',
    'Подросток',
    'Взрослый',
    'Мастер',
  ];

  static int stageForXp(int xpFed) {
    int stage = 0;
    for (int i = 0; i < stageThresholds.length; i++) {
      if (xpFed >= stageThresholds[i]) stage = i;
    }
    return stage;
  }

  static bool isMaxStage(int xpFed) => stageForXp(xpFed) >= stageThresholds.length - 1;

  /// XP still needed to reach the next stage, or null if already at max.
  static int? xpToNextStage(int xpFed) {
    final int stage = stageForXp(xpFed);
    if (stage >= stageThresholds.length - 1) return null;
    return stageThresholds[stage + 1] - xpFed;
  }
}

/// Species a pet can be — purely cosmetic, chosen once at first hatch.
enum PetSpecies { ferret, owl, fox;

  static PetSpecies fromJson(String value) {
    return PetSpecies.values.firstWhere(
      (PetSpecies e) => e.name == value,
      orElse: () => PetSpecies.ferret,
    );
  }

  String toJson() => name;

  String get emoji => switch (this) {
        PetSpecies.ferret => '🦡',
        PetSpecies.owl => '🦉',
        PetSpecies.fox => '🦊',
      };

  String get label => switch (this) {
        PetSpecies.ferret => 'Хорёк',
        PetSpecies.owl => 'Сова',
        PetSpecies.fox => 'Лис',
      };
}

/// Duel (vs. bot opponent) tuning. Fully offline: the "opponent" is a
/// locally simulated score target scaled off the player's own recent
/// performance, not a real network match.
class DuelConfig {
  const DuelConfig._();

  /// Base point value of one duel-countable action (exercise solved).
  static const int pointsPerCorrectAnswer = 10;
  static const int pointsPerPerfectLesson = 25;

  /// Bot target score is the player's average daily score over the
  /// last N days (min/max clamped), so the bot scales with skill
  /// instead of being trivially easy or impossibly hard.
  static const int minBotTarget = 40;
  static const int maxBotTarget = 400;

  static const int gemsRewardOnWin = 25;

  static const List<String> opponentNamePool = <String>[
    'CodeBot-9000',
    'ByteRival',
    'SyntaxGhost',
    'NullPointer',
    'StackOverflowBot',
    'RecursiveRex',
    'СтарыйКомпилятор',
  ];
}

/// Cosmetics purchasable with gems: avatar frames and alternate app-icon
/// themes (the app-icon "swap" is presentational only inside the app —
/// actually changing the home-screen icon requires native platform
/// config, so this reflects the in-app theme accent used on the profile
/// header/badges rather than the OS launcher icon).
enum CosmeticCategory { avatarFrame, iconTheme }

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.category,
    required this.priceGems,
    required this.colorHex,
  });

  final String id;
  final String name;
  final CosmeticCategory category;
  final int priceGems;

  /// Accent color used to render a preview swatch/ring for this item.
  final String colorHex;
}

class CosmeticsCatalog {
  const CosmeticsCatalog._();

  static const List<CosmeticItem> items = <CosmeticItem>[
    CosmeticItem(
      id: 'frame_indigo',
      name: 'Индиго-кольцо',
      category: CosmeticCategory.avatarFrame,
      priceGems: 40,
      colorHex: '#6366F1',
    ),
    CosmeticItem(
      id: 'frame_mint',
      name: 'Мятное кольцо',
      category: CosmeticCategory.avatarFrame,
      priceGems: 40,
      colorHex: '#34D399',
    ),
    CosmeticItem(
      id: 'frame_amber',
      name: 'Янтарное кольцо',
      category: CosmeticCategory.avatarFrame,
      priceGems: 60,
      colorHex: '#F59E0B',
    ),
    CosmeticItem(
      id: 'frame_gold',
      name: 'Золотое кольцо',
      category: CosmeticCategory.avatarFrame,
      priceGems: 150,
      colorHex: '#EAB308',
    ),
    CosmeticItem(
      id: 'icon_mint',
      name: 'Мятная тема',
      category: CosmeticCategory.iconTheme,
      priceGems: 50,
      colorHex: '#34D399',
    ),
    CosmeticItem(
      id: 'icon_coral',
      name: 'Коралловая тема',
      category: CosmeticCategory.iconTheme,
      priceGems: 50,
      colorHex: '#F87171',
    ),
    CosmeticItem(
      id: 'icon_violet',
      name: 'Фиолетовая тема',
      category: CosmeticCategory.iconTheme,
      priceGems: 80,
      colorHex: '#B07CF8',
    ),
  ];

  static CosmeticItem? byId(String id) {
    for (final CosmeticItem item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<CosmeticItem> byCategory(CosmeticCategory category) =>
      items.where((CosmeticItem i) => i.category == category).toList();
}
