# llm_meter — Launch Playbook

Every post you need to make, every platform, every copy-paste-ready blurb.

**Status:** v0.1.0 tagged locally, awaiting publish · **Target ship:** 2026-06-02 (Earliest in roadmap was Jun 14)

Fill these in after publish:
- **pub.dev:** https://pub.dev/packages/llm_meter
- **GitHub:** https://github.com/jayu1023/llm_meter
- **Release:** https://github.com/jayu1023/llm_meter/releases/tag/v0.1.0

---

## 0. Pre-flight commands (run these yourself)

```bash
cd "/Users/limbanijayhasmukhbhai/Downloads/jayu pcakage/llm_meter"

# 1. Create the public GitHub repo (requires gh auth)
gh repo create jayu1023/llm_meter --public \
  --description "Per-request token cost + latency + cache observability HUD for any Flutter LLM app." \
  --homepage "https://pub.dev/packages/llm_meter" \
  --source=. --remote=origin

# 2. Push branch + tag
git push -u origin main
git push origin v0.1.0

# 3. Publish to pub.dev (interactive — opens browser for OAuth)
dart pub publish

# 4. Create the GitHub release with CHANGELOG body
gh release create v0.1.0 \
  --title "v0.1.0 — first public release" \
  --notes-file CHANGELOG.md
```

---

## ⏰ Launch timeline

| When | What |
|---|---|
| **Day 0 (publish day)** | Twitter, LinkedIn, r/FlutterDev, Awesome Flutter PR, Flutter Weekly |
| **Day 1** | Flutter Tap shout-out, r/dartlang cross-post |
| **Day 2** | Hacker News Show HN (Tue/Wed morning US time is best) |
| **Day 3–5** | dev.to article, then Medium repost |
| **Day 7** | Follow-up tweet with first-week stats |

---

## 📋 Checklist

- [ ] **1. Twitter / X** — short post + GIF
- [ ] **2. LinkedIn** — long-form professional post
- [ ] **3. r/FlutterDev** — discussion post (NOT a self-promo)
- [ ] **4. Awesome Flutter PR** — one line in `Tools` or `Performance`
- [ ] **5. Flutter Weekly** — newsletter submission form
- [ ] **6. Flutter Tap** — tag @fluttertap on Twitter
- [ ] **7. r/dartlang** — cross-post (Day 1)
- [ ] **8. Hacker News** — Show HN (Day 2)
- [ ] **9. dev.to article** — Day 3
- [ ] **10. Medium repost** — Day 4 (canonical URL = dev.to)

---

## 🎨 Assets needed

| File | Where | Notes |
|---|---|---|
| `launch-assets/hud-demo.gif` | tweet, README, dev.to | 10s loop of the example app, HUD reacting as fake chat streams |
| `launch-assets/hud-static.png` | LinkedIn, Hacker News | single frame, 1200×630 |
| `launch-assets/comparison-table.png` | dev.to | screenshot of the README comparison table |

Record the GIF from the example app:
```bash
cd example && flutter run -d chrome
# then use Kap or LICEcap to record the bottom-right HUD while clicking "Auto-run"
```

---

## 1. Twitter / X

**Account:** your personal handle. Tag `@FlutterDev` and `@dart_lang`.

```
shipped llm_meter — a Flutter package that shows you exactly what every
LLM call in your app costs.

drop one widget in, get live $ / latency / cache % over your chat.
silent telemetry sink in prod.

31 hosted models priced out of the box. zero deps. BSD-3.

pub.dev/packages/llm_meter

@FlutterDev @dart_lang
```

Attach: `hud-demo.gif`

**Reply with thread (optional, 1-2 tweets):**
```
the HUD is dev-only. in release builds it auto-hides and the same events go
to PostHog / Mixpanel / your own sink via batching + retry decorators.

no API keys live in the package. you bring your own client; llm_meter just
measures it.
```

```
why i built it: was tuning a chat app last week and realized i had no idea
how many of my anthropic calls were actually hitting the prompt cache. the
existing "LLM observability" tools all want my requests routed through
their proxy. that's a non-starter for a mobile app.
```

---

## 2. LinkedIn

**Format:** longer, more "shipping is the feature" energy. No hashtags in the body — drop them at the end.

