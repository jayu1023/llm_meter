# Changelog

## 0.1.0 — 2026-06-02

First public release. Per-request cost + latency + cache observability for
any Flutter LLM app.

### Added

- **Core**
  - `MeterEvent` — immutable record of one LLM call (provider, model, tokens,
    cost, latency, cache hits, conversation/request ids, error, metadata).
  - `LlmMeter` singleton with `init(config)`, `record(event)`, `stats()`,
    `events()`, `stream`, and `clear()`.
  - `MeterConfig` — sinks, pricing overrides, display currency, GDPR mode,
    ring-buffer capacity.
- **Pricing engine**
  - `ModelPricing.perMillion(...)` factory.
  - Built-in pricing table for 31 hosted models (OpenAI GPT-5/4.1/4o/o3/o4,
    Anthropic Claude 4.7/4.6/4.5/3.7/3.5, Google Gemini 2.5/2.0, Meta Llama
    3.3/3.1, Mistral, xAI Grok, DeepSeek, Cohere). Snapshot dated
    **2026-05-31**.
  - `pricingFor(model)` / `priceForModel(...)` pure functions with case-,
    separator-, and provider-prefix-tolerant lookup.
  - Cache-discount math (Anthropic cache reads, Gemini context cache).
  - User overrides via `MeterConfig.pricingOverrides`.
- **Currency**
  - `Currency` with `perMillion` conversion + prefix/suffix formatting; bundled
    USD, EUR, GBP, INR, SEK, CHF. No `package:intl` dependency.
- **Aggregation**
  - `RingBuffer<T>` — fixed-capacity O(1) push, oldest dropped.
  - `MeterStats` — total $, p50/p99 latency, cache-hit %, per-model breakdown.
- **Provider wrappers**
  - `MeteredCall.run<T>(...)` — wraps any Future, extracts usage, records
    latency. Records zero-cost error events and rethrows on failure.
  - `MeteredStream.wrap<C>(...)` — streaming passthrough that records once on
    done. Handles per-chunk usage deltas, errors, and mid-stream cancellation.
  - Provider usage recipes (`openAiUsage`, `anthropicUsage`, `geminiUsage`)
    that accept JSON maps — no provider SDK dependency.
- **HUD**
  - `LlmMeterHud` floating draggable card; snaps to nearest corner on release.
  - Live total cost, last call cost+ms, p50/p99, cache %, event count.
  - Tap-to-expand event log (configurable `maxEventsInLog`).
  - `AnimatedSize` transition; auto-hides in release unless `forceShow: true`.
- **Sinks**
  - `MeterSink` abstract interface.
  - `ConsoleSink` (debug default).
  - `PosthogSink` and `MixpanelSink` via `dart:io HttpClient` (no SDK dep;
    web fallback is a no-op).
  - `BatchingSink` (by count or time interval).
  - `RetryingSink` (exponential backoff with bounded offline queue).
  - `gdprScrub()` helper that drops `conversation_id`, `request_id`, and
    `user_*` / `email` / `ip` metadata.

### Quality

- 124 unit and widget tests passing.
- `flutter analyze` with strict casts/inference/raw-types: zero issues.
- Pure-Dart core; no transitive runtime dependencies.
- API keys are never read or stored by the package — caller-supplied only.
