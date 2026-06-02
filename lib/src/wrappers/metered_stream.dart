/// Drop-in instrumentation for streaming LLM responses.
library;

import 'dart:async';

import '../core/meter.dart';
import '../core/meter_event.dart';
import 'metered_call.dart';

/// Signature for accumulating per-chunk usage info during a stream.
///
/// Called for every chunk. Return a *delta* — the wrapper sums them.
/// Returning `null` means "no usage info in this chunk" (common for
/// non-final chunks).
typedef ChunkUsageExtractor<C> = MeterUsage? Function(C chunk);

/// Wraps a `Stream<C>` of LLM chunks so the meter records the full call once
/// the stream completes.
///
/// ```dart
/// final stream = MeteredStream.wrap<OpenAIChunk>(
///   provider: 'openai',
///   model: 'gpt-5',
///   stream: openai.chat.createStream(...),
///   extractChunk: (chunk) => chunk.usage == null
///       ? null
///       : MeterUsage(
///           tokensIn: chunk.usage!.promptTokens,
///           tokensOut: chunk.usage!.completionTokens,
///         ),
/// );
/// await for (final c in stream) {
///   uiAppend(c.text);
/// }
/// ```
///
/// The recorded event has `streaming: true`. Latency is measured from the
/// first `listen` call until the source stream emits `done`. On error the
/// event is still recorded with whatever usage was accumulated so far + the
/// error message attached.
class MeteredStream {
  const MeteredStream._();

  /// Wrap [stream] and return a passthrough that records when complete.
  static Stream<C> wrap<C>({
    required String provider,
    required String model,
    required Stream<C> stream,
    required ChunkUsageExtractor<C> extractChunk,
    String? conversationId,
    String? requestId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final Stopwatch sw = Stopwatch();
    int tokensIn = 0;
    int tokensOut = 0;
    int cachedTokensIn = 0;

    final StreamController<C> out = StreamController<C>(sync: true);
    StreamSubscription<C>? sub;

    void recordFinal({String? error}) {
      sw.stop();
      LlmMeter.instance.record(
        MeterEvent(
          provider: provider,
          model: model,
          tokensIn: tokensIn,
          tokensOut: tokensOut,
          cachedTokensIn: cachedTokensIn,
          costUsd: 0,
          latency: sw.elapsed,
          timestamp: DateTime.now(),
          conversationId: conversationId,
          requestId: requestId,
          streaming: true,
          error: error,
          metadata: metadata,
        ),
      );
    }

    out.onListen = () {
      sw.start();
      sub = stream.listen(
        (C chunk) {
          // Accumulate any usage info attached to this chunk.
          final MeterUsage? usage = extractChunk(chunk);
          if (usage != null) {
            // Most providers send a *running total* in the final chunk; some
            // send per-chunk deltas. Take the larger of the two so total
            // counts match either pattern.
            tokensIn = usage.tokensIn > tokensIn ? usage.tokensIn : tokensIn;
            tokensOut = usage.tokensOut > tokensOut
                ? usage.tokensOut
                : tokensOut;
            cachedTokensIn = usage.cachedTokensIn > cachedTokensIn
                ? usage.cachedTokensIn
                : cachedTokensIn;
          }
          out.add(chunk);
        },
        onError: (Object error, StackTrace st) {
          recordFinal(error: error.toString());
          out.addError(error, st);
        },
        onDone: () {
          recordFinal();
          out.close();
        },
      );
    };
    out.onCancel = () async {
      await sub?.cancel();
      if (sw.isRunning) {
        // Consumer cancelled mid-stream — record what we have.
        recordFinal(error: 'cancelled');
      }
    };
    out.onPause = () => sub?.pause();
    out.onResume = () => sub?.resume();

    return out.stream;
  }
}
