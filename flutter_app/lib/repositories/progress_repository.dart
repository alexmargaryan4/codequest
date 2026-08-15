import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/user_progress.dart';

/// Owns all reads/writes of [UserProgress] against SQLite. Every method
/// returns the freshly updated [UserProgress] so callers (Riverpod
/// notifiers) can push the new state immediately without a second read.
class ProgressRepository {
  ProgressRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<UserProgress> load() async {
    final Database db = await _db.database;

    final List<Map<String, Object?>> rows =
        await db.query('user_progress', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return const UserProgress();
    }
    final Map<String, Object?> row = rows.first;

    final List<Map<String, Object?>> lessonRows = await db.query('completed_lessons');
    final List<Map<String, Object?>> topicRows = await db.query('completed_topics');
    final List<Map<String, Object?>> projectRows = await db.query('completed_projects');
    final List<Map<String, Object?>> achievementRows = await db.query('unlocked_achievements');
    final List<Map<String, Object?>> masteryRows = await db.query('topic_mastery');

    return UserProgress(
      totalXp: row['total_xp'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      lastActivityDate: row['last_activity_date'] != null
          ? DateTime.tryParse(row['last_activity_date'] as String)
          : null,
      lessonsCompleted: row['lessons_completed'] as int? ?? 0,
      projectsCompleted: row['projects_completed'] as int? ?? 0,
      activeCourseId: row['active_course_id'] as String? ?? 'python',
      completedLessonIds:
          lessonRows.map((Map<String, Object?> r) => r['lesson_id'] as String).toSet(),
      completedTopicIds:
          topicRows.map((Map<String, Object?> r) => r['topic_id'] as String).toSet(),
      completedProjectIds:
          projectRows.map((Map<String, Object?> r) => r['project_id'] as String).toSet(),
      unlockedAchievementIds: achievementRows
          .map((Map<String, Object?> r) => r['achievement_id'] as String)
          .toSet(),
      topicMastery: <String, TopicMastery>{
        for (final Map<String, Object?> r in masteryRows)
          r['topic_id'] as String: TopicMastery(
            topicId: r['topic_id'] as String,
            correctCount: r['correct_count'] as int? ?? 0,
            incorrectCount: r['incorrect_count'] as int? ?? 0,
            totalAttempts: r['total_attempts'] as int? ?? 0,
            hintsUsed: r['hints_used'] as int? ?? 0,
            totalTimeSeconds: r['total_time_seconds'] as int? ?? 0,
            lastPracticedAt: r['last_practiced_at'] != null
                ? DateTime.tryParse(r['last_practiced_at'] as String)
                : null,
          ),
      },
    );
  }

  Future<void> saveCore(UserProgress progress) async {
    final Database db = await _db.database;
    await db.update(
      'user_progress',
      <String, Object?>{
        'total_xp': progress.totalXp,
        'current_streak': progress.currentStreak,
        'longest_streak': progress.longestStreak,
        'last_activity_date': progress.lastActivityDate?.toIso8601String(),
        'lessons_completed': progress.lessonsCompleted,
        'projects_completed': progress.projectsCompleted,
        'active_course_id': progress.activeCourseId,
      },
      where: 'id = 1',
    );
  }

  Future<void> markLessonCompleted({
    required String lessonId,
    required String topicId,
    required String courseId,
    required bool wasPerfect,
  }) async {
    final Database db = await _db.database;
    await db.insert(
      'completed_lessons',
      <String, Object?>{
        'lesson_id': lessonId,
        'topic_id': topicId,
        'course_id': courseId,
        'completed_at': DateTime.now().toIso8601String(),
        'was_perfect': wasPerfect ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markTopicCompleted({required String topicId, required String courseId}) async {
    final Database db = await _db.database;
    await db.insert(
      'completed_topics',
      <String, Object?>{
        'topic_id': topicId,
        'course_id': courseId,
        'completed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markProjectCompleted({required String projectId, required String topicId}) async {
    final Database db = await _db.database;
    await db.insert(
      'completed_projects',
      <String, Object?>{
        'project_id': projectId,
        'topic_id': topicId,
        'completed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unlockAchievement(String achievementId) async {
    final Database db = await _db.database;
    await db.insert(
      'unlocked_achievements',
      <String, Object?>{
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> recordExerciseAttempt({
    required String topicId,
    required bool wasCorrect,
    required bool usedHint,
    required int timeSeconds,
  }) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> existing =
        await db.query('topic_mastery', where: 'topic_id = ?', whereArgs: <Object?>[topicId]);

    if (existing.isEmpty) {
      await db.insert('topic_mastery', <String, Object?>{
        'topic_id': topicId,
        'correct_count': wasCorrect ? 1 : 0,
        'incorrect_count': wasCorrect ? 0 : 1,
        'total_attempts': 1,
        'hints_used': usedHint ? 1 : 0,
        'total_time_seconds': timeSeconds,
        'last_practiced_at': DateTime.now().toIso8601String(),
      });
    } else {
      final Map<String, Object?> row = existing.first;
      await db.update(
        'topic_mastery',
        <String, Object?>{
          'correct_count': (row['correct_count'] as int? ?? 0) + (wasCorrect ? 1 : 0),
          'incorrect_count': (row['incorrect_count'] as int? ?? 0) + (wasCorrect ? 0 : 1),
          'total_attempts': (row['total_attempts'] as int? ?? 0) + 1,
          'hints_used': (row['hints_used'] as int? ?? 0) + (usedHint ? 1 : 0),
          'total_time_seconds': (row['total_time_seconds'] as int? ?? 0) + timeSeconds,
          'last_practiced_at': DateTime.now().toIso8601String(),
        },
        where: 'topic_id = ?',
        whereArgs: <Object?>[topicId],
      );
    }
  }
}
