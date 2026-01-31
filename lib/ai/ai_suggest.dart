import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_config.dart';

enum AiSuggestFailureType {
  configIncomplete,
  badUrl,
  timeout,
  connectionFailed,
  httpNon200,
  jsonParse,
  responseSchema,
  unknown,
}

class AiSuggestResult {
  const AiSuggestResult._({
    required this.ok,
    this.text,
    this.type,
    this.detail,
    this.httpStatusCode,
  });

  final bool ok;
  final String? text;
  final AiSuggestFailureType? type;
  final String? detail;
  final int? httpStatusCode;

  factory AiSuggestResult.ok(String text) => AiSuggestResult._(ok: true, text: text);

  factory AiSuggestResult.fail(
    AiSuggestFailureType type, {
    String? detail,
    int? httpStatusCode,
  }) {
    return AiSuggestResult._(
      ok: false,
      type: type,
      detail: detail,
      httpStatusCode: httpStatusCode,
    );
  }
}

String _normalizeBaseUrl(String raw) {
  var url = raw.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

Future<AiSuggestResult> requestAiSuggestion(
  AiConfig cfg, {
  required String systemPrompt,
  required String userPrompt,
  Duration timeout = const Duration(seconds: 20),
}) async {
  if (!cfg.isComplete) {
    return AiSuggestResult.fail(AiSuggestFailureType.configIncomplete);
  }

  Uri uri;
  try {
    final baseUrl = _normalizeBaseUrl(cfg.baseUrl);
    uri = Uri.parse('$baseUrl/chat/completions');
  } catch (e) {
    return AiSuggestResult.fail(AiSuggestFailureType.badUrl, detail: e.toString());
  }

  final client = HttpClient();
  client.connectionTimeout = timeout;

  try {
    final req = await client.postUrl(uri).timeout(timeout);
    req.headers.contentType = ContentType.json;
    req.headers.set('Authorization', 'Bearer ${cfg.apiKey}');

    final body = <String, Object?>{
      'model': cfg.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.2,
      // Best-effort cap. Still rely on the prompt instruction to keep it short.
      'max_tokens': 300,
    };
    req.add(utf8.encode(jsonEncode(body)));

    final resp = await req.close().timeout(timeout);
    final status = resp.statusCode;

    // Avoid huge payloads; cap collected bytes.
    const maxBytes = 64 * 1024;
    final bytes = <int>[];
    await for (final chunk in resp) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBytes) break;
    }
    final text = utf8.decode(bytes, allowMalformed: true);

    if (status != 200) {
      final snippet = text.isEmpty ? '<empty>' : text;
      return AiSuggestResult.fail(
        AiSuggestFailureType.httpNon200,
        httpStatusCode: status,
        detail: snippet,
      );
    }

    try {
      final raw = jsonDecode(text);
      if (raw is! Map) return AiSuggestResult.fail(AiSuggestFailureType.responseSchema);
      final choices = raw['choices'];
      if (choices is! List || choices.isEmpty) {
        return AiSuggestResult.fail(AiSuggestFailureType.responseSchema);
      }
      final first = choices.first;
      if (first is! Map) return AiSuggestResult.fail(AiSuggestFailureType.responseSchema);
      final msg = first['message'];
      if (msg is! Map) return AiSuggestResult.fail(AiSuggestFailureType.responseSchema);
      final content = msg['content'];
      if (content is! String) return AiSuggestResult.fail(AiSuggestFailureType.responseSchema);
      final out = content.trim();
      return AiSuggestResult.ok(out);
    } catch (e) {
      return AiSuggestResult.fail(AiSuggestFailureType.jsonParse, detail: e.toString());
    }
  } on TimeoutException catch (e) {
    return AiSuggestResult.fail(AiSuggestFailureType.timeout, detail: e.toString());
  } on SocketException catch (e) {
    return AiSuggestResult.fail(AiSuggestFailureType.connectionFailed, detail: e.toString());
  } catch (e) {
    return AiSuggestResult.fail(AiSuggestFailureType.unknown, detail: e.toString());
  } finally {
    client.close(force: true);
  }
}

