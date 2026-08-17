/// All XP rewards in the app live here so game-balance tuning never
/// requires touching feature code.
class XpRewards {
  const XpRewards._();

  static const int correctAnswerFirstTry = 5;
  static const int correctAnswerAfterHint = 3;
  static const int lessonComplete = 30;
  static const int miniProjectComplete = 100;
  static const int dailyChallengeComplete = 50;
  static const int perfectLessonBonus = 15; // no wrong answers, no hints
  static const int streakDayBonus = 10;
  static const int achievementUnlocked = 25;
}

/// Streak-length XP multiplier: the longer the current streak, the more
/// bonus XP every award earns. Kept as a step function (not a smooth
/// curve) so it's easy to show the exact next threshold in the UI
/// ("3 more days to reach x1.5").
class StreakMultiplier {
  const StreakMultiplier._();

  /// (minimum streak length in days, multiplier applied to XP awards).
  /// Checked from the end backwards, so longer streaks look up their
  /// entry directly rather than falling through every earlier tier.
  static const List<(int minDays, double multiplier)> _tiers = <(int, double)>[
    (30, 2.0),
    (14, 1.75),
    (7, 1.5),
    (3, 1.2),
    (0, 1.0),
  ];

  static double forStreak(int streakDays) {
    for (final (int minDays, double multiplier) in _tiers) {
      if (streakDays >= minDays) return multiplier;
    }
    return 1.0;
  }

  /// Days still needed to reach the next-higher tier, or null if already
  /// at the top tier. Used for "N days to x1.5" progress messaging.
  static int? daysToNextTier(int streakDays) {
    for (int i = _tiers.length - 1; i >= 0; i--) {
      final int minDays = _tiers[i].$1;
      if (streakDays < minDays) return minDays - streakDays;
    }
    return null;
  }

  static double? nextMultiplier(int streakDays) {
    for (int i = _tiers.length - 1; i >= 0; i--) {
      final int minDays = _tiers[i].$1;
      if (streakDays < minDays) return _tiers[i].$2;
    }
    return null;
  }
}

/// Level thresholds: cumulative XP required to REACH each level.
/// Index 0 = Level 1 (0 XP). Generated with a smooth quadratic-ish curve
/// so early levels feel fast and later levels feel earned.
class LevelThresholds {
  const LevelThresholds._();

  static final List<int> _cumulativeXp = _generate();

  static List<int> _generate() {
    final List<int> thresholds = <int>[0];
    int xp = 0;
    for (int level = 2; level <= 100; level++) {
      // Growth: each level costs a bit more than the last.
      final int increment = 100 + ((level - 1) * 35);
      xp += increment;
      thresholds.add(xp);
    }
    return thresholds;
  }

  /// Returns the user's level (1-based) for a given total XP.
  static int levelForXp(int totalXp) {
    int level = 1;
    for (int i = 0; i < _cumulativeXp.length; i++) {
      if (totalXp >= _cumulativeXp[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level;
  }

  /// Total XP required to reach [level].
  static int xpForLevel(int level) {
    final int index = (level - 1).clamp(0, _cumulativeXp.length - 1);
    return _cumulativeXp[index];
  }

  /// XP required to go from the current level to the next one.
  static int xpForNextLevel(int level) => xpForLevel(level + 1);

  /// Progress within the current level as (currentXpInLevel, xpNeededForLevel).
  static (int current, int needed) progressWithinLevel(int totalXp) {
    final int level = levelForXp(totalXp);
    final int levelStart = xpForLevel(level);
    final int levelEnd = xpForLevel(level + 1);
    return (totalXp - levelStart, levelEnd - levelStart);
  }
}
