import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/daily_chest.dart';

/// Owns all reads/writes of [DailyChestState] against SQLite.
class DailyChestRepository {
  DailyChestRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<DailyChestState> load() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query('daily_chest', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const DailyChestState();

    final Map<String, Object?> row = rows.first;
    return DailyChestState(
      lastOpenedDateKey: row['last_opened_date'] as String?,
      openStreak: row['current_streak'] as int? ?? 0,
    );
  }

  Future<void> save(DailyChestState state) async {
    final Database db = await _db.database;
    final int updatedRows = await db.update(
      'daily_chest',
      <String, Object?>{
        'last_opened_date': state.lastOpenedDateKey,
        'current_streak': state.openStreak,
      },
      where: 'id = 1',
    );
    if (updatedRows == 0) {
      await db.insert(
        'daily_chest',
        <String, Object?>{
          'id': 1,
          'last_opened_date': state.lastOpenedDateKey,
          'current_streak': state.openStreak,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
