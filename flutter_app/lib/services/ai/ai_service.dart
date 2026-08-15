import 'dart:async';

import 'package:logger/logger.dart';

import '../../core/config/ai_config.dart';
import 'ai_provider.dart';
import 'groq_provider.dart';
import 'openai_provider.dart';

/// Result wrapper so callers know whether the content came from a live
/// AI provider (and which one) or should be treated as unavailable.
class AIGenerationResult {
  const AIGenerationResult({
    required this.rawJson,
    required this.providerName,
  });

  final String rawJson;
  final String providerName;
}

/// Thrown when every configured provider failed (or none are configured).
/// Callers (LessonRepository, DailyChallengeService, etc.) should catch
/// this and fall back to bundled/cached content — never surface it as a
/// raw error to the user.
class AllProvidersUnavailableException implements Exception {
  AllProvidersUnavailableException(this.attempts);
  final Map<String, String> attempts; // provider name -> failure reason

  @override
  String toString() => 'All AI providers unavailable: $attempts';
}

/// Tracks a provider's recent health so a provider that's clearly down
/// doesn't get hammered with retries on every single lesson request.
class _ProviderHealth {
  int consecutiveFailures = 0;
  DateTime? cooldownUntil;

  bool get isInCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  void recordSuccess() {
    consecutiveFailures = 0;
    cooldownUntil = null;
  }

  void recordFailure() {
    consecutiveFailures++;
    if (consecutiveFailures >= AIConfig.consecutiveFailuresBeforeCooldown) {
      cooldownUntil = DateTime.now().add(AIConfig.providerCooldown);
    }
  }
}

/// The single entry point for all AI content generation in the app.
///
/// Every feature (lesson generation, hint generation, daily challenge,
/// mini-project feedback, prompt-engineering grading) calls through
/// [AIService.generate] — nothing in the app talks to OpenAIProvider or
/// GroqProvider directly. This keeps the fallback policy (OpenAI first,
/// Groq second, then "unavailable") defined in exactly one place.
///
/// Policy:
///  1. Try OpenAI. Retry it up to [AIConfig.maxRetriesPerProvider] times
///     for retryable failures (timeouts, 5xx, malformed JSON).
///  2. If OpenAI fails definitively (or is unconfigured / in cooldown),
///     try Groq the same way.
///  3. If both fail, throw [AllProvidersUnavailableException] — the
///     caller is expected to fall back to cached/bundled content.
///  4. OpenAI is always retried first on the *next* call — there is no
///     manual "switch provider" step. A provider only skips its turn
///     while [_ProviderHealth.isInCooldown] is true, and cooldown always
///     expires on its own, restoring OpenAI-first behavior automatically.
class AIService {
  AIService({
    AIProvider? openAiProvider,
    AIProvider? groqProvider,
    Logger? logger,
  })  : _logger = logger ?? Logger(),
        _providers = <AIProvider>[
          openAiProvider ?? OpenAIProvider(),
          groqProvider ?? GroqProvider(),
        ] {
    for (final AIProvider p in _providers) {
      _health[p.name] = _ProviderHealth();
    }
  }

  final Logger _logger;

  /// Ordered by priority: index 0 (OpenAI) is always attempted first.
  final List<AIProvider> _providers;
  final Map<String, _ProviderHealth> _health = <String, _ProviderHealth>{};

  bool get hasAnyConfiguredProvider => _providers.any((AIProvider p) => p.isConfigured);

  /// Generates raw JSON text from [systemPrompt] + [userPrompt], trying
  /// providers in priority order. Returns which provider actually served
  /// the request so callers can tag content as isAiGenerated / log
  /// analytics if desired.
  Future<AIGenerationResult> generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final Map<String, String> failures = <String, String>{};

    for (final AIProvider provider in _providers) {
      if (!provider.isConfigured) {
        failures[provider.name] = 'not configured';
        continue;
      }

      final _ProviderHealth health = _health[provider.name]!;
      if (health.isInCooldown) {
        failures[provider.name] = 'in cooldown until ${health.cooldownUntil}';
        _logger.i('${provider.name} skipped (cooldown active)');
        continue;
      }

      final String? result = await _tryProviderWithRetries(provider, systemPrompt, userPrompt);
      if (result != null) {
        health.recordSuccess();
        return AIGenerationResult(rawJson: result, providerName: provider.name);
      }

      health.recordFailure();
      failures[provider.name] = 'failed after retries';
    }

    throw AllProvidersUnavailableException(failures);
  }

  Future<String?> _tryProviderWithRetries(
    AIProvider provider,
    String systemPrompt,
    String userPrompt,
  ) async {
    for (int attempt = 0; attempt <= AIConfig.maxRetriesPerProvider; attempt++) {
      try {
        final String result = await provider.generateJson(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        return result;
      } on AIProviderException catch (e) {
        _logger.w('${provider.name} attempt ${attempt + 1} failed: $e');
        if (!e.isRetryable) {
          // Non-retryable (bad key, quota gone): stop retrying this
          // provider immediately and let AIService move to fallback.
          return null;
        }
        if (attempt == AIConfig.maxRetriesPerProvider) {
          return null;
        }
        // Small backoff before retrying the same provider.
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      } catch (e) {
        _logger.e('${provider.name} unexpected error: $e');
        return null;
      }
    }
    return null;
  }
}
