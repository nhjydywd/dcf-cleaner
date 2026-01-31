import 'package:dcf_cleaner/ai/ai_suggest_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tryParseAiSuggestion parses tagged output', () {
    const raw = '''
[[DCF_SUMMARY]]
This is summary.
[[DCF_ADVICE]]
Delete it.
[[DCF_END]]
''';

    final parsed = tryParseAiSuggestion(raw);
    expect(parsed, isNotNull);
    expect(parsed!.summary, 'This is summary.');
    expect(parsed.advice, 'Delete it.');
  });

  test('tryParseAiSuggestion returns null on untagged output', () {
    const raw = 'Hello **world**';
    expect(tryParseAiSuggestion(raw), isNull);
  });
}

