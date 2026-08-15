import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/ai_config.dart';
import 'ai_provider.dart';

/// OpenAI Chat Completions provider. Uses `response_format: json_object`
/// so the model is constrained to return valid JSON, which we still
/// validate downstream in AIService/LessonRepository before ever showing
/// content to the user.
class OpenAIProvider implements AIProvider {
  OpenAIProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  @override
  String get name => 'OpenAI';

  @override
  bool get isConfigured => AIConfig.hasOpenAiKey;

  @override
  Future<String> generateJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      throw AIProviderException('OpenAI API key not configured', isRetryable: false);
    }

    final Uri uri = Uri.parse(_endpoint);
    final Map<String, dynamic> body = <String, dynamic>{
      'model': AIConfig.openAiModel,
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
              'Authorization': 'Bearer ${AIConfig.openAiApiKey}',
            },
            body: jsonEncode(body),
          )
          .timeout(AIConfig.requestTimeout);
    } catch (e) {
      throw AIProviderException('OpenAI network error: $e', isRetryable: true);
    }

    return _handleResponse(response);
  }

  String _handleResponse(http.Response response) {
    // Auth failures: not worth retrying immediately, but fallback should
    // still proceed to Groq.
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIProviderException(
        'OpenAI auth failed (${response.statusCode})',
        isRetryable: false,
        statusCode: response.statusCode,
      );
    }

    // Rate limit / quota exceeded — classic fallback trigger.
    if (response.statusCode == 429) {
      throw AIProviderException(
        'OpenAI rate limit or quota exceeded',
        isRetryable: false,
        statusCode: 429,
      );
    }

    if (response.statusCode >= 500) {
      throw AIProviderException(
        'OpenAI server error (${response.statusCode})',
        isRetryable: true,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200) {
      throw AIProviderException(
        'OpenAI request failed (${response.statusCode}): ${response.body}',
        isRetryable: false,
        statusCode: response.statusCode,
      );
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> choices = decoded['choices'] as List<dynamic>? ?? const <dynamic>[];
      if (choices.isEmpty) {
        throw AIProviderException('OpenAI returned no choices', isRetryable: true);
      }
      final Map<String, dynamic> message =
          (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      final String? content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AIProviderException('OpenAI returned empty content', isRetryable: true);
      }
      return content;
    } on AIProviderException {
      rethrow;
    } catch (e) {
      throw AIProviderException('Failed to parse OpenAI response: $e', isRetryable: true);
    }
  }
}
