import '../core/constants/rewards_constants.dart';

/// Persisted state of the daily chest: when it was last opened and the
/// current "opened N days in a row" streak (separate from the main
/// learning streak — this one tracks chest-opening specifically, so
/// missing a lesson day doesn't reset chest progress and vice versa).
class DailyChestState {
  const DailyChestState({this.lastOpenedDateKey, this.openStreak = 0});

  /// 'yyyy-MM-dd' of the last date the chest was opened, or null if
  /// never opened.
  final String? lastOpenedDateKey;
  final int openStreak;

  bool get isAvailableToday {
    final String today = _todayKey();
    return lastOpenedDateKey != today;
  }

  static String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DailyChestState copyWith({String? lastOpenedDateKey, int? openStreak}) {
    return DailyChestState(
      lastOpenedDateKey: lastOpenedDateKey ?? this.lastOpenedDateKey,
      openStreak: openStreak ?? this.openStreak,
    );
  }

  factory DailyChestState.fromJson(Map<String, dynamic> json) {
    return DailyChestState(
      lastOpenedDateKey: json['lastOpenedDateKey'] as String?,
      openStreak: json['openStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lastOpenedDateKey': lastOpenedDateKey,
        'openStreak': openStreak,
      };
}

/// The outcome of a single chest opening — what the player actually won,
/// ready for the reveal screen to display and the service layer to
/// apply to the relevant wallet/state.
class ChestRewardResult {
  const ChestRewardResult({required this.type, required this.amount});

  final ChestRewardType type;

  /// Gem or XP amount for [ChestRewardType.gems]/[ChestRewardType.xp].
  /// Ignored (always 1) for perk-type rewards.
  final int amount;

  String get title => switch (type) {
        ChestRewardType.gems => '$amount гемов',
        ChestRewardType.xp => '$amount XP',
        ChestRewardType.streakFreeze => 'Заморозка стрика',
        ChestRewardType.xpBoost => 'Буст XP x2',
      };

  String get description => switch (type) {
        ChestRewardType.gems => 'Добавлено в твой кошелёк',
        ChestRewardType.xp => 'Опыт зачислен сразу',
        ChestRewardType.streakFreeze => 'Спасёт твой стрик, если пропустишь день',
        ChestRewardType.xpBoost => 'Двойной опыт на 10 минут',
      };
}
