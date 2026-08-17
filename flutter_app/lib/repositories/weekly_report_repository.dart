import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';

/// Read-only aggregation queries against `completed_lessons` /
/// `topic_mastery` used to build [WeeklyReport]. Kept separate from
/// [ProgressRepository] since these are analytics reads over raw rows
/// rather than the single [UserProgress] aggregate row it owns.
class WeeklyReportRepository {
  WeeklyReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  /// Lessons completed with `completed_at` within [start, end) (end
  /// exclusive), each row as (wasPerfect, completedAt).
  Future<List<(bool wasPerfect, DateTime completedAt)>> lessonsCompletedBetween(
    DateTime start,
    DateTime end,
  ) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'completed_lessons',
      where: 'completed_at >= ? AND completed_at < ?',
      whereArgs: <Object?>[start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map((Map<String, Object?> r) {
      final bool perfect = (r['was_perfect'] as int? ?? 0) == 1;
      final DateTime at = DateTime.tryParse(r['completed_at'] as String? ?? '') ?? start;
      return (perfect, at);
    }).toList();
  }

  /// All topic-mastery rows, used to find the current strongest/weakest
  /// topics by accuracy (whole-history, not week-scoped — mastery rows
  /// don't carry enough history to window by date).
  Future<List<(String topicId, int correct, int total)>> topicMasterySummary() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query('topic_mastery');
    return rows.map((Map<String, Object?> r) {
      return (
        r['topic_id'] as String,
        r['correct_count'] as int? ?? 0,
        r['total_attempts'] as int? ?? 0,
      );
    }).toList();
  }
}
