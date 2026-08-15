import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../core/storage/app_database.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/adaptive_engine.dart';
import '../services/ai/ai_service.dart';
import '../services/lesson_engine/lesson_generator.dart';

/// Single source of truth for obtaining a [Lesson] to show the user.
///
/// Resolution order:
///  1. Local cache (`cached_lessons` table) — instant, no network, works
///     fully offline, avoids re-spending API budget on repeat visits.
///  2. AI generation via [LessonGenerator] (OpenAI → Groq fallback under
///     the hood), tailored to the user's adaptive plan. On success, the
///     result is cached for next time.
///  3. Bundled fallback content shipped in assets/data/fallback_lessons —
///     used when offline, when both AI providers are unavailable, or when
///     AI generation fails validation repeatedly.
///
/// The caller never needs to know which path was taken; a broken or
/// half-generated lesson is never returned.
class LessonRepository {
  LessonRepository({
    required AIService aiService,
    AppDatabase? db,
    Logger? logger,
    AdaptiveEngine? adaptiveEngine,
  })  : _generator = LessonGenerator(aiService: aiService, logger: logger),
        _db = db ?? AppDatabase.instance,
        _logger = logger ?? Logger(),
        _adaptiveEngine = adaptiveEngine ?? const AdaptiveEngine();

  final LessonGenerator _generator;
  final AppDatabase _db;
  final Logger _logger;
  final AdaptiveEngine _adaptiveEngine;

  /// In-memory cache of parsed fallback bundles, keyed by courseId, to
  /// avoid re-reading/re-parsing the asset JSON on every lesson request.
  final Map<String, List<Lesson>> _fallbackCache = <String, List<Lesson>>{};

  Future<Lesson> getLesson({
    required String courseId,
    required String courseTitle,
    required String topicId,
    required String topicTitle,
    required LessonDifficulty baseDifficulty,
    required UserProgress userProgress,
    bool forceRegenerate = false,
  }) async {
    if (!forceRegenerate) {
      final Lesson? cached = await _readFromCache(topicId);
      if (cached != null) {
        _logger.i('Lesson "$topicId" served from cache');
        return cached;
      }
    }

    final AdaptivePlan plan = _adaptiveEngine.planFor(
      progress: userProgress,
      topicId: topicId,
      baseDifficulty: baseDifficulty,
    );

    try {
      final Lesson generated = await _generator.generateLesson(
        courseId: courseId,
        courseTitle: courseTitle,
        topicId: topicId,
        topicTitle: topicTitle,
        difficulty: plan.difficulty,
        strugglingTopics: plan.reinforceTopics,
        masteredTopics: plan.skipBasicsFor,
      );
      await _writeToCache(generated);
      return generated;
    } catch (e) {
      _logger.w('AI lesson generation unavailable for "$topicId" ($e), using bundled fallback');
      final Lesson? fallback = await _readBundledFallback(courseId: courseId, topicId: topicId);
      if (fallback != null) {
        await _writeToCache(fallback);
        return fallback;
      }
      rethrow;
    }
  }

  Future<Lesson?> _readFromCache(String topicId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'cached_lessons',
      where: 'topic_id = ?',
      whereArgs: <Object?>[topicId],
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final Map<String, dynamic> json =
          jsonDecode(rows.first['json_payload'] as String) as Map<String, dynamic>;
      final Lesson lesson = Lesson.fromJson(json);
      return lesson.validate().isEmpty ? lesson : null;
    } catch (e) {
      _logger.w('Corrupt cache entry for "$topicId": $e');
      return null;
    }
  }

  Future<void> _writeToCache(Lesson lesson) async {
    final Database db = await _db.database;
    await db.insert(
      'cached_lessons',
      <String, Object?>{
        'lesson_id': lesson.id,
        'topic_id': lesson.topicId,
        'course_id': lesson.courseId,
        'json_payload': jsonEncode(lesson.toJson()),
        'is_ai_generated': lesson.isAiGenerated ? 1 : 0,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads a hand-authored fallback lesson bundled in assets. Expected
  /// path: assets/data/fallback_lessons/<courseId>.json, containing a
  /// JSON array of Lesson objects (see that file for the exact shape).
  Future<Lesson?> _readBundledFallback({
    required String courseId,
    required String topicId,
  }) async {
    List<Lesson>? lessons = _fallbackCache[courseId];
    if (lessons == null) {
      try {
        final String raw =
            await rootBundle.loadString('assets/data/fallback_lessons/$courseId.json');
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        lessons = decoded
            .map((dynamic e) => Lesson.fromJson(e as Map<String, dynamic>))
            .where((Lesson l) => l.validate().isEmpty)
            .toList();
        _fallbackCache[courseId] = lessons;
      } catch (e) {
        _logger.e('No bundled fallback content for course "$courseId": $e');
        return null;
      }
    }

    for (final Lesson l in lessons) {
      if (l.topicId == topicId) return l;
    }
    return null;
  }
}
