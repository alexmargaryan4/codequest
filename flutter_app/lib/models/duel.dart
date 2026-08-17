/// A single daily duel against a locally simulated bot opponent. Fully
/// offline — the "opponent" is a target score derived from the player's
/// own recent performance (see [DuelConfig]), not a real network match,
/// so this works with no backend and no friend accounts.
class Duel {
  const Duel({
    required this.id,
    required this.dateKey,
    required this.opponentName,
    required this.opponentScore,
    this.playerScore = 0,
    required this.targetScore,
    this.won,
    this.gemsReward = 0,
    this.claimedAt,
    required this.createdAt,
  });

  final String id;

  /// 'yyyy-MM-dd' — one active duel per calendar day.
  final String dateKey;
  final String opponentName;

  /// The bot's final score (fixed at duel creation, framed as "already
  /// played their round" so the player is racing a known target).
  final int opponentScore;

  /// The player's score, incremented as duel-countable actions happen
  /// during the day (see [DuelConfig.pointsPerCorrectAnswer]).
  final int playerScore;

  final int targetScore;

  /// Null while the duel is still in progress (day not over / not
  /// manually settled yet); true/false once resolved.
  final bool? won;

  final int gemsReward;
  final DateTime? claimedAt;
  final DateTime createdAt;

  bool get isResolved => won != null;
  bool get isClaimed => claimedAt != null;
  double get progressRatio =>
      targetScore <= 0 ? 0 : (playerScore / targetScore).clamp(0.0, 1.0);

  Duel copyWith({
    int? playerScore,
    bool? won,
    DateTime? claimedAt,
    bool clearWon = false,
  }) {
    return Duel(
      id: id,
      dateKey: dateKey,
      opponentName: opponentName,
      opponentScore: opponentScore,
      playerScore: playerScore ?? this.playerScore,
      targetScore: targetScore,
      won: clearWon ? null : (won ?? this.won),
      gemsReward: gemsReward,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt,
    );
  }

  factory Duel.fromJson(Map<String, dynamic> json) {
    return Duel(
      id: json['id'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      opponentName: json['opponentName'] as String? ?? 'CodeBot',
      opponentScore: json['opponentScore'] as int? ?? 0,
      playerScore: json['playerScore'] as int? ?? 0,
      targetScore: json['targetScore'] as int? ?? 0,
      won: json['won'] as bool?,
      gemsReward: json['gemsReward'] as int? ?? 0,
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'] as String) : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'dateKey': dateKey,
        'opponentName': opponentName,
        'opponentScore': opponentScore,
        'playerScore': playerScore,
        'targetScore': targetScore,
        'won': won,
        'gemsReward': gemsReward,
        'claimedAt': claimedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
