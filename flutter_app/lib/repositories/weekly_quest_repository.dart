import 'package:sqflite/sqflite.dart';

import '../core/constants/game_economy_constants.dart';
import '../core/storage/app_database.dart';
import '../models/weekly_quest.dart';

/// A fixed pool of quest templates, purely local/offline — no AI or
/// network dependency, since quests should always be available. Three
/// are deterministically selected per week (see [_selectForWeek]) so the
/// same week always yields the same quest set for a given user, without
/// needing to persist "which templates were picked" separately.
class _QuestTemplate {
  const _QuestTemplate({
    required this.id,
    required this.metric,
    required this.target,
    required this.gemsReward,
    required this.xpReward,
  });

  final String id;
  final QuestMetric metric;
  final int target;
  final int gemsReward;
  final int xpReward;
}

/// Owns weekly quest generation and progress persistence. Progress is
/// updated incrementally by [QuestService] as the user does things
/// elsewhere in the app (solves exercises, finishes lessons, etc.) —
/// this class only knows how to store/retrieve/reset quest rows.
class WeeklyQuestRepository {
  WeeklyQuestRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  static const List<_QuestTemplate> _pool = <_QuestTemplate>[
    _QuestTemplate(
      id: 'solve_15_exercises',
      metric: QuestMetric.exercisesSolved,
      target: 15,
      gemsReward: 15,
      xpReward: 30,
    ),
    _QuestTemplate(
      id: 'solve_35_exercises',
      metric: QuestMetric.exercisesSolved,
      target: 35,
      gemsReward: 25,
      xpReward: 60,
    ),
    _QuestTemplate(
      id: 'complete_5_lessons',
      metric: QuestMetric.lessonsCompleted,
      target: 5,
      gemsReward: 20,
      xpReward: 40,
    ),
    _QuestTemplate(
      id: 'complete_10_lessons',
      metric: QuestMetric.lessonsCompleted,
      target: 10,
      gemsReward: 30,
      xpReward: 80,
    ),
    _QuestTemplate(
      id: 'perfect_3_lessons',
      metric: QuestMetric.perfectLessons,
      target: 3,
      gemsReward: 20,
      xpReward: 50,
    ),
    _QuestTemplate(
      id: 'earn_300_xp',
      metric: QuestMetric.xpEarned,
      target: 300,
      gemsReward: 20,
      xpReward: 0,
    ),
    _QuestTemplate(
      id: 'earn_600_xp',
      metric: QuestMetric.xpEarned,
      target: 600,
      gemsReward: 35,
      xpReward: 0,
    ),
    _QuestTemplate(
      id: 'complete_1_project',
      metric: QuestMetric.projectsCompleted,
      target: 1,
      gemsReward: 25,
      xpReward: 0,
    ),
  ];

  /// ISO-8601 week key, e.g. '2026-W33'. Weeks are treated as starting
  /// on Monday, matching [DateTime.weekday] (1 = Monday).
  static String weekKeyFor(DateTime date) {
    final DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    final DateTime firstDayOfYear = DateTime(monday.year, 1, 1);
    final int dayOfYear = monday.difference(firstDayOfYear).inDays + 1;
    final int weekNumber = ((dayOfYear - monday.weekday + 10) / 7).floor();
    return '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  List<_QuestTemplate> _selectForWeek(String weekKey) {
    // Deterministic pseudo-random selection seeded by the week key, so
    // the same week always produces the same 3 quests for this device.
    final int seed = weekKey.codeUnits.fold<int>(0, (int acc, int c) => acc + c);
    final List<_QuestTemplate> shuffled = List<_QuestTemplate>.from(_pool);
    // Simple deterministic shuffle (Fisher–Yates with a seeded LCG).
    int state = seed == 0 ? 1 : seed;
    int nextRand(int maxExclusive) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state % maxExclusive;
    }

    for (int i = shuffled.length - 1; i > 0; i--) {
      final int j = nextRand(i + 1);
      final _QuestTemplate tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return shuffled.take(QuestConfig.questsPerWeek).toList();
  }

  /// Returns this week's quests, generating (and persisting) a fresh set
  /// the first time this week is seen.
  Future<List<WeeklyQuest>> loadForWeek(String weekKey) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'weekly_quests',
      where: 'week_key = ?',
      whereArgs: <Object?>[weekKey],
    );

    if (rows.isNotEmpty) {
      return rows.map(_fromRow).toList();
    }

    final List<_QuestTemplate> templates = _selectForWeek(weekKey);
    final List<WeeklyQuest> generated = templates
        .map((_QuestTemplate t) => WeeklyQuest(
              id: t.id,
              weekKey: weekKey,
              metric: t.metric,
              target: t.target,
              progress: 0,
              gemsReward: t.gemsReward,
              xpReward: t.xpReward,
            ))
        .toList();

    final Batch batch = db.batch();
    for (final WeeklyQuest q in generated) {
      batch.insert('weekly_quests', _toRow(q), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);

    return generated;
  }

  Future<void> saveQuest(WeeklyQuest quest) async {
    final Database db = await _db.database;
    await db.update(
      'weekly_quests',
      _toRow(quest),
      where: 'id = ? AND week_key = ?',
      whereArgs: <Object?>[quest.id, quest.weekKey],
    );
  }

  WeeklyQuest _fromRow(Map<String, Object?> row) {
    return WeeklyQuest(
      id: row['id'] as String,
      weekKey: row['week_key'] as String,
      metric: QuestMetric.fromJson(row['metric'] as String? ?? 'exercisesSolved'),
      target: row['target'] as int? ?? 1,
      progress: row['progress'] as int? ?? 0,
      gemsReward: row['gems_reward'] as int? ?? 0,
      xpReward: row['xp_reward'] as int? ?? 0,
      completed: (row['completed'] as int? ?? 0) == 1,
      claimedAt:
          row['claimed_at'] != null ? DateTime.tryParse(row['claimed_at'] as String) : null,
    );
  }

  Map<String, Object?> _toRow(WeeklyQuest quest) {
    return <String, Object?>{
      'id': quest.id,
      'week_key': quest.weekKey,
      'metric': quest.metric.toJson(),
      'target': quest.target,
      'progress': quest.progress,
      'gems_reward': quest.gemsReward,
      'xp_reward': quest.xpReward,
      'completed': quest.completed ? 1 : 0,
      'claimed_at': quest.claimedAt?.toIso8601String(),
    };
  }
}
