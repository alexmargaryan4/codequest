/// Thrown by an [AIProvider] when a request fails for a reason that
/// should trigger fallback to the next provider (auth error, rate limit,
/// quota exceeded, timeout, malformed response after retries, etc).
class AIProviderException implements Exception {
  AIProviderException(this.message, {this.isRetryable = true, this.statusCode});

  final String message;

  /// If false, retrying this same provider immediately is pointless
  /// (e.g. invalid API key) — AIService should skip straight to fallback
  /// and put this provider in cooldown.
  final bool isRetryable;

  final int? statusCode;

  @override
  String toString() => 'AIProviderException($statusCode): $message';
}

/// A provider-agnostic contract for "generate structured JSON content from
/// a prompt". Both [OpenAIProvider] and [GroqProvider] implement this so
/// [AIService] never needs to know which concrete API it's talking to.
abstract class AIProvider {
  /// Human-readable name for logging/debugging (e.g. "OpenAI", "Groq").
  String get name;

  /// Sends [systemPrompt] + [userPrompt] to the underlying model and
  /// returns the raw text response, which the caller (AIService) is
  /// responsible for parsing as JSON and validating.
  ///
  /// Implementations should:
  ///  - use the provider's structured-output / JSON-mode feature when
  ///    available, to maximize the odds of getting valid JSON back;
  ///  - throw [AIProviderException] on any failure (network, auth, rate
  ///    limit, timeout, non-2xx response);
  ///  - respect the configured request timeout.
  Future<String> generateJson({
    required String systemPrompt,
    required String userPrompt,
  });

  /// Whether this provider is currently configured (has an API key).
  /// AIService skips unconfigured providers entirely rather than trying
  /// and failing.
  bool get isConfigured;
}
