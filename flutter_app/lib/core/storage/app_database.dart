import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite database for all structured local data:
/// user progress, completed lessons/exercises, cached AI-generated
/// lessons, achievements, and topic mastery stats.
///
/// SharedPreferences is intentionally NOT used here (per architecture
/// requirements) — it's reserved for small scalar settings only (see
/// core/storage/settings_store.dart).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'codequest.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        total_xp INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_activity_date TEXT,
        lessons_completed INTEGER NOT NULL DEFAULT 0,
        projects_completed INTEGER NOT NULL DEFAULT 0,
        active_course_id TEXT NOT NULL DEFAULT 'python'
      )
    ''');

    await db.execute('''
      CREATE TABLE completed_lessons (
        lesson_id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        course_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        was_perfect INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE completed_topics (
        topic_id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE completed_projects (
        project_id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE unlocked_achievements (
        achievement_id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE topic_mastery (
        topic_id TEXT PRIMARY KEY,
        correct_count INTEGER NOT NULL DEFAULT 0,
        incorrect_count INTEGER NOT NULL DEFAULT 0,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        hints_used INTEGER NOT NULL DEFAULT 0,
        total_time_seconds INTEGER NOT NULL DEFAULT 0,
        last_practiced_at TEXT
      )
    ''');

    // Cached lessons — both AI-generated and bundled fallback content,
    // so repeated visits to the same topic don't re-hit the AI API.
    await db.execute('''
      CREATE TABLE cached_lessons (
        lesson_id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        course_id TEXT NOT NULL,
        json_payload TEXT NOT NULL,
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        cached_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cached_lessons_topic ON cached_lessons(topic_id)',
    );

    await db.execute('''
      CREATE TABLE daily_challenges (
        challenge_date TEXT PRIMARY KEY,
        json_payload TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed the single user_progress row.
    await db.insert('user_progress', <String, Object?>{
      'id': 1,
      'total_xp': 0,
      'current_streak': 0,
      'longest_streak': 0,
      'lessons_completed': 0,
      'projects_completed': 0,
      'active_course_id': 'python',
    });
  }

  Future<void> close() async {
    final Database? db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
