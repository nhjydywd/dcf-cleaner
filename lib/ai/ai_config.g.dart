// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiConfig _$AiConfigFromJson(Map<String, dynamic> json) => AiConfig(
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
      model: json['model'] as String,
    );

Map<String, dynamic> _$AiConfigToJson(AiConfig instance) => <String, dynamic>{
      'apiKey': instance.apiKey,
      'baseUrl': instance.baseUrl,
      'model': instance.model,
    };
