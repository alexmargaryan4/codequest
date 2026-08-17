import 'package:sqflite/sqflite.dart';

import '../core/constants/rewards_constants.dart';
import '../core/storage/app_database.dart';
import '../models/pet_companion.dart';

/// Owns all reads/writes of [PetCompanion] against SQLite.
class PetRepository {
  PetRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<PetCompanion> load() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query('pet_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const PetCompanion();

    final Map<String, Object?> row = rows.first;
    return PetCompanion(
      species: PetSpecies.fromJson(row['species'] as String? ?? 'ferret'),
      xpFed: row['xp_fed'] as int? ?? 0,
      name: row['name'] as String? ?? 'Байт',
      lastFedAt:
          row['last_fed_at'] != null ? DateTime.tryParse(row['last_fed_at'] as String) : null,
    );
  }

  Future<void> save(PetCompanion pet) async {
    final Database db = await _db.database;
    final int updatedRows = await db.update(
      'pet_state',
      <String, Object?>{
        'species': pet.species.toJson(),
        'xp_fed': pet.xpFed,
        'name': pet.name,
        'last_fed_at': pet.lastFedAt?.toIso8601String(),
      },
      where: 'id = 1',
    );
    if (updatedRows == 0) {
      await db.insert(
        'pet_state',
        <String, Object?>{
          'id': 1,
          'species': pet.species.toJson(),
          'xp_fed': pet.xpFed,
          'name': pet.name,
          'last_fed_at': pet.lastFedAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
