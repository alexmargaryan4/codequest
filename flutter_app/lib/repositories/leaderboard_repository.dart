import '../models/leaderboard_entry.dart';
import '../models/user_progress.dart';

/// Provides leaderboard data. Today this is purely local/simulated —
/// there is NO backend in this project (by design, see product spec).
///
/// The abstraction is deliberately identical to what a real
/// backend-backed implementation would look like: callers ask for
/// `topEntries(type)` and get back a ranked list including the current
/// user's own entry. When a backend is introduced later, only this class
/// needs to change (e.g. swap the body of [topEntries] for an HTTP call)
/// — no UI or state-management code depends on the data source.
class LeaderboardRepository {
  const LeaderboardRepository();

  /// Deterministic placeholder "other users" so the leaderboard doesn't
  /// look empty before a backend exists. Clearly fictional — replace with
  /// a real API call once user accounts + sync ship.
  static const List<Map<String, Object>> _simulatedPeers = <Map<String, Object>>[
    <String, Object>{'username': 'Alex', 'level': 42, 'totalXp': 12450, 'streak': 184},
    <String, Object>{'username': 'David', 'level': 39, 'totalXp': 11900, 'streak': 129},
    <String, Object>{'username': 'Anna', 'level': 36, 'totalXp': 10840, 'streak': 151},
    <String, Object>{'username': 'Maria', 'level': 28, 'totalXp': 8120, 'streak': 45},
    <String, Object>{'username': 'Ivan', 'level': 22, 'totalXp': 5990, 'streak': 12},
  ];

  Future<List<LeaderboardEntry>> topEntries({
    required LeaderboardType type,
    required UserProgress currentUser,
    required String currentUsername,
  }) async {
    final List<LeaderboardEntry> entries = _simulatedPeers
        .map((Map<String, Object> p) => LeaderboardEntry(
              userId: p['username'] as String,
              username: p['username'] as String,
              level: p['level'] as int,
              totalXp: p['totalXp'] as int,
              streak: p['streak'] as int,
            ))
        .toList();

    entries.add(LeaderboardEntry(
      userId: 'me',
      username: currentUsername,
      level: currentUser.level,
      totalXp: currentUser.totalXp,
      streak: currentUser.currentStreak,
      isCurrentUser: true,
    ));

    entries.sort((LeaderboardEntry a, LeaderboardEntry b) {
      if (type == LeaderboardType.xp) return b.totalXp.compareTo(a.totalXp);
      return b.streak.compareTo(a.streak);
    });

    return entries;
  }
}
