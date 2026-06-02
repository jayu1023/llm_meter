/// dart:io implementation for the PostHog HTTP sink.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Best-effort fire-and-forget JSON POST. Errors are swallowed — wrap a
/// PostHog sink in `RetryingSink` if you need durable delivery.
Future<void> postJson({
  required String url,
  required Map<String, Object?> body,
}) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest req = await client.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(body)));
    final HttpClientResponse res = await req.close();
    await res.drain<void>();
  } on Object catch (_) {
    // best-effort
  } finally {
    client.close(force: false);
  }
}
