import 'dart:convert';

import 'package:logger/logger.dart';

import '../../models/exercise.dart';
import '../ai/ai_service.dart';
import 'lesson_prompt_builder.dart';

/// Thrown when AI generation of today's exercise failed validation even
/// after retries, or no provider is available. Callers fall back to the
/// bundled challenge pool — the user must never see a broken challenge.
class DailyChallengeGenerationFailedException implements Exception {
  DailyChallengeGenerationFailedException(this.reason);
  final String reason;

  @override
  String toString() => 'DailyChallengeGenerationFailedException: $reason';
}

/// Generates a single structured [Exercise] for today's Daily Challenge
/// via [AIService] (OpenAI → Groq fallback under the hood), validating
/// the response the same way [LessonGenerator] does for full lessons.
class DailyChallengeGenerator {
  DailyChallengeGenerator({required AIService aiService, Logger? logger})
      : _aiService = aiService,
        _logger = logger ?? Logger();

  final AIService _aiService;
  final Logger _logger;

  static const int _maxValidationRetries = 2;

  Future<Exercise> generate({
    required String topicTitle,
    required String difficulty,
    List<String> recentTopicLabels = const <String>[],
  }) async {
    final String systemPrompt = LessonPromptBuilder.dailyChallengeSystemPrompt();
    final String userPrompt = LessonPromptBuilder.dailyChallengeUserPrompt(
      topicTitle: topicTitle,
      difficulty: difficulty,
      recentTopicLabels: recentTopicLabels,
    );

    String effectivePrompt = userPrompt;

    for (int attempt = 0; attempt <= _maxValidationRetries; attempt++) {
      final AIGenerationResult result = await _aiService.generate(
        systemPrompt: systemPrompt,
        userPrompt: effectivePrompt,
      );

      final Exercise? parsed = _tryParse(result.rawJson);
      if (parsed == null) {
        _logger.w('Daily challenge JSON parse failed on attempt $attempt (${result.providerName})');
        effectivePrompt = '$userPrompt\n\nYour previous response was not valid JSON matching '
            'the required shape. Return ONLY the corrected JSON object.';
        continue;
      }

      final String? error = parsed.validate();
      if (error == null) {
        _logger.i('Daily challenge generated successfully via ${result.providerName}');
        return parsed;
      }

      _logger.w('Daily challenge validation failed on attempt $attempt: $error');
      effectivePrompt =
          '$userPrompt\n\nYour previous response had this problem: $error. '
          'Return ONLY a corrected JSON object fixing it.';
    }

    throw DailyChallengeGenerationFailedException(
      'Daily challenge generation failed validation after $_maxValidationRetries retries',
    );
  }

  Exercise? _tryParse(String rawJson) {
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(_stripCodeFences(rawJson)) as Map<String, dynamic>;
      return Exercise.fromJson(decoded);
    } catch (e) {
      _logger.w('Failed to parse daily challenge JSON: $e');
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
