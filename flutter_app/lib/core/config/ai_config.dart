/// Central configuration for AI provider credentials and behavior.
///
/// Values are injected at BUILD TIME via `--dart-define`, e.g.:
///
///   flutter build apk \
///     --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
///     --dart-define=GROQ_API_KEY=$GROQ_API_KEY
///
/// No secret ever lives in source control. In GitHub Actions these values
/// come from `secrets.OPENAI_API_KEY` / `secrets.GROQ_API_KEY`.
///
/// IMPORTANT: `--dart-define` values are still embedded in the compiled
/// binary and can be extracted by a sufficiently motivated attacker via
/// APK/IPA reverse engineering. This is acceptable for early development,
/// but before shipping to production with paid API keys, route AI calls
/// through a thin backend proxy (or serverless function) that holds the
/// real keys server-side. The [AIConfig] abstraction below is intentionally
/// isolated so that swapping "call OpenAI directly" for "call my proxy"
/// later requires touching only [AIConfig] and the provider classes —
/// not any UI or feature code.
class AIConfig {
  const AIConfig._();

  /// OpenAI API key, injected via --dart-define=OPENAI_API_KEY=...
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Groq API key, injected via --dart-define=GROQ_API_KEY=...
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// OpenAI model used for lesson / exercise generation.
  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// Groq model used as fallback.
  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasGroqKey => groqApiKey.isNotEmpty;

  /// True if at least one live AI provider is configured. When false, the
  /// app must rely entirely on bundled/cached lessons and never attempt
  /// a network call.
  static bool get hasAnyProvider => hasOpenAiKey || hasGroqKey;

  /// Request timeout for AI calls, generous enough for structured JSON
  /// generation but bounded so a hung request doesn't block the UI.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// How many times AIService retries a single provider (e.g. on a
  /// malformed-JSON response) before moving to the next provider in line.
  static const int maxRetriesPerProvider = 2;

  /// After this many consecutive failures, a provider is put in "cooldown"
  /// and skipped for [providerCooldown] even if asked again, to avoid
  /// hammering a provider that's clearly down.
  static const int consecutiveFailuresBeforeCooldown = 3;

  static const Duration providerCooldown = Duration(minutes: 5);
}
