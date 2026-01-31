class ParsedAiSuggestion {
  const ParsedAiSuggestion({
    required this.summary,
    required this.advice,
  });

  final String summary;
  final String advice;
}

const String kAiTagSummary = '[[DCF_SUMMARY]]';
const String kAiTagAdvice = '[[DCF_ADVICE]]';
const String kAiTagEnd = '[[DCF_END]]';

ParsedAiSuggestion? tryParseAiSuggestion(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final s = text.indexOf(kAiTagSummary);
  final a = text.indexOf(kAiTagAdvice);
  if (s < 0 || a < 0 || a <= s) return null;

  final end = text.indexOf(kAiTagEnd, a);
  final endIndex = end < 0 ? text.length : end;

  final summary = text.substring(s + kAiTagSummary.length, a).trim();
  final advice = text.substring(a + kAiTagAdvice.length, endIndex).trim();

  if (summary.isEmpty || advice.isEmpty) return null;
  return ParsedAiSuggestion(summary: summary, advice: advice);
}

