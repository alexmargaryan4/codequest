import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/ai_config.dart';
import 'ai_provider.dart';

/// Groq's OpenAI-compatible Chat Completions provider. Used as the
/// fallback whenever [OpenAIProvider] is unavailable, rate-limited, or
/// erroring.
class GroqProvider implements AIProvider {
  GroqProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  String get name => 'Groq';

  @override
  bool get isConfigured => AIConfig.hasGroqKey;

  @override
  Future<String> generateJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      throw AIProviderException('Groq API key not configured', isRetryable: false);
    }

    final Uri uri = Uri.parse(_endpoint);
    final Map<String, dynamic> body = <String, dynamic>{
      'model': AIConfig.groqModel,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': userPrompt},
      ],
      'response_format': <String, String>{'type': 'json_object'},
      'temperature': 0.7,
    };

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AIConfig.groqApiKey}',
            },
            body: jsonEncode(body),
          )
          .timeout(AIConfig.requestTimeout);
    } catch (e) {
      throw AIProviderException('Groq network error: $e', isRetryable: true);
    }

    return _handleResponse(response);
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIProviderException(
        'Groq auth failed (${response.statusCode})',
        isRetryable: false,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 429) {
      throw AIProviderException(
        'Groq rate limit exceeded',
        isRetryable: false,
        statusCode: 429,
      );
    }

    if (response.statusCode >= 500) {
      throw AIProviderException(
        'Groq server error (${response.statusCode})',
        isRetryable: true,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200) {
      throw AIProviderException(
        'Groq request failed (${response.statusCode}): ${response.body}',
        isRetryable: false,
        statusCode: response.statusCode,
      );
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> choices = decoded['choices'] as List<dynamic>? ?? const <dynamic>[];
      if (choices.isEmpty) {
        throw AIProviderException('Groq returned no choices', isRetryable: true);
      }
      final Map<String, dynamic> message =
          (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      final String? content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AIProviderException('Groq returned empty content', isRetryable: true);
      }
      return content;
    } on AIProviderException {
      rethrow;
    } catch (e) {
      throw AIProviderException('Failed to parse Groq response: $e', isRetryable: true);
    }
  }
}
