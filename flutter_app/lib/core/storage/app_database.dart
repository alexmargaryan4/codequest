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
  static const int _dbVersion = 2;

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
      onUpgrade: _onUpgrade,
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

    await _createEconomyTables(db);

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

    await _seedEconomyRows(db);
  }

  /// Hearts / gems / weekly-quests tables, added in schema v2. Split into
  /// its own method so both a fresh install ([_onCreate]) and an
  /// existing v1 database ([_onUpgrade]) can create them identically.
  Future<void> _createEconomyTables(Database db) async {
    await db.execute('''
      CREATE TABLE hearts_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current INTEGER NOT NULL DEFAULT 5,
        last_lost_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gems_wallet (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        balance INTEGER NOT NULL DEFAULT 0,
        streak_freeze_available INTEGER NOT NULL DEFAULT 0,
        xp_boost_active_until TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE weekly_quests (
        id TEXT NOT NULL,
        week_key TEXT NOT NULL,
        metric TEXT NOT NULL,
        target INTEGER NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        gems_reward INTEGER NOT NULL DEFAULT 0,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        claimed_at TEXT,
        PRIMARY KEY (id, week_key)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_weekly_quests_week ON weekly_quests(week_key)',
    );
  }

  Future<void> _seedEconomyRows(Database db) async {
    await db.insert('hearts_state', <String, Object?>{
      'id': 1,
      'current': 5,
      'last_lost_at': null,
    });
    await db.insert('gems_wallet', <String, Object?>{
      'id': 1,
      'balance': 20,
      'streak_freeze_available': 0,
      'xp_boost_active_until': null,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createEconomyTables(db);
      await _seedEconomyRows(db);
    }
  }

  Future<void> close() async {
    final Database? db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
