import 'dart:convert';

import 'package:logger/logger.dart';

import '../../models/lesson.dart';
import '../ai/ai_service.dart';
import 'lesson_prompt_builder.dart';

/// Thrown when AI generation succeeded at the network level but produced
/// content that failed structural validation even after retries, or when
/// all providers are unavailable. Callers should catch this and fall back
/// to cached/bundled lessons — the user must never see a broken lesson.
class LessonGenerationFailedException implements Exception {
  LessonGenerationFailedException(this.reason);
  final String reason;

  @override
  String toString() => 'LessonGenerationFailedException: $reason';
}

/// Generates a single structured [Lesson] via [AIService], validating the
/// response and requesting a corrected version if it's malformed before
/// ever handing content back to the UI.
class LessonGenerator {
  LessonGenerator({required AIService aiService, Logger? logger})
      : _aiService = aiService,
        _logger = logger ?? Logger();

  final AIService _aiService;
  final Logger _logger;

  static const int _maxValidationRetries = 2;

  Future<Lesson> generateLesson({
    required String courseId,
    required String courseTitle,
    required String topicId,
    required String topicTitle,
    required String difficulty,
    List<String> strugglingTopics = const <String>[],
    List<String> masteredTopics = const <String>[],
  }) async {
    final String systemPrompt = LessonPromptBuilder.lessonSystemPrompt(courseTitle: courseTitle);
    final String userPrompt = LessonPromptBuilder.lessonUserPrompt(
      courseId: courseId,
      courseTitle: courseTitle,
      topicId: topicId,
      topicTitle: topicTitle,
      difficulty: difficulty,
      strugglingTopics: strugglingTopics,
      masteredTopics: masteredTopics,
    );

    String effectiveUserPrompt = userPrompt;
    String lastProviderName = 'unknown';

    for (int attempt = 0; attempt <= _maxValidationRetries; attempt++) {
      final AIGenerationResult result = await _aiService.generate(
        systemPrompt: systemPrompt,
        userPrompt: effectiveUserPrompt,
      );
      lastProviderName = result.providerName;

      final Lesson? parsed = _tryParse(result.rawJson, courseId: courseId, topicId: topicId);
      if (parsed == null) {
        _logger.w('Lesson JSON parse failed on attempt $attempt (${result.providerName})');
        effectiveUserPrompt =
            '$userPrompt\n\nYour previous response was not valid JSON matching the '
            'required shape. Return ONLY the corrected JSON object.';
        continue;
      }

      final List<String> errors = parsed.validate();
      if (errors.isEmpty) {
        _logger.i('Lesson "$topicId" generated successfully via $lastProviderName');
        return parsed.copyWith().let(
              (Lesson l) => Lesson(
                id: l.id,
                title: l.title,
                description: l.description,
                topicId: l.topicId,
                courseId: l.courseId,
                difficulty: l.difficulty,
                exercises: l.exercises,
                status: l.status,
                orderIndex: l.orderIndex,
                xpReward: l.xpReward,
                isAiGenerated: true,
                generatedAt: DateTime.now(),
              ),
            );
      }

      _logger.w('Lesson validation failed on attempt $attempt: ${errors.join("; ")}');
      effectiveUserPrompt = '$userPrompt\n\nYour previous response had these problems: '
          '${errors.join("; ")}. Return ONLY a corrected JSON object fixing them.';
    }

    throw LessonGenerationFailedException(
      'Lesson "$topicId" failed validation after $_maxValidationRetries retries '
      '(last provider: $lastProviderName)',
    );
  }

  Lesson? _tryParse(String rawJson, {required String courseId, required String topicId}) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(_stripCodeFences(rawJson)) as Map<String, dynamic>;
      // Ensure courseId/topicId match what we asked for even if the model
      // drifted — this keeps the cache key and course-map wiring correct.
      decoded['courseId'] = decoded['courseId'] ?? courseId;
      decoded['topicId'] = decoded['topicId'] ?? topicId;
      return Lesson.fromJson(decoded);
    } catch (e) {
      _logger.w('Failed to parse lesson JSON: $e');
      return null;
    }
  }

  String _stripCodeFences(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(json)?'), '').trim();
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }
    return cleaned;
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
