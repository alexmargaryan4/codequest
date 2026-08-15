enum LeaderboardType {
  xp,
  streak;

  static LeaderboardType fromJson(String value) {
    return LeaderboardType.values.firstWhere(
      (LeaderboardType e) => e.name == value,
      orElse: () => LeaderboardType.xp,
    );
  }

  String toJson() => name;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.level,
    required this.totalXp,
    required this.streak,
    this.isCurrentUser = false,
    this.avatarSeed = 'default',
  });

  final String userId;
  final String username;
  final int level;
  final int totalXp;
  final int streak;
  final bool isCurrentUser;
  final String avatarSeed;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      totalXp: json['totalXp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      avatarSeed: json['avatarSeed'] as String? ?? 'default',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'username': username,
        'level': level,
        'totalXp': totalXp,
        'streak': streak,
        'isCurrentUser': isCurrentUser,
        'avatarSeed': avatarSeed,
      };
}
