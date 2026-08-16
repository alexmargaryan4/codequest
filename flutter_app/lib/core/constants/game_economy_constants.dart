/// Tuning constants for the hearts (lives), gems (currency), and weekly
/// quests systems. Kept alongside [XpRewards]/[LevelThresholds] so all
/// game-balance numbers live in one predictable place.
class HeartsConfig {
  const HeartsConfig._();

  /// Maximum hearts a user can hold at once.
  static const int maxHearts = 5;

  /// How long a single lost heart takes to regenerate.
  static const Duration regenDuration = Duration(minutes: 30);

  /// Gems required to refill to full instantly.
  static const int refillCostGems = 40;

  /// Gems required to buy exactly one extra heart.
  static const int singleHeartCostGems = 10;
}

class GemsConfig {
  const GemsConfig._();

  static const int lessonComplete = 5;
  static const int perfectLessonBonus = 5;
  static const int miniProjectComplete = 20;
  static const int dailyChallengeComplete = 10;
  static const int weeklyQuestComplete = 15;
  static const int achievementUnlocked = 10;

  /// One-time starter balance so the shop doesn't look useless on a
  /// brand-new install.
  static const int startingBalance = 20;

  /// Cost of a 24h streak freeze (protects the streak if a day is missed).
  static const int streakFreezeCost = 50;

  /// Cost of a lesson double-XP boost, active for [xpBoostDuration].
  static const int xpBoostCost = 30;
  static const Duration xpBoostDuration = Duration(minutes: 15);
  static const double xpBoostMultiplier = 2.0;
}

/// Ids for purchasable shop items — kept as constants rather than a free
/// string so typos fail at compile time everywhere they're used.
class ShopItemIds {
  const ShopItemIds._();
  static const String refillHearts = 'refill_hearts';
  static const String singleHeart = 'single_heart';
  static const String streakFreeze = 'streak_freeze';
  static const String xpBoost = 'xp_boost';
}

/// Weekly-quest tuning. Quests reset every Monday (local time) and are
/// deliberately simple, countable goals so progress can be derived from
/// events the app already emits (exercises answered, lessons finished,
/// perfect lessons, XP earned) without any new tracking infrastructure.
class QuestConfig {
  const QuestConfig._();

  /// Number of quests generated per week.
  static const int questsPerWeek = 3;
}
