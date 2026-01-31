import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_config.dart';

enum AiValidateFailureType {
  configIncomplete,
  badUrl,
  timeout,
  connectionFailed,
  httpNon200,
  jsonParse,
  responseSchema,
  unknown,
}

class AiValidationResult {
  const AiValidationResult._({
    required this.ok,
    this.type,
    this.detail,
    this.httpStatusCode,
  });

  final bool ok;
  final AiValidateFailureType? type;
  final String? detail;
  final int? httpStatusCode;

  factory AiValidationResult.ok() => const AiValidationResult._(ok: true);

  factory AiValidationResult.fail(
    AiValidateFailureType type, {
    String? detail,
    int? httpStatusCode,
  }) {
    return AiValidationResult._(
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

Future<AiValidationResult> validateAiConfig(
  AiConfig cfg, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (!cfg.isComplete) {
    return AiValidationResult.fail(AiValidateFailureType.configIncomplete);
  }

  Uri uri;
  try {
    final baseUrl = _normalizeBaseUrl(cfg.baseUrl);
    uri = Uri.parse('$baseUrl/chat/completions');
  } catch (e) {
    return AiValidationResult.fail(AiValidateFailureType.badUrl, detail: e.toString());
  }

  final client = HttpClient();
  client.connectionTimeout = timeout;

  try {
    final req = await client.postUrl(uri).timeout(timeout);
    req.headers.contentType = ContentType.json;
    req.headers.set('Authorization', 'Bearer ${cfg.apiKey}');

    final body = <String, Object?>{
      'model': cfg.model,
      'messages': const [
        {'role': 'user', 'content': 'ping'},
      ],
      'max_tokens': 1,
    };
    req.add(utf8.encode(jsonEncode(body)));

    final resp = await req.close().timeout(timeout);
    final status = resp.statusCode;

    // Avoid huge payloads; cap collected bytes.
    const maxBytes = 2000;
    final bytes = <int>[];
    await for (final chunk in resp) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBytes) break;
    }
    final text = utf8.decode(bytes, allowMalformed: true);

    if (status != 200) {
      final snippet = text.isEmpty ? '<empty>' : text;
      return AiValidationResult.fail(
        AiValidateFailureType.httpNon200,
        httpStatusCode: status,
        detail: snippet,
      );
    }

    // Minimal schema check for an OpenAI-compatible response.
    try {
      final raw = jsonDecode(text);
      if (raw is! Map) return AiValidationResult.fail(AiValidateFailureType.responseSchema);
      final choices = raw['choices'];
      if (choices is! List || choices.isEmpty) {
        return AiValidationResult.fail(AiValidateFailureType.responseSchema);
      }
    } catch (e) {
      return AiValidationResult.fail(AiValidateFailureType.jsonParse, detail: e.toString());
    }

    return AiValidationResult.ok();
  } on TimeoutException catch (e) {
    return AiValidationResult.fail(AiValidateFailureType.timeout, detail: e.toString());
  } on SocketException catch (e) {
    return AiValidationResult.fail(AiValidateFailureType.connectionFailed, detail: e.toString());
  } catch (e) {
    return AiValidationResult.fail(AiValidateFailureType.unknown, detail: e.toString());
  } finally {
    client.close(force: true);
  }
}
