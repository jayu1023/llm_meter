/// Built-in pricing table for the top 30 hosted LLM models, snapshot taken
/// from official provider pricing pages on **2026-05-31**.
///
/// Pricing changes; treat the bundled table as a sensible default. Override at
/// runtime via `MeterConfig(pricingOverrides: ...)` when a provider updates
/// rates or when you bring your own model id.
library;

import 'model_pricing.dart';

/// Lookup the bundled [ModelPricing] for [model].
///
/// Matching is case-insensitive and tolerant of common variants:
/// * `gpt-5`, `gpt5`, `openai/gpt-5` all resolve to the same entry.
/// * unknown models fall back to [defaultPricing] (currently
///   `ModelPricing.free`, i.e. cost reports as `$0`).
///
/// To override, pass `pricingOverrides` to `MeterConfig` or call
/// [priceForModel] with an explicit `overrides` map.
ModelPricing pricingFor(String model, {Map<String, ModelPricing>? overrides}) {
  final String key = _normalize(model);
  if (overrides != null) {
    final ModelPricing? override =
        overrides[model] ?? overrides[key] ?? _aliasMatch(key, overrides);
    if (override != null) return override;
  }
  return _table[key] ?? _aliasMatch(key, _table) ?? defaultPricing;
}

/// Fallback when a model id is unknown to both the built-in table and any
/// user overrides.
const ModelPricing defaultPricing = ModelPricing.free;

/// Pure cost calculation. Use this when you want a one-shot quote without
/// recording an event.
double priceForModel({
  required String model,
  required int tokensIn,
  required int tokensOut,
  int cachedTokensIn = 0,
  Map<String, ModelPricing>? overrides,
}) {
  return pricingFor(model, overrides: overrides).cost(
    tokensIn: tokensIn,
    tokensOut: tokensOut,
    cachedTokensIn: cachedTokensIn,
  );
}

/// The set of model ids known to the built-in pricing table.
///
/// Order is stable for snapshot testing.
List<String> get builtInModels => List<String>.unmodifiable(_table.keys);

String _normalize(String model) {
  String m = model.trim().toLowerCase();
  // Strip provider prefix (openai/, anthropic/, google/, ...) used by
  // OpenRouter etc.
  final int slash = m.indexOf('/');
  if (slash != -1) m = m.substring(slash + 1);
  // Strip date suffix used by some Anthropic ids (e.g.
  // claude-3-5-sonnet-20241022 -> claude-3-5-sonnet).
  final RegExp dated = RegExp(r'-\d{8}$');
  m = m.replaceFirst(dated, '');
  // Collapse separators so gpt-5, gpt_5, gpt5 all match.
  m = m.replaceAll('_', '-');
  return m;
}

ModelPricing? _aliasMatch(String key, Map<String, ModelPricing> table) {
  // Try alias map first.
  final String? aliased = _aliases[key];
  if (aliased != null && table.containsKey(aliased)) return table[aliased];
  // Then try prefix match: "gpt-5-mini-2026-05-01" -> "gpt-5-mini".
  String longest = '';
  for (final String candidate in table.keys) {
    if (key.startsWith(candidate) && candidate.length > longest.length) {
      longest = candidate;
    }
  }
  if (longest.isNotEmpty) return table[longest];
  return null;
}

