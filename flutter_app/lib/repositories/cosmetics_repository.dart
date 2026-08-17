import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/cosmetics_state.dart';

/// Owns all reads/writes of owned/equipped cosmetics against SQLite.
class CosmeticsRepository {
  CosmeticsRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<CosmeticsState> load() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> ownedRows = await db.query('owned_cosmetics');
    final List<Map<String, Object?>> equippedRows =
        await db.query('equipped_cosmetics', where: 'id = 1', limit: 1);

    final Set<String> owned =
        ownedRows.map((Map<String, Object?> r) => r['cosmetic_id'] as String).toSet();

    if (equippedRows.isEmpty) {
      return CosmeticsState(ownedIds: owned);
    }
    final Map<String, Object?> row = equippedRows.first;
    return CosmeticsState(
      ownedIds: owned,
      equippedAvatarFrameId: row['avatar_frame_id'] as String?,
      equippedIconThemeId: row['app_icon_id'] as String?,
    );
  }

  Future<void> purchase(String cosmeticId) async {
    final Database db = await _db.database;
    await db.insert(
      'owned_cosmetics',
      <String, Object?>{
        'cosmetic_id': cosmeticId,
        'purchased_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> saveEquipped({String? avatarFrameId, String? iconThemeId}) async {
    final Database db = await _db.database;
    final int updatedRows = await db.update(
      'equipped_cosmetics',
      <String, Object?>{
        'avatar_frame_id': avatarFrameId,
        'app_icon_id': iconThemeId,
      },
      where: 'id = 1',
    );
    if (updatedRows == 0) {
      await db.insert(
        'equipped_cosmetics',
        <String, Object?>{
          'id': 1,
          'avatar_frame_id': avatarFrameId,
          'app_icon_id': iconThemeId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
