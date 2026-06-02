/// Mixpanel telemetry sink — HTTP fallback (no SDK dependency).
library;

import 'dart:async';
import 'dart:convert';

import '../core/meter_event.dart';
import 'meter_sink.dart';
import '_posthog_http_io.dart'
    if (dart.library.html) '_posthog_http_web.dart' as http;

/// Sends events to Mixpanel's `/track` ingestion endpoint.
///
/// Like [PosthogSink], this sink talks raw HTTP and pulls in zero
/// third-party SDKs. The Mixpanel project token is the only credential
/// required; pass it via constructor argument — the package never reads
/// keys from env or shared prefs.
class MixpanelSink extends MeterSink {
  /// Build a Mixpanel sink.
  MixpanelSink({
    required this.token,
    this.host = 'https://api.mixpanel.com',
    this.distinctId = 'anonymous',
    this.eventName = 'llm_call',
    this.scrubGdpr = false,
  });

  /// Mixpanel project token.
  final String token;

  /// Ingestion host. Use `https://api-eu.mixpanel.com` for EU residency.
  final String host;

  /// `distinct_id` for the event.
  final String distinctId;

  /// Event name as it appears in Mixpanel.
  final String eventName;

  /// When `true`, [gdprScrub] is applied before send.
  final bool scrubGdpr;

  @override
  Future<void> record(MeterEvent event) async {
    final MeterEvent safe = scrubGdpr ? gdprScrub(event) : event;
    final Map<String, Object?> payload = <String, Object?>{
      'event': eventName,
      'properties': <String, Object?>{
        'token': token,
        'distinct_id': distinctId,
        'time': safe.timestamp.toUtc().millisecondsSinceEpoch,
        ...safe.toJson(),
      },
    };
    // Mixpanel /track wants a base64'd JSON `data` query param.
    final String b64 = base64UrlEncode(utf8.encode(jsonEncode(payload)));
    await http.postJson(
      url: '$host/track?data=$b64',
      body: const <String, Object?>{},
    );
  }
}
