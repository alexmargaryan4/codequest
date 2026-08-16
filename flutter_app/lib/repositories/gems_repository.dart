import 'package:sqflite/sqflite.dart';

import '../core/constants/game_economy_constants.dart';
import '../core/storage/app_database.dart';
import '../models/gems_wallet.dart';

/// Owns all reads/writes of [GemsWallet] against SQLite.
class GemsRepository {
  GemsRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<GemsWallet> load() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query('gems_wallet', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const GemsWallet(balance: GemsConfig.startingBalance);

    final Map<String, Object?> row = rows.first;
    return GemsWallet(
      balance: row['balance'] as int? ?? 0,
      streakFreezeAvailable: (row['streak_freeze_available'] as int? ?? 0) == 1,
      xpBoostActiveUntil: row['xp_boost_active_until'] != null
          ? DateTime.tryParse(row['xp_boost_active_until'] as String)
          : null,
    );
  }

  Future<void> save(GemsWallet wallet) async {
    final Database db = await _db.database;
    final int updatedRows = await db.update(
      'gems_wallet',
      <String, Object?>{
        'balance': wallet.balance,
        'streak_freeze_available': wallet.streakFreezeAvailable ? 1 : 0,
        'xp_boost_active_until': wallet.xpBoostActiveUntil?.toIso8601String(),
      },
      where: 'id = 1',
    );
    if (updatedRows == 0) {
      await db.insert(
        'gems_wallet',
        <String, Object?>{
          'id': 1,
          'balance': wallet.balance,
          'streak_freeze_available': wallet.streakFreezeAvailable ? 1 : 0,
          'xp_boost_active_until': wallet.xpBoostActiveUntil?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
