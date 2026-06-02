/// PostHog telemetry sink — HTTP fallback (no SDK dependency).
library;

import 'dart:async';

import '../core/meter_event.dart';
import 'meter_sink.dart';
import '_posthog_http_io.dart'
    if (dart.library.html) '_posthog_http_web.dart' as http;

/// Send events to PostHog's `/capture/` endpoint via plain HTTP.
///
/// **No third-party SDK is imported** — this sink uses only the SDK HTTP
/// client. That keeps `llm_meter` install-size flat.
///
/// On web targets this sink becomes a silent no-op; install the PostHog JS
/// snippet in your `web/index.html` and forward events from your own
/// [MeterSink] subclass instead.
///
/// Provide your project's `apiKey` and (optionally) a self-hosted [host]. The
/// key is read from constructor args only — **never** from the package or
/// from env vars. You stay in full control of where the key lives.
class PosthogSink extends MeterSink {
  /// Build a PostHog sink.
  PosthogSink({
    required this.apiKey,
    this.host = 'https://app.posthog.com',
    this.distinctId = 'anonymous',
    this.eventName = 'llm_call',
    this.scrubGdpr = false,
  });

  /// PostHog project API key. Required.
  final String apiKey;

  /// PostHog ingestion host. Defaults to US cloud.
  final String host;

  /// `distinct_id` for the event. Defaults to `'anonymous'`.
  final String distinctId;

  /// Event name as it will appear in PostHog. Defaults to `'llm_call'`.
  final String eventName;

  /// When `true`, [gdprScrub] is applied to every event before send.
  final bool scrubGdpr;

  @override
  Future<void> record(MeterEvent event) async {
    final MeterEvent safe = scrubGdpr ? gdprScrub(event) : event;
    await http.postJson(
      url: '$host/capture/',
      body: <String, Object?>{
        'api_key': apiKey,
        'event': eventName,
        'distinct_id': distinctId,
        'properties': safe.toJson(),
        'timestamp': safe.timestamp.toUtc().toIso8601String(),
      },
    );
  }
}
