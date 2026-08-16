/// Tracks the user's gem balance plus any time-limited active boosts
/// purchased with gems (currently: an XP multiplier). Gems are the soft
/// currency earned by completing lessons/projects/challenges/quests and
/// spent in the shop (heart refills, streak freezes, XP boosts).
class GemsWallet {
  const GemsWallet({
    this.balance = 0,
    this.streakFreezeAvailable = false,
    this.xpBoostActiveUntil,
  });

  final int balance;

  /// Whether the user currently holds an unused streak-freeze charge.
  /// Consumed automatically the next time a day is missed, instead of
  /// letting the streak reset to zero.
  final bool streakFreezeAvailable;

  /// If set and in the future, XP earned is boosted (see
  /// [GemsConfig.xpBoostMultiplier]).
  final DateTime? xpBoostActiveUntil;

  bool get hasActiveXpBoost =>
      xpBoostActiveUntil != null && xpBoostActiveUntil!.isAfter(DateTime.now());

  GemsWallet copyWith({
    int? balance,
    bool? streakFreezeAvailable,
    DateTime? xpBoostActiveUntil,
    bool clearXpBoost = false,
  }) {
    return GemsWallet(
      balance: balance ?? this.balance,
      streakFreezeAvailable: streakFreezeAvailable ?? this.streakFreezeAvailable,
      xpBoostActiveUntil:
          clearXpBoost ? null : (xpBoostActiveUntil ?? this.xpBoostActiveUntil),
    );
  }

  factory GemsWallet.fromJson(Map<String, dynamic> json) {
    return GemsWallet(
      balance: json['balance'] as int? ?? 0,
      streakFreezeAvailable: (json['streakFreezeAvailable'] as int? ?? 0) == 1,
      xpBoostActiveUntil: json['xpBoostActiveUntil'] != null
          ? DateTime.tryParse(json['xpBoostActiveUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'balance': balance,
        'streakFreezeAvailable': streakFreezeAvailable ? 1 : 0,
        'xpBoostActiveUntil': xpBoostActiveUntil?.toIso8601String(),
      };
}