/// Pricing snapshot — USD per 1M tokens unless otherwise noted.
///
/// Sources (all verified 2026-05-31):
///  * openai.com/api/pricing
///  * anthropic.com/pricing
///  * ai.google.dev/pricing
///  * deepmind.google/technologies/gemini/pricing
///  * meta.ai / hosted via Groq / Together for Llama 3.3
///  * mistral.ai/pricing
///  * x.ai/pricing
///  * deepseek.com/pricing
///  * cohere.com/pricing
const Map<String, ModelPricing> _table = <String, ModelPricing>{
  // ── OpenAI ────────────────────────────────────────────────────────────
  'gpt-5': ModelPricing.perMillion(
    inputPerMillion: 1.25,
    outputPerMillion: 10.0,
    cachedInputPerMillion: 0.125,
  ),
  'gpt-5-mini': ModelPricing.perMillion(
    inputPerMillion: 0.25,
    outputPerMillion: 2.0,
    cachedInputPerMillion: 0.025,
  ),
  'gpt-5-nano': ModelPricing.perMillion(
    inputPerMillion: 0.05,
    outputPerMillion: 0.40,
    cachedInputPerMillion: 0.005,
  ),
  'gpt-4.1': ModelPricing.perMillion(
    inputPerMillion: 2.0,
    outputPerMillion: 8.0,
    cachedInputPerMillion: 0.50,
  ),
  'gpt-4.1-mini': ModelPricing.perMillion(
    inputPerMillion: 0.40,
    outputPerMillion: 1.60,
    cachedInputPerMillion: 0.10,
  ),
  'gpt-4o': ModelPricing.perMillion(
    inputPerMillion: 2.50,
    outputPerMillion: 10.0,
    cachedInputPerMillion: 1.25,
  ),
  'gpt-4o-mini': ModelPricing.perMillion(
    inputPerMillion: 0.15,
    outputPerMillion: 0.60,
    cachedInputPerMillion: 0.075,
  ),
  'o3': ModelPricing.perMillion(
    inputPerMillion: 2.0,
    outputPerMillion: 8.0,
    cachedInputPerMillion: 0.50,
  ),
  'o3-mini': ModelPricing.perMillion(
    inputPerMillion: 1.10,
    outputPerMillion: 4.40,
    cachedInputPerMillion: 0.55,
  ),
  'o4-mini': ModelPricing.perMillion(
    inputPerMillion: 1.10,
    outputPerMillion: 4.40,
    cachedInputPerMillion: 0.275,
  ),

  // ── Anthropic ─────────────────────────────────────────────────────────
  'claude-opus-4-7': ModelPricing.perMillion(
    inputPerMillion: 15.0,
    outputPerMillion: 75.0,
    cachedInputPerMillion: 1.50,
  ),
  'claude-sonnet-4-6': ModelPricing.perMillion(
    inputPerMillion: 3.0,
    outputPerMillion: 15.0,
    cachedInputPerMillion: 0.30,
  ),
  'claude-haiku-4-5': ModelPricing.perMillion(
    inputPerMillion: 1.0,
    outputPerMillion: 5.0,
    cachedInputPerMillion: 0.10,
  ),
  'claude-3-7-sonnet': ModelPricing.perMillion(
    inputPerMillion: 3.0,
    outputPerMillion: 15.0,
    cachedInputPerMillion: 0.30,
  ),
  'claude-3-5-sonnet': ModelPricing.perMillion(
    inputPerMillion: 3.0,
    outputPerMillion: 15.0,
    cachedInputPerMillion: 0.30,
  ),
  'claude-3-5-haiku': ModelPricing.perMillion(
    inputPerMillion: 0.80,
    outputPerMillion: 4.0,
    cachedInputPerMillion: 0.08,
  ),

  // ── Google Gemini ─────────────────────────────────────────────────────
  'gemini-2.5-pro': ModelPricing.perMillion(
    inputPerMillion: 1.25,
    outputPerMillion: 10.0,
    cachedInputPerMillion: 0.31,
  ),
  'gemini-2.5-flash': ModelPricing.perMillion(
    inputPerMillion: 0.30,
    outputPerMillion: 2.50,
    cachedInputPerMillion: 0.075,
  ),
  'gemini-2.5-flash-lite': ModelPricing.perMillion(
    inputPerMillion: 0.10,
    outputPerMillion: 0.40,
    cachedInputPerMillion: 0.025,
  ),
  'gemini-2.0-flash': ModelPricing.perMillion(
    inputPerMillion: 0.10,
    outputPerMillion: 0.40,
    cachedInputPerMillion: 0.025,
  ),
  'gemini-2.0-flash-lite': ModelPricing.perMillion(
    inputPerMillion: 0.075,
    outputPerMillion: 0.30,
  ),

  // ── Meta Llama (hosted Groq/Together) ─────────────────────────────────
  'llama-3.3-70b': ModelPricing.perMillion(
    inputPerMillion: 0.59,
    outputPerMillion: 0.79,
  ),
  'llama-3.1-70b': ModelPricing.perMillion(
    inputPerMillion: 0.59,
    outputPerMillion: 0.79,
  ),
  'llama-3.1-8b': ModelPricing.perMillion(
    inputPerMillion: 0.05,
    outputPerMillion: 0.08,
  ),

  // ── Mistral ───────────────────────────────────────────────────────────
  'mistral-large': ModelPricing.perMillion(
    inputPerMillion: 2.0,
    outputPerMillion: 6.0,
  ),
  'mistral-small': ModelPricing.perMillion(
    inputPerMillion: 0.20,
    outputPerMillion: 0.60,
  ),
  'codestral': ModelPricing.perMillion(
    inputPerMillion: 0.30,
    outputPerMillion: 0.90,
  ),

  // ── xAI Grok ──────────────────────────────────────────────────────────
  'grok-4': ModelPricing.perMillion(
    inputPerMillion: 3.0,
    outputPerMillion: 15.0,
    cachedInputPerMillion: 0.75,
  ),
  'grok-3': ModelPricing.perMillion(
    inputPerMillion: 3.0,
    outputPerMillion: 15.0,
  ),
  'grok-3-mini': ModelPricing.perMillion(
    inputPerMillion: 0.30,
    outputPerMillion: 0.50,
  ),

  // ── DeepSeek ──────────────────────────────────────────────────────────
  'deepseek-v3': ModelPricing.perMillion(
    inputPerMillion: 0.27,
    outputPerMillion: 1.10,
    cachedInputPerMillion: 0.07,
  ),
  'deepseek-r1': ModelPricing.perMillion(
    inputPerMillion: 0.55,
    outputPerMillion: 2.19,
    cachedInputPerMillion: 0.14,
  ),

  // ── Cohere ────────────────────────────────────────────────────────────
  'command-r-plus': ModelPricing.perMillion(
    inputPerMillion: 2.50,
    outputPerMillion: 10.0,
  ),
  'command-r': ModelPricing.perMillion(
    inputPerMillion: 0.15,
    outputPerMillion: 0.60,
  ),
};

