# llm_meter — Feature Catalog

Per-request token cost + latency + cache observability for any Flutter LLM
app. Drop-in wrapper, live HUD in dev, silent sink in prod.

**Legend:** 🔴 Must-have · 🟡 Should-have · 🟢 Nice-to-have (v0.2+)

---

## 1. Core API

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-CORE-01 | `LlmMeter.instance` singleton accessor | 🔴 | |
| F-CORE-02 | `LlmMeter.init(config)` setup | 🔴 | One line in `main()` |
| F-CORE-03 | `MeterEvent` model (provider, model, tokensIn, tokensOut, cost, latency, cached) | 🔴 | The unit of measurement |
| F-CORE-04 | `MeterConfig` (sinks, hud, pricing overrides) | 🔴 | |
| F-CORE-05 | Manual recording: `LlmMeter.record(MeterEvent)` | 🔴 | For users not using wrappers |

## 2. Provider Wrappers

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-WRAP-01 | OpenAI client wrapper (or callback-based instrumentation) | 🔴 | Captures tokens from response.usage |
| F-WRAP-02 | Anthropic client wrapper | 🔴 | |
| F-WRAP-03 | Gemini client wrapper | 🔴 | |
| F-WRAP-04 | Generic `MeteredCall(future, onResult)` wrapper | 🔴 | For any HTTP client |
| F-WRAP-05 | Streaming-aware (capture per-chunk + total) | 🔴 | Critical for AI chat apps |
| F-WRAP-06 | OpenRouter wrapper | 🟡 | |
| F-WRAP-07 | Ollama / LM Studio (local) wrapper | 🟢 | v0.2 |

## 3. Pricing Engine

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-PRICE-01 | Built-in pricing table for top 30 models (GPT-5, Claude 4.7, Gemini 2.5 etc.) | 🔴 | Auto-updates via package version |
| F-PRICE-02 | Per-model input/output token rates | 🔴 | |
| F-PRICE-03 | Custom pricing override: `MeterConfig(pricing: {...})` | 🔴 | |
| F-PRICE-04 | Cache-discount calc (Anthropic cache, Gemini context cache) | 🔴 | |
| F-PRICE-05 | Multi-currency display (USD default, EUR/INR/...) | 🟡 | |

## 4. Live HUD Overlay

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-HUD-01 | Floating draggable widget showing live cost + latency | 🔴 | Apple-DevTools style |
| F-HUD-02 | Cost-per-conversation breakdown | 🔴 | |
| F-HUD-03 | Cache-hit rate indicator (%) | 🔴 | |
| F-HUD-04 | p50/p99 latency rolling window | 🔴 | |
| F-HUD-05 | Tap-to-expand event log | 🔴 | |
| F-HUD-06 | Auto-hide in release builds (unless explicitly opted in) | 🔴 | |
| F-HUD-07 | Configurable position (corners, snap-to-edge) | 🟡 | |
| F-HUD-08 | Tap event → opens detail sheet w/ full metadata | 🟡 | |

## 5. Sinks (Production Telemetry)

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-SINK-01 | `MeterSink` interface (abstract) | 🔴 | |
| F-SINK-02 | Console sink (default in debug) | 🔴 | |
| F-SINK-03 | Posthog sink | 🔴 | |
| F-SINK-04 | Mixpanel sink | 🔴 | |
| F-SINK-05 | Datadog sink | 🟡 | |
| F-SINK-06 | Custom sink interface for user-defined backends | 🔴 | |
| F-SINK-07 | Sentry breadcrumb sink | 🟡 | |
| F-SINK-08 | Batching + retry logic (offline-safe) | 🔴 | Avoid blocking UI thread |

## 6. Aggregation & Reporting

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-AGG-01 | Rolling window stats (last 5/30/100 events) | 🔴 | |
| F-AGG-02 | Per-model breakdown | 🔴 | |
| F-AGG-03 | Conversation-scoped budgets (alert on threshold) | 🟡 | |
| F-AGG-04 | Daily/session cost cap with hard-stop callback | 🟡 | |

## 7. Privacy & Safety

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-PRIV-01 | Never log prompt text by default | 🔴 | Counts/cost only |
| F-PRIV-02 | Opt-in prompt logging (debug-only flag) | 🔴 | |
| F-PRIV-03 | PII filter helper for sinks | 🟡 | |
| F-PRIV-04 | GDPR-mode: redact user-ids, scrub IPs | 🔴 | Important for EU |

## 8. Documentation & Marketing

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-DOC-01 | README — install, 30-sec setup, HUD screenshot, sink recipe | 🔴 | |
| F-DOC-02 | Launch GIF showing live HUD over a streaming chat | 🔴 | |
| F-DOC-03 | Recipe: "Add cost-cap to your chat app" | 🟡 | |
| F-DOC-04 | Recipe: "Ship LLM ops to Posthog" | 🟡 | |

## 9. Quality

| ID | Feature | Priority | Notes |
|---|---|---|---|
| F-QA-01 | ≥30 unit tests on pricing + aggregation | 🔴 | Correctness is the moat |
| F-QA-02 | Widget tests for HUD | 🔴 | |
| F-QA-03 | `flutter analyze --fatal-warnings` 0 | 🔴 | |
| F-QA-04 | pana ≥ 130/130 | 🔴 | |
