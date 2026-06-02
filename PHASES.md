# llm_meter — Phase-wise Execution Plan

7 phases, **7–10 working days**. Quick-win package — small surface area, high
correctness bar. Target: viral launch via "live $ HUD over chat" GIF.

**Target ship:** earliest Jun 14, 2026 · must-ship-by Jun 21, 2026.

---

## Phase 0 — Foundation (Day 1, morning)

**Goal:** Scaffold + planning + deps.

**Tasks:**
- [ ] `flutter create --template=package llm_meter`
- [ ] `pubspec.yaml`: description, topics (`ai`, `llm`, `observability`, `metrics`, `analytics`)
- [ ] Deps: none required (pure Dart for core)
- [ ] Strict `analysis_options.yaml`
- [ ] Folder structure: `lib/src/{core,pricing,wrappers,hud,sinks,aggregation}/`
- [ ] First commit

**DoD:** Scaffold builds, lint clean.
**Features:** F-CORE-01..05 (skeletons)
**Skill:** none · **Est:** 2h

---

## Phase 1 — Core Models + Pricing Engine (Day 1–2)

**Goal:** Correct cost calculation for top 30 models. This is the moat.

**Tasks:**
- [ ] `MeterEvent` data class (immutable, equatable)
- [ ] `ModelPricing` data class (inputRate, outputRate, cachedInputRate)
- [ ] Built-in pricing table for top 30 models (GPT-5, Claude 4.6/4.7, Gemini 2.5, Llama 3.3 hosted, etc.)
- [ ] `priceForModel(model, tokensIn, tokensOut, cached)` pure function
- [ ] Multi-currency formatter (USD default)
- [ ] 30+ unit tests against published official pricing as of May 2026

**DoD:** Pricing calc matches official provider docs for 20+ model variants.
**Features:** F-CORE-03, F-PRICE-01..05, F-QA-01
**Skill:** `claude-api`, `dart-test-fundamentals` · **Est:** 1.5 days

---

## Phase 2 — Aggregation & Recording (Day 3)

**Goal:** In-memory event store with rolling stats.

**Tasks:**
- [ ] `LlmMeter` singleton with event ring buffer (last 1000 events)
- [ ] `record(MeterEvent)` API
- [ ] Rolling window stats: total $, p50/p99 latency, cache-hit %, per-model breakdown
- [ ] `LlmMeter.stream` to broadcast new events to listeners
- [ ] 20+ tests on aggregation correctness

**DoD:** Stats are computed in O(1) per event. Stream emits on every record.
**Features:** F-CORE-01..02, F-AGG-01..02
**Skill:** `flutter-handling-concurrency` · **Est:** 1 day

---

## Phase 3 — Provider Wrappers (Day 4–5)

**Goal:** Drop-in wrappers for OpenAI, Anthropic, Gemini that auto-record.

**Tasks:**
- [ ] `MeteredCall<T>` generic helper: takes a Future + token-extraction fn, records on completion
- [ ] `MeteredStream<T>` for streaming responses (accumulates tokens across chunks)
- [ ] Recipe + code for OpenAI (callback-pattern, package-agnostic — doesn't depend on a specific OpenAI SDK)
- [ ] Recipe + code for Anthropic
- [ ] Recipe + code for Gemini
- [ ] Tests with fake HTTP futures

**DoD:** All 3 provider wrappers record correctly for non-streaming + streaming.
**Features:** F-WRAP-01..05
**Skill:** `claude-api`, `flutter-handling-concurrency` · **Est:** 2 days

---

## Phase 4 — Live HUD Overlay (Day 6–7)

**Goal:** The hero feature. The thing that gets retweeted.

**Tasks:**
- [ ] `LlmMeterHud` widget — floating draggable card, snaps to corners
- [ ] Shows: total $, last-call latency, cache %, p99 latency, event count
- [ ] Tap to expand → list of last 20 events with full breakdown
- [ ] Auto-hide in release mode (unless `forceShow: true`)
- [ ] Subtle entrance animation, draggable across screen
- [ ] Widget tests for render + interaction

**DoD:** HUD overlays any Flutter app with `LlmMeterHud()` in the widget tree.
**Features:** F-HUD-01..08
**Skill:** `flutter-expert`, `impeccable` · **Est:** 2 days

---

## Phase 5 — Sinks (Day 7–8)

**Goal:** Production-ready telemetry adapters.

**Tasks:**
- [ ] `MeterSink` abstract interface
- [ ] `ConsoleSink` (debug default)
- [ ] `PosthogSink` (uses `posthog_flutter` or HTTP fallback)
- [ ] `MixpanelSink`
- [ ] `BatchingSink` decorator (wraps another sink, batches every Ns / Nn events)
- [ ] `RetryingSink` decorator (exponential backoff, offline queue)
- [ ] GDPR scrub helper

**DoD:** Events flow end-to-end to Posthog in example app.
**Features:** F-SINK-01..08, F-PRIV-04
**Skill:** none · **Est:** 1 day

---

## Phase 6 — Example App + Marketing (Day 9)

**Goal:** Showcase + record the launch GIF.

**Tasks:**
- [ ] `example/lib/main.dart` — fake streaming chat with HUD live on screen
- [ ] Auto-runs a sequence of calls (varied models, sizes, cache hits)
- [ ] Record GIF: HUD reacts as chat streams ("$0.0012 · 340ms · cache 73%")
- [ ] Take screenshots for pubspec `screenshots:`

**DoD:** Example runs on iOS, Android, Web. GIF recorded.
**Features:** F-DOC-01..02
**Skill:** `app-store-screenshots` · **Est:** 1 day

---

## Phase 7 — Docs + Publish (Day 10)

**Tasks:**
- [ ] README: install + 30s setup + GIF + sink recipe + pricing-override recipe
- [ ] CHANGELOG `[0.1.0]`
- [ ] dartdoc all public APIs
- [ ] GitHub Actions CI
- [ ] `dart pub publish --dry-run` → 0 warnings
- [ ] Publish
- [ ] Launch: Tweet w/ GIF, r/FlutterDev "I built a token-cost HUD for Flutter AI apps", Awesome Flutter PR

**DoD:** Live on pub.dev. ≥1 indie-hacker retweet within 24h.
**Features:** F-DOC-01..04, F-QA-03..04
**Skill:** `claude-api` · **Est:** 1 day

---

## Summary

| Phase | Days | Deliverable |
|---|---|---|
| 0 | 0.25 | Scaffold |
| 1 | 1.5 | Pricing engine |
| 2 | 1 | Aggregation |
| 3 | 2 | Provider wrappers |
| 4 | 2 | Live HUD |
| 5 | 1 | Sinks |
| 6 | 1 | Example + GIF |
| 7 | 1 | Publish |
| **Total** | **~10** | **llm_meter v0.1.0 live on pub.dev** |
