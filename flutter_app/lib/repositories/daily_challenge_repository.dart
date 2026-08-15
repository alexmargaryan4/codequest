import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/daily_challenge.dart';
import '../models/user_progress.dart';
import '../services/ai/ai_service.dart';
import '../services/lesson_engine/daily_challenge_generator.dart';

/// Provides today's [DailyChallenge].
///
/// Resolution order mirrors [LessonRepository]:
///  1. Already-cached challenge for today's date — never regenerated
///     until the calendar day rolls over.
///  2. AI generation via [DailyChallengeGenerator] (OpenAI → Groq
///     fallback, validated before being shown).
///  3. A bundled fallback pool (assets/data/fallback_lessons/
///     daily_challenges.json), picked deterministically by date so
///     offline users still get a sensible challenge.
class DailyChallengeRepository {
  DailyChallengeRepository({
    required AIService aiService,
    AppDatabase? db,
    Logger? logger,
  })  : _generator = DailyChallengeGenerator(aiService: aiService, logger: logger),
        _db = db ?? AppDatabase.instance,
        _logger = logger ?? Logger();

  final DailyChallengeGenerator _generator;
  final AppDatabase _db;
  final Logger _logger;

  List<DailyChallenge>? _fallbackPoolCache;

  static String todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<DailyChallenge> getTodayChallenge({
    required UserProgress userProgress,
    required String topicTitle,
    required String topicId,
  }) async {
    final String dateKey = todayKey();

    final DailyChallenge? cached = await _readFromCache(dateKey);
    if (cached != null) {
      _logger.i('Daily challenge for $dateKey served from cache');
      return cached;
    }

    try {
      final difficulty = userProgress.level >= 8 ? 'hard' : (userProgress.level >= 3 ? 'medium' : 'easy');
      final exercise = await _generator.generate(
        topicTitle: topicTitle,
        difficulty: difficulty,
      );
      final DailyChallenge challenge = DailyChallenge(
        dateKey: dateKey,
        exercise: exercise,
        topicId: topicId,
        topicLabel: topicTitle,
        isAiGenerated: true,
      );
      await _writeToCache(challenge);
      return challenge;
    } catch (e) {
      _logger.w('AI daily-challenge generation unavailable ($e), using bundled fallback');
      final DailyChallenge fallback = await _pickBundledFallback(dateKey: dateKey);
      await _writeToCache(fallback);
      return fallback;
    }
  }

  Future<void> markCompleted(String dateKey) async {
    final Database db = await _db.database;
    await db.update(
      'daily_challenges',
      <String, Object?>{'completed': 1},
      where: 'challenge_date = ?',
      whereArgs: <Object?>[dateKey],
    );
  }

  Future<DailyChallenge?> _readFromCache(String dateKey) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'daily_challenges',
      where: 'challenge_date = ?',
      whereArgs: <Object?>[dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final Map<String, dynamic> json =
          jsonDecode(rows.first['json_payload'] as String) as Map<String, dynamic>;
      final DailyChallenge challenge = DailyChallenge.fromJson(json).copyWith(
        completed: (rows.first['completed'] as int? ?? 0) == 1,
      );
      return challenge.isValid ? challenge : null;
    } catch (e) {
      _logger.w('Corrupt daily challenge cache entry for $dateKey: $e');
      return null;
    }
  }

  Future<void> _writeToCache(DailyChallenge challenge) async {
    final Database db = await _db.database;
    await db.insert(
      'daily_challenges',
      <String, Object?>{
        'challenge_date': challenge.dateKey,
        'json_payload': jsonEncode(challenge.toJson()),
        'completed': challenge.completed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyChallenge> _pickBundledFallback({required String dateKey}) async {
    final List<DailyChallenge> pool = await _loadFallbackPool();
    if (pool.isEmpty) {
      throw DailyChallengeGenerationFailedException(
        'No bundled daily-challenge fallback content available',
      );
    }
    // Deterministic-by-date pick so everyone offline on the same day
    // sees a stable (not randomly re-rolled on every app restart)
    // challenge, without needing any network or server coordination.
    final int seed = dateKey.hashCode;
    final DailyChallenge picked = pool[Random(seed).nextInt(pool.length)];
    return DailyChallenge(
      dateKey: dateKey,
      exercise: picked.exercise,
      topicId: picked.topicId,
      topicLabel: picked.topicLabel,
      xpReward: picked.xpReward,
      isAiGenerated: false,
    );
  }

  Future<List<DailyChallenge>> _loadFallbackPool() async {
    if (_fallbackPoolCache != null) return _fallbackPoolCache!;
    try {
      final String raw =
          await rootBundle.loadString('assets/data/fallback_lessons/daily_challenges.json');
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _fallbackPoolCache = decoded
          .map((dynamic e) => DailyChallenge.fromJson(e as Map<String, dynamic>))
          .where((DailyChallenge c) => c.isValid)
          .toList();
    } catch (e) {
      _logger.e('Failed to load bundled daily challenge pool: $e');
      _fallbackPoolCache = <DailyChallenge>[];
    }
    return _fallbackPoolCache!;
  }
}