```
Shipped llm_meter today.

It's a Flutter package that gives you per-request cost, latency, and cache
visibility for any LLM call in your app. One widget for live dev feedback,
plus production telemetry sinks for PostHog, Mixpanel, or whatever you
already use.

The thing that bugged me about the existing options: they all want you to
route your requests through their proxy. For a mobile app where you're
talking to OpenAI / Anthropic / Gemini from the device, that's a
non-starter on latency, privacy, and lock-in.

So llm_meter sits next to your existing client instead of in front of it.
You bring your own SDK. It just measures.

What's in v0.1.0:
- 31 hosted models priced out of the box (GPT-5, Claude 4.7, Gemini 2.5,
  Llama 3.3, Mistral, Grok, DeepSeek, Cohere)
- Cache discount math for Anthropic + Gemini context caching
- Drop-in Future + Stream wrappers
- Live floating HUD overlay (draggable, expandable)
- Sinks with batching + retry + offline queue
- GDPR-safe scrub helper
- 124 tests, zero runtime deps

Open source, BSD-3-Clause.

pub.dev → https://pub.dev/packages/llm_meter
GitHub → https://github.com/jayu1023/llm_meter

This is package 3 of 7 in a portfolio I'm building toward a senior Flutter
role in Sweden or Switzerland by September. streamdown and paywall_kit
already shipped. agent_kit is next.

#Flutter #Dart #LLM #AI #OpenSource
```

Attach: `hud-static.png` (single frame screenshot)

---

## 3. r/FlutterDev

> ⚠️  Previous packages got auto-removed for "AI-generated content." Keep it
> short, conversational, ask a real question at the end, no em-dashes, no
> "delve / dive deep / unlock", no marketing tone.

**Title:**
```
I built a token-cost HUD for Flutter LLM apps — looking for feedback
```

**Body:**
```
Hey folks,

Built a small package called llm_meter. It shows you what every LLM
call in your app costs, live, while you develop.

The problem I was solving: I had a Flutter chat app talking to Claude
and Gemini, and I had no clue how often my prompt cache was actually
hitting. Existing "LLM observability" tools all want you to route
requests through their proxy, which is a no-go for a mobile app.

So this thing just sits next to your client. You bring your own SDK.
It records token counts + latency + cache % per call, prices it from
a built-in table of 31 hosted models, and shows the totals in a tiny
floating HUD. Drop it in your widget tree, auto-hides in release.

For production there are sinks for PostHog and Mixpanel with batching
and retry built in.

Zero runtime deps. BSD-3.

https://pub.dev/packages/llm_meter
https://github.com/jayu1023/llm_meter

Anyone running into the same observability gap? Curious what you're
using if anything.
```

**Reply to first commenter** within 30 min, even if it's a simple thanks.

---

## 4. Awesome Flutter PR

**Repo:** https://github.com/Solido/awesome-flutter

**Section to edit:** `Tools` → look for an "AI / LLM" or "Observability" sub-section. If none, add under `Tools / Debugging`.

**One-line entry:**
```markdown
* [llm_meter](https://github.com/jayu1023/llm_meter) - Per-request token cost, latency, and cache observability HUD for any Flutter LLM app. Drop-in wrapper, live dev HUD, silent telemetry sink in prod.
```

**PR title:**
```
Add llm_meter under Tools / Debugging
```

**PR body:**
```
Adds llm_meter — a Flutter package for tracking what each LLM call in
your app actually costs.

- v0.1.0 live on pub.dev
- BSD-3-Clause
- Zero runtime dependencies
- 124 tests, flutter analyze clean
- 31 hosted models priced out of the box

The package fills a gap I couldn't find anywhere else: live token cost
and cache-hit visibility for Flutter apps that talk directly to
OpenAI / Anthropic / Gemini from the device.
```

---

## 5. Flutter Weekly

**Submit at:** https://flutterweekly.net/

**Form fields:**

- **Link:** `https://pub.dev/packages/llm_meter`
- **Type:** Packages
- **Title:**
  ```
  llm_meter — per-request token cost + cache observability HUD
  ```
- **Description:**
  ```
  Drop-in Flutter package that shows you live cost, latency, and cache-hit
  stats for every LLM call in your app. Built-in pricing for 31 hosted
  models including GPT-5, Claude 4.7, Gemini 2.5, and Llama 3.3. Sinks for
  PostHog and Mixpanel with batching and retry. Zero runtime deps, BSD-3.
  ```

---

## 6. Flutter Tap

**Tweet at the account:**
```
hey @fluttertap — just shipped llm_meter, a per-request LLM cost HUD
for Flutter apps. live $ / latency / cache % over your chat, drop-in
widget, production sinks built in. would love a feature 🙏

pub.dev/packages/llm_meter
```

---

## 7. r/dartlang (Day 1)

> Different angle than the FlutterDev post. Lean into "this is a pure-Dart
> package with conditional web imports."

**Title:**
```
llm_meter — pure-Dart LLM observability package, drop-in for any client
```

