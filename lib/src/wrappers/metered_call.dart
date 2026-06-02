/// Drop-in instrumentation for non-streaming LLM calls.
library;

import '../core/meter.dart';
import '../core/meter_event.dart';

/// Token usage extracted from a provider response.
class MeterUsage {
  /// Build a usage record.
  const MeterUsage({
    required this.tokensIn,
    required this.tokensOut,
    this.cachedTokensIn = 0,
  });

  /// Empty usage — useful when an error occurs before the response is parsed.
  static const MeterUsage empty = MeterUsage(tokensIn: 0, tokensOut: 0);

  /// Input (prompt) tokens billed.
  final int tokensIn;

  /// Output (completion) tokens billed.
  final int tokensOut;

  /// Cached prompt tokens, billed at the cache discount.
  final int cachedTokensIn;
}

/// Signature for converting a provider response into a [MeterUsage].
typedef UsageExtractor<T> = MeterUsage Function(T response);

/// Wrap any LLM Future + extractor so the meter records it automatically.
///
/// ```dart
/// final response = await MeteredCall.run<OpenAIResponse>(
///   provider: 'openai',
///   model: 'gpt-5',
///   call: () => openai.chat.create(model: 'gpt-5', messages: [...]),
///   extract: (r) => MeterUsage(
///     tokensIn: r.usage.promptTokens,
///     tokensOut: r.usage.completionTokens,
///     cachedTokensIn: r.usage.cachedPromptTokens ?? 0,
///   ),
/// );
/// ```
///
/// Errors are re-thrown after a zero-cost event is recorded with the error
/// message attached.
class MeteredCall {
  const MeteredCall._();

  /// Run [call] and record the result.
  ///
  /// On success: records a [MeterEvent] with the extracted usage and the
  /// measured latency, then returns the response.
  ///
  /// On failure: records a zero-cost event with `error` set, then rethrows.
  static Future<T> run<T>({
    required String provider,
    required String model,
    required Future<T> Function() call,
    required UsageExtractor<T> extract,
    String? conversationId,
    String? requestId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    try {
      final T response = await call();
      sw.stop();
      final MeterUsage usage = extract(response);
      LlmMeter.instance.record(
        MeterEvent(
          provider: provider,
          model: model,
          tokensIn: usage.tokensIn,
          tokensOut: usage.tokensOut,
          cachedTokensIn: usage.cachedTokensIn,
          costUsd: 0, // resolved by the meter from the pricing table
          latency: sw.elapsed,
          timestamp: DateTime.now(),
          conversationId: conversationId,
          requestId: requestId,
          metadata: metadata,
        ),
      );
      return response;
    } on Object catch (e) {
      sw.stop();
      LlmMeter.instance.record(
        MeterEvent(
          provider: provider,
          model: model,
          tokensIn: 0,
          tokensOut: 0,
          costUsd: 0,
          latency: sw.elapsed,
          timestamp: DateTime.now(),
          conversationId: conversationId,
          requestId: requestId,
          error: e.toString(),
          metadata: metadata,
        ),
      );
      rethrow;
    }
  }
}
