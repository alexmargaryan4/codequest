import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/hearts_state.dart';

/// Owns all reads/writes of [HeartsState] against SQLite. Mirrors the
/// shape of [ProgressRepository] — a single-row table, load/save methods
/// that always return the fresh state.
class HeartsRepository {
  HeartsRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<HeartsState> load() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query('hearts_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const HeartsState();

    final Map<String, Object?> row = rows.first;
    return HeartsState(
      current: row['current'] as int? ?? 5,
      lastLostAt: row['last_lost_at'] != null
          ? DateTime.tryParse(row['last_lost_at'] as String)
          : null,
    );
  }

  Future<void> save(HeartsState state) async {
    final Database db = await _db.database;
    final int updatedRows = await db.update(
      'hearts_state',
      <String, Object?>{
        'current': state.current,
        'last_lost_at': state.lastLostAt?.toIso8601String(),
      },
      where: 'id = 1',
    );
    if (updatedRows == 0) {
      await db.insert(
        'hearts_state',
        <String, Object?>{
          'id': 1,
          'current': state.current,
          'last_lost_at': state.lastLostAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
