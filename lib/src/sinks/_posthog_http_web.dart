/// Web no-op fallback for PostHog HTTP sink.
///
/// Use a real PostHog integration (JS snippet or a `package:http`-based sink)
/// in your own [MeterSink] when targeting web.
library;

import 'dart:async';

/// No-op on web — see file-level docs.
Future<void> postJson({
  required String url,
  required Map<String, Object?> body,
}) async {}
