import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/duel.dart';

/// Owns all reads/writes of [Duel] against SQLite. One duel per calendar
/// day (keyed by [Duel.dateKey]), kept in a history table so past duels
/// remain visible even after the day rolls over.
class DuelRepository {
  DuelRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Duel?> loadForDate(String dateKey) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'duel_history',
      where: 'date_key = ?',
      whereArgs: <Object?>[dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<Duel>> loadRecent({int limit = 14}) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'duel_history',
      orderBy: 'date_key DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> save(Duel duel) async {
    final Database db = await _db.database;
    await db.insert(
      'duel_history',
      <String, Object?>{
        'id': duel.id,
        'date_key': duel.dateKey,
        'opponent_name': duel.opponentName,
        'opponent_score': duel.opponentScore,
        'player_score': duel.playerScore,
        'target_score': duel.targetScore,
        'won': duel.won == null ? null : (duel.won! ? 1 : 0),
        'gems_reward': duel.gemsReward,
        'claimed_at': duel.claimedAt?.toIso8601String(),
        'created_at': duel.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Duel _fromRow(Map<String, Object?> row) {
    return Duel(
      id: row['id'] as String,
      dateKey: row['date_key'] as String,
      opponentName: row['opponent_name'] as String,
      opponentScore: row['opponent_score'] as int? ?? 0,
      playerScore: row['player_score'] as int? ?? 0,
      targetScore: row['target_score'] as int? ?? 0,
      won: row['won'] == null ? null : (row['won'] as int) == 1,
      gemsReward: row['gems_reward'] as int? ?? 0,
      claimedAt:
          row['claimed_at'] != null ? DateTime.tryParse(row['claimed_at'] as String) : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