/// Provider-id aliases. The key is the normalized lookup string the user
/// supplied; the value is the canonical key in [_table].
const Map<String, String> _aliases = <String, String>{
  // OpenAI alt spellings
  'gpt5': 'gpt-5',
  'gpt5-mini': 'gpt-5-mini',
  'gpt5-nano': 'gpt-5-nano',
  'gpt-4-1': 'gpt-4.1',
  'gpt-4-1-mini': 'gpt-4.1-mini',
  'chatgpt-4o': 'gpt-4o',

  // Anthropic dot-style + dashed legacy
  'claude-4-7-opus': 'claude-opus-4-7',
  'claude-4-6-sonnet': 'claude-sonnet-4-6',
  'claude-4-5-haiku': 'claude-haiku-4-5',
  'claude-3-5-sonnet-latest': 'claude-3-5-sonnet',
  'claude-3-5-haiku-latest': 'claude-3-5-haiku',
  'claude-3-7-sonnet-latest': 'claude-3-7-sonnet',

  // Gemini
  'gemini-2-5-pro': 'gemini-2.5-pro',
  'gemini-2-5-flash': 'gemini-2.5-flash',
  'gemini-2-5-flash-lite': 'gemini-2.5-flash-lite',
  'gemini-2-0-flash': 'gemini-2.0-flash',
  'gemini-2-0-flash-lite': 'gemini-2.0-flash-lite',

  // Llama
  'llama3.3-70b': 'llama-3.3-70b',
  'llama-3-3-70b': 'llama-3.3-70b',
  'llama-3-1-70b': 'llama-3.1-70b',
  'llama-3-1-8b': 'llama-3.1-8b',
  'llama3.1-70b': 'llama-3.1-70b',
  'llama3.1-8b': 'llama-3.1-8b',
};
