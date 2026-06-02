/// Abstract telemetry sink interface.
library;

import '../core/meter_event.dart';

/// Receives every [MeterEvent] that the meter records.
///
/// Implementations should:
///   * be non-blocking — return quickly or do their I/O off the UI thread
///   * tolerate transient failures internally (never throw to caller)
///   * be safe to call concurrently
///
/// Failures in one sink do not affect any other sink registered on
/// [LlmMeter].
abstract class MeterSink {
  /// Const constructor so subclasses can be const.
  const MeterSink();

  /// Called once per recorded event.
  ///
  /// Implementations must not throw; catch and swallow recoverable errors,
  /// optionally re-queueing for retry.
  Future<void> record(MeterEvent event);

  /// Optional batch flush hook. Called by `BatchingSink` and by `LlmMeter`
  /// on shutdown. Default is a no-op.
  Future<void> flush() async {}

  /// Optional teardown hook. Default is a no-op.
  Future<void> close() async {}
}

/// Redacts user-correlatable fields from [event] for GDPR-safe transmission.
///
/// Sinks should call this when `MeterConfig.gdprMode` is `true`. Currently
/// scrubs `conversationId`, `requestId`, and any `user_*` metadata keys.
MeterEvent gdprScrub(MeterEvent event) {
  final Map<String, Object?> safeMeta = <String, Object?>{};
  for (final MapEntry<String, Object?> entry in event.metadata.entries) {
    if (entry.key.startsWith('user') ||
        entry.key.contains('email') ||
        entry.key.contains('ip')) {
      continue;
    }
    safeMeta[entry.key] = entry.value;
  }
  return MeterEvent(
    provider: event.provider,
    model: event.model,
    tokensIn: event.tokensIn,
    tokensOut: event.tokensOut,
    cachedTokensIn: event.cachedTokensIn,
    costUsd: event.costUsd,
    latency: event.latency,
    timestamp: event.timestamp,
    streaming: event.streaming,
    error: event.error,
    metadata: safeMeta,
  );
}
