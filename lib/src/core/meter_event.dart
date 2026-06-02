/// {@template meter_event}
/// A single LLM call recorded by [LlmMeter].
///
/// One [MeterEvent] = one provider call. Fields are immutable so events can be
/// safely passed across isolates or persisted to disk by a sink.
/// {@endtemplate}
library;

import 'package:flutter/foundation.dart';

/// Immutable record of a single LLM API call.
///
/// {@macro meter_event}
@immutable
class MeterEvent {
  /// {@macro meter_event}
  const MeterEvent({
    required this.provider,
    required this.model,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    required this.latency,
    required this.timestamp,
    this.cachedTokensIn = 0,
    this.conversationId,
    this.requestId,
    this.streaming = false,
    this.error,
    this.metadata = const <String, Object?>{},
  });

  /// Provider name, lower-case. e.g. `openai`, `anthropic`, `gemini`.
  final String provider;

  /// Model id as the provider expects it. e.g. `gpt-5`, `claude-4-7-sonnet`.
  final String model;

  /// Input (prompt) tokens billed by the provider.
  ///
  /// Does NOT include cached tokens — those are billed at a discount and live
  /// in [cachedTokensIn].
  final int tokensIn;

  /// Output (completion) tokens billed by the provider.
  final int tokensOut;

  /// Cached prompt tokens (Anthropic cache hits, Gemini context cache, etc.).
  ///
  /// Billed at the model's `cachedInputRate` if set, otherwise at full
  /// `inputRate`.
  final int cachedTokensIn;

  /// Total cost in USD as billed by the provider, including the cache
  /// discount if any.
  final double costUsd;

  /// Wall-clock latency for the call (request → final byte).
  final Duration latency;

  /// When the call completed.
  final DateTime timestamp;

  /// Optional conversation grouping id. Lets the HUD show "$ this chat".
  final String? conversationId;

  /// Optional provider request id (e.g. OpenAI `id`) for correlation with
  /// provider-side logs.
  final String? requestId;

  /// Whether this event came from a streaming response.
  final bool streaming;

  /// Error message if the call failed. Cost/tokens may be zero in this case.
  final String? error;

  /// Free-form metadata. Sinks may serialize this; keep it small + JSON-safe.
  final Map<String, Object?> metadata;

  /// Total tokens (input + output + cached input).
  int get totalTokens => tokensIn + tokensOut + cachedTokensIn;

  /// Cache hit ratio in `[0, 1]`. Returns `0` when there is no input at all.
  double get cacheHitRatio {
    final int totalIn = tokensIn + cachedTokensIn;
    if (totalIn == 0) return 0;
    return cachedTokensIn / totalIn;
  }

  /// Copy this event, overriding any field.
  MeterEvent copyWith({
    String? provider,
    String? model,
    int? tokensIn,
    int? tokensOut,
    int? cachedTokensIn,
    double? costUsd,
    Duration? latency,
    DateTime? timestamp,
    String? conversationId,
    String? requestId,
    bool? streaming,
    String? error,
    Map<String, Object?>? metadata,
  }) {
    return MeterEvent(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      cachedTokensIn: cachedTokensIn ?? this.cachedTokensIn,
      costUsd: costUsd ?? this.costUsd,
      latency: latency ?? this.latency,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      requestId: requestId ?? this.requestId,
      streaming: streaming ?? this.streaming,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON-serializable map. Safe to ship to telemetry sinks.
  Map<String, Object?> toJson() => <String, Object?>{
    'provider': provider,
    'model': model,
    'tokens_in': tokensIn,
    'tokens_out': tokensOut,
    'cached_tokens_in': cachedTokensIn,
    'cost_usd': costUsd,
    'latency_ms': latency.inMilliseconds,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (conversationId != null) 'conversation_id': conversationId,
    if (requestId != null) 'request_id': requestId,
    'streaming': streaming,
    if (error != null) 'error': error,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterEvent &&
        other.provider == provider &&
        other.model == model &&
        other.tokensIn == tokensIn &&
        other.tokensOut == tokensOut &&
        other.cachedTokensIn == cachedTokensIn &&
        other.costUsd == costUsd &&
        other.latency == latency &&
        other.timestamp == timestamp &&
        other.conversationId == conversationId &&
        other.requestId == requestId &&
        other.streaming == streaming &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    provider,
    model,
    tokensIn,
    tokensOut,
    cachedTokensIn,
    costUsd,
    latency,
    timestamp,
    conversationId,
    requestId,
    streaming,
    error,
  );

  @override
  String toString() =>
      'MeterEvent($provider/$model, in=$tokensIn out=$tokensOut '
      'cached=$cachedTokensIn, \$${costUsd.toStringAsFixed(6)}, '
      '${latency.inMilliseconds}ms${streaming ? ", stream" : ""}'
      '${error != null ? ", error=$error" : ""})';
}
