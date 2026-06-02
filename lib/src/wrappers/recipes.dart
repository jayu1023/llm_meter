/// Provider-specific extraction recipes — usage adapters for the
/// `tokens` field shapes OpenAI, Anthropic, and Gemini emit.
///
/// **No API keys are ever read, stored, or transmitted by this package.** The
/// recipes only know how to read `usage` blocks from a *response object you
/// already have in hand*. Bring your own client; we just measure it.
///
/// Each recipe accepts a JSON-shaped `Map<String, Object?>` because every
/// official SDK can hand you one (either directly via a `toJson()` call or
/// via `jsonDecode(response.body)`). This keeps `llm_meter` free of any
/// transitive provider SDK dependency.
library;

import 'metered_call.dart';

/// OpenAI Chat Completions / Responses API usage shape:
/// `{ usage: { prompt_tokens, completion_tokens, prompt_tokens_details:
///   { cached_tokens } } }`.
///
/// ```dart
/// final response = await MeteredCall.run(
///   provider: 'openai',
///   model: 'gpt-5',
///   call: () => myOpenAiClient.chat.completions.create(...),
///   extract: (r) => openAiUsage(r.toJson()),
/// );
/// ```
MeterUsage openAiUsage(Map<String, Object?> response) {
  final Map<String, Object?>? usage = _readMap(response['usage']);
  if (usage == null) return MeterUsage.empty;
  final int promptTokens = _readInt(usage['prompt_tokens']) ?? 0;
  final int completionTokens = _readInt(usage['completion_tokens']) ?? 0;
  final Map<String, Object?>? details = _readMap(
    usage['prompt_tokens_details'],
  );
  final int cached = _readInt(details?['cached_tokens']) ?? 0;
  // The OpenAI shape gives prompt_tokens *including* cached; subtract so we
  // bill them separately at the cache rate.
  final int billedIn = promptTokens > cached
      ? promptTokens - cached
      : promptTokens;
  return MeterUsage(
    tokensIn: billedIn,
    tokensOut: completionTokens,
    cachedTokensIn: cached,
  );
}

/// Anthropic Messages API usage shape:
/// `{ usage: { input_tokens, output_tokens, cache_read_input_tokens,
///    cache_creation_input_tokens } }`.
///
/// Cache *reads* are billed at the discounted rate; cache *creation* is
/// billed at full input rate (we already capture that in `input_tokens`).
///
/// ```dart
/// final response = await MeteredCall.run(
///   provider: 'anthropic',
///   model: 'claude-sonnet-4-6',
///   call: () => myAnthropicClient.messages.create(...),
///   extract: (r) => anthropicUsage(r.toJson()),
/// );
/// ```
MeterUsage anthropicUsage(Map<String, Object?> response) {
  final Map<String, Object?>? usage = _readMap(response['usage']);
  if (usage == null) return MeterUsage.empty;
  final int input = _readInt(usage['input_tokens']) ?? 0;
  final int output = _readInt(usage['output_tokens']) ?? 0;
  final int cacheRead = _readInt(usage['cache_read_input_tokens']) ?? 0;
  return MeterUsage(
    tokensIn: input,
    tokensOut: output,
    cachedTokensIn: cacheRead,
  );
}

/// Google Gemini `generateContent` usage shape:
/// `{ usageMetadata: { promptTokenCount, candidatesTokenCount,
///    cachedContentTokenCount } }`.
///
/// ```dart
/// final response = await MeteredCall.run(
///   provider: 'gemini',
///   model: 'gemini-2.5-pro',
///   call: () => myGeminiClient.generateContent(...),
///   extract: (r) => geminiUsage(r.toJson()),
/// );
/// ```
MeterUsage geminiUsage(Map<String, Object?> response) {
  final Map<String, Object?>? meta = _readMap(response['usageMetadata']);
  if (meta == null) return MeterUsage.empty;
  final int prompt = _readInt(meta['promptTokenCount']) ?? 0;
  final int candidate = _readInt(meta['candidatesTokenCount']) ?? 0;
  final int cached = _readInt(meta['cachedContentTokenCount']) ?? 0;
  final int billedIn = prompt > cached ? prompt - cached : prompt;
  return MeterUsage(
    tokensIn: billedIn,
    tokensOut: candidate,
    cachedTokensIn: cached,
  );
}

Map<String, Object?>? _readMap(Object? v) =>
    v is Map<String, Object?> ? v : null;

int? _readInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
