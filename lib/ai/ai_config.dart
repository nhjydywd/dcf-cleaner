import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'ai_config.g.dart';

@JsonSerializable()
class AiConfig {
  const AiConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  bool get isComplete => apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  AiConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }

  static AiConfig empty() => const AiConfig(apiKey: '', baseUrl: '', model: '');

  factory AiConfig.fromJson(Map<String, dynamic> json) => _$AiConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AiConfigToJson(this);
}

class AiConfigRepository {
  AiConfigRepository._();

  static final AiConfigRepository instance = AiConfigRepository._();

  AiConfig _cached = AiConfig.empty();
  bool _loaded = false;

  AiConfig get cached => _cached;

  void updateCached(AiConfig cfg) {
    _cached = cfg;
    _loaded = true;
  }

  Future<AiConfig> load() async {
    if (_loaded) return _cached;
    _loaded = true;
    final file = await _configFile();
    if (!await file.exists()) {
      _cached = AiConfig.empty();
      return _cached;
    }
    try {
      final txt = await file.readAsString();
      final raw = jsonDecode(txt);
      if (raw is Map) _cached = AiConfig.fromJson(raw.cast<String, dynamic>());
    } catch (_) {
      // If config is corrupted, treat it as empty (user can re-configure).
      _cached = AiConfig.empty();
    }
    return _cached;
  }

  Future<void> save(AiConfig cfg) async {
    updateCached(cfg);
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(cfg.toJson()));
  }

  Future<File> _configFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'ai_config.json'));
  }
}
