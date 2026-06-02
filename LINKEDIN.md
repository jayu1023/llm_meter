# LinkedIn Project Metadata — llm_meter

Copy these straight into LinkedIn → Profile → Add section → Projects.

LinkedIn caps the description at 2000 characters. Two versions below — pick one.

---

## Field-by-field

| Field | Value |
|---|---|
| **Project name** | llm_meter — Token-cost observability for Flutter LLM apps |
| **Date** | Jun 2026 – Present |
| **Currently working on it** | ✅ Yes (toggle on) |
| **Associated with** | (leave blank, or your current company if you want) |
| **Project URL** | https://pub.dev/packages/llm_meter |
| **Project description** | (use one of the versions below) |
| **Contributors** | Add yourself only (solo project) |
| **Skills** | (full list below — add all 12) |
| **Media** | Upload `launch-assets/hud-static.png` |

---

## Project description — Short version (under 600 chars, good for mobile)

```
Open-source Flutter package that shows per-request cost, latency, and
cache-hit visibility for any LLM call in your app. Drop-in widget for
live dev feedback, plus production telemetry sinks for PostHog and
Mixpanel.

Built-in pricing for 31 hosted models including GPT-5, Claude 4.7,
Gemini 2.5, and Llama 3.3. Zero runtime dependencies. BSD-3-Clause.

Tech: Dart, Flutter, streams, async, dart:io HTTP, conditional imports
for web safety. 124 unit and widget tests, flutter analyze clean.

pub.dev/packages/llm_meter
```

---

## Project description — Full version (under 2000 chars, recommended for the project page itself)

```
llm_meter is an open-source Flutter package I built to solve a problem
I kept running into: I had no idea what any of my app's LLM calls
actually cost, or how often the prompt cache was hitting. Every
observability tool on the market wanted to sit in front of my API call
as a proxy, which is a non-starter for a mobile app talking to OpenAI
or Anthropic from the device.

So I built one that sits next to your existing client instead. You bring
your own SDK; llm_meter just measures.

What it does:
- Records token counts, latency, and cache-hit % for every LLM call
- Prices it from a built-in table for 31 hosted models (GPT-5, Claude
  4.7, Gemini 2.5, Llama 3.3, Mistral, Grok, DeepSeek, Cohere)
- Shows the totals in a live floating HUD widget you drop into any
  Flutter widget tree
- Forwards events to PostHog, Mixpanel, or your own sink in production,
  with built-in batching, retry, and offline queue
- Includes a GDPR-safe scrub helper for the EU market

Engineering choices I'm proud of:
- Zero runtime dependencies. The whole core is pure Dart.
- Web-safe with conditional imports (dart:io on mobile/desktop, no-op
  on web).
- Provider-agnostic. Three JSON-shape adapters cover OpenAI, Anthropic,
  and Gemini without dragging in any provider SDK.
- 124 unit and widget tests. flutter analyze clean with strict casts,
  strict inference, and strict raw types.
- No credentials ever touch the package. Every API key is a constructor
  arg you supply.

This is package three of seven I'm publishing this year. streamdown
(streaming markdown rendering) and paywall_kit (12 conversion-optimized
paywall variants) shipped earlier. agent_kit, liquid_glass, lighthouse,
and mcp_client land next.

pub.dev → https://pub.dev/packages/llm_meter
GitHub  → https://github.com/jayu1023/llm_meter
```

---

## Skills to tag on the project (add all)

LinkedIn lets you add up to 50. These map to roles at Klarna, Tink,
Spotify, Mistral, Sygnum, DeepL — the targets in your roadmap.

1. Flutter
2. Dart
3. Mobile Development
4. Open Source
5. LLM (Large Language Models)
6. AI Engineering
7. Observability
8. Software Architecture
9. API Design
10. Test-Driven Development
11. Package Development
12. Cross-Platform Development

---

## Featured section (separate from Projects)

LinkedIn has a "Featured" carousel above your experience. Add the pub.dev
page as a featured link:

| Field | Value |
|---|---|
| **Type** | Link |
| **URL** | https://pub.dev/packages/llm_meter |
| **Title** | llm_meter — Flutter package on pub.dev |
| **Description** | Token-cost + latency + cache observability HUD for any Flutter LLM app. Live dev HUD, production telemetry sinks, zero runtime deps. |
| **Thumbnail** | Auto-fetched from pub.dev. If it looks bad, override with hud-static.png. |

---

## Headline / About update (optional)

If your LinkedIn headline is generic, swap in something like:

```
Senior Flutter Engineer · Building AI-native open-source packages on
pub.dev · streamdown · paywall_kit · llm_meter
```

In your About section, add one line at the end:

```
Currently shipping a 7-package Flutter portfolio focused on AI tooling,
monetization, and production polish. 3 of 7 live on pub.dev as of Jun 2026.
```

---

## Cross-link from other pub.dev packages

Update the LinkedIn "Projects" entries for streamdown and paywall_kit so
each one mentions the portfolio. Future recruiters see all three in one
glance.

For streamdown add to its description:
> Part of a 7-package open-source portfolio. Sibling packages: paywall_kit (monetization), llm_meter (LLM observability).

For paywall_kit add to its description:
> Part of a 7-package open-source portfolio. Sibling packages: streamdown (streaming markdown), llm_meter (LLM observability).

---

## Activity post to pin (optional but recommended)

After you publish the LinkedIn long-form launch post from `LAUNCH.md`
section 2, pin it to your profile for two weeks. That's the post a
recruiter will see first when they land on you.

LinkedIn → your profile → "..." next to the post → Pin to profile.

---

*Update the pub.dev URL once the package is live. Until then, the link
will 404 and LinkedIn will show a broken preview.*