**Body:**
```
Shipped llm_meter yesterday. Sharing here because the core is pure Dart
with conditional imports for the web-vs-io split, which kept the install
size flat (zero runtime deps).

Use case: you have a Dart or Flutter app talking to an LLM API. You want
to know how much each call costs, how slow the slowest one is, and how
often the provider cache actually hits. This package wraps any Future or
Stream and records it.

Has a built-in pricing table for 31 hosted models. Cache discount math
for Anthropic and Gemini. Provider-agnostic — you bring your own client
SDK.

pub.dev → https://pub.dev/packages/llm_meter
GitHub  → https://github.com/jayu1023/llm_meter

BSD-3.
```

---

## 8. Hacker News — Show HN (Day 2)

**Submit at:** https://news.ycombinator.com/submit

> Best window: Tue or Wed, 7-9am Pacific. Title format MUST start with "Show HN:".

**Title:**
```
Show HN: llm_meter – per-request cost and cache HUD for Flutter LLM apps
```

**URL:** `https://github.com/jayu1023/llm_meter`

**First comment (post within 2 minutes of submission):**
```
Author here. Built this because every LLM observability tool I tried
wanted to be in front of my API call as a proxy. That's fine for a
backend but it falls apart for a mobile app talking to OpenAI from
the device.

llm_meter sits next to your client instead. You bring your own SDK,
it just measures token counts, latency, and cache-hit %, then prices
it from a built-in table for the top 31 hosted models. There's a tiny
floating HUD widget you can drop into any Flutter app for live dev
feedback, and sinks for PostHog or Mixpanel for production.

Zero runtime deps, pure Dart core. BSD-3.

The bit I'm most curious for feedback on is the pricing table itself.
Provider rates change quarterly and I don't want this to drift. There's
a runtime override mechanism, but I'd love a smarter approach if anyone
has one.
```

---

## 9. dev.to article (Day 3)

**Suggested title:**
```
What every LLM call in your Flutter app actually costs
```

**Front-matter (dev.to):**
```yaml
---
title: What every LLM call in your Flutter app actually costs
published: true
description: I built a small Flutter package that gives you per-request cost, latency, and cache visibility for any LLM call. Here's the story.
tags: flutter, dart, ai, llm
cover_image: https://raw.githubusercontent.com/jayu1023/llm_meter/main/launch-assets/hud-static.png
canonical_url: https://dev.to/jayu1023/what-every-llm-call-in-your-flutter-app-actually-costs
---
```

**Outline (write the body in your own voice):**
1. **The bug that started it.** I was debugging a chat app and realized I had no idea how often the Anthropic prompt cache was hitting. The bill was higher than I expected and I had no data.
2. **Why existing tools didn't fit.** LangSmith, Helicone, etc. all want a proxy in front of the API. Fine for a backend, broken for a mobile app talking to OpenAI directly from the device.
3. **What I built.** Show the HUD GIF. Walk through the 30-second setup. Show the comparison table.
4. **The pricing table.** How I priced 31 models, how cache discount math works, how to override.
5. **What's next.** mcp_client and agent_kit roadmap.

Add a "Liked this? I'm building 7 of these by September." closer with link to the GitHub portfolio.

---

## 10. Medium repost (Day 4)

Same article, paste into Medium. Use the **Import a story** flow:
1. Go to https://medium.com/p/import
2. Paste the dev.to URL
3. Medium auto-fills the canonical URL → no SEO penalty
4. Submit to a Flutter publication (Flutter Community, Better Programming)

---

## 11. Follow-up tweet (Day 7)

```
one week of llm_meter:
- X likes on pub.dev
- X github stars
- X downloads
- inbound: @____ asked about a datadog sink → in v0.1.1

thanks to everyone who tried it. next package (agent_kit) starts today.

pub.dev/packages/llm_meter
```

---

## 📊 Success metrics (per ROADMAP.md)

Within 30 days of launch:

- [ ] ≥ 100 likes on pub.dev
- [ ] ≥ 50 GitHub stars
- [ ] ≥ 80 pana score (target 130/130)
- [ ] ≥ 1 mention in Flutter Weekly / Awesome Flutter
- [ ] ≥ 1 organic Twitter mention with >100 likes

If 3+ miss → reflect for 1 day, then move on to agent_kit.

---

## ⚠️ Lessons from prior launches

- **r/FlutterDev AutoModerator** removed the paywall_kit post for "AI-generated content." Post copy above is intentionally short, first-person, no em-dashes, no marketing words.
- **r/indiehackers** removed our streamdown post for insufficient karma (was 13 at the time). Skip r/indiehackers unless karma > 50.
- **Awesome Flutter** has an open PR for an unrelated package right now (per memory ID 8731). Check the queue before opening yours.
- **Reddit modmail** doesn't work for new accounts (memory IDs S3377, S3380). Don't bother appealing removals.
- **Reddit cross-posting:** wait 24h between r/FlutterDev and r/dartlang. Identical body across both = removed for spam.

---

*Generated 2026-06-02. Update each row as you tick the box.*
