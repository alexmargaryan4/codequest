import 'dart:convert';

import 'package:logger/logger.dart';

import '../ai/ai_service.dart';
import 'lesson_prompt_builder.dart';

/// Provides progressive, non-spoiling hints for an exercise or mini
/// project. Prefers pre-authored hints (bundled with the content) and
/// only calls the AI for additional/dynamic hints beyond what's
/// pre-written, or when no pre-authored hints exist at all.
class HintService {
  HintService({required AIService aiService, Logger? logger})
      : _aiService = aiService,
        _logger = logger ?? Logger();

  final AIService _aiService;
  final Logger _logger;

  /// Returns the next hint to show. [previousHints] are hints already
  /// shown to this user for this exercise (both pre-authored and
  /// AI-generated), used to avoid repetition and to calibrate how
  /// specific the next hint should be.
  Future<String> getNextHint({
    required String question,
    String? codeSnippet,
    required List<String> authoredHints,
    required List<String> previousHints,
  }) async {
    final int hintLevel = previousHints.length;

    // Prefer authored hints first — they're free, instant, and
    // hand-tuned. Only reach for AI once those are exhausted.
    if (hintLevel < authoredHints.length) {
      return authoredHints[hintLevel];
    }

    if (!_aiService.hasAnyConfiguredProvider) {
      return _genericFallbackHint(hintLevel);
    }

    try {
      final AIGenerationResult result = await _aiService.generate(
        systemPrompt: LessonPromptBuilder.hintSystemPrompt(),
        userPrompt: LessonPromptBuilder.hintUserPrompt(
          question: question,
          codeSnippet: codeSnippet,
          hintLevel: hintLevel,
          previousHints: previousHints,
        ),
      );
      final Map<String, dynamic> decoded =
          jsonDecode(_stripFences(result.rawJson)) as Map<String, dynamic>;
      final String? hint = decoded['hint'] as String?;
      if (hint == null || hint.trim().isEmpty) {
        return _genericFallbackHint(hintLevel);
      }
      return hint.trim();
    } catch (e) {
      _logger.w('Hint generation failed, using generic fallback: $e');
      return _genericFallbackHint(hintLevel);
    }
  }

  String _genericFallbackHint(int hintLevel) {
    const List<String> generic = <String>[
      'Перечитай условие задачи ещё раз — какая часть кода должна что-то сделать?',
      'Попробуй разбить задачу на маленькие шаги и реши их по очереди.',
      'Проверь синтаксис: скобки, отступы, кавычки — всё ли на месте?',
    ];
    return generic[hintLevel.clamp(0, generic.length - 1)];
  }

  String _stripFences(String raw) {
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
