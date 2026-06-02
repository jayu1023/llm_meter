/// Decorator that batches events before forwarding to an inner sink.
library;

import 'dart:async';

import '../core/meter_event.dart';
import 'meter_sink.dart';

/// Wraps another [MeterSink] and flushes events in batches.
///
/// Flushes whenever either threshold is reached:
///   * `maxBatchSize` events have been queued, or
///   * `flushInterval` has elapsed since the first event in the batch.
///
/// Calling [flush] / [close] drains the queue immediately.
class BatchingSink extends MeterSink {
  /// Build a batching decorator around [inner].
  BatchingSink({
    required this.inner,
    this.maxBatchSize = 20,
    this.flushInterval = const Duration(seconds: 5),
  }) : assert(maxBatchSize > 0, 'maxBatchSize must be > 0');

  /// The wrapped sink that receives flushed events.
  final MeterSink inner;

  /// Trigger flush when the queue reaches this many events.
  final int maxBatchSize;

  /// Trigger flush this long after the first queued event.
  final Duration flushInterval;

  final List<MeterEvent> _queue = <MeterEvent>[];
  Timer? _timer;

  @override
  Future<void> record(MeterEvent event) async {
    _queue.add(event);
    if (_queue.length >= maxBatchSize) {
      await flush();
      return;
    }
    _timer ??= Timer(flushInterval, () => unawaited(flush()));
  }

  @override
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final List<MeterEvent> drained = List<MeterEvent>.from(_queue);
    _queue.clear();
    for (final MeterEvent e in drained) {
      try {
        await inner.record(e);
      } on Object catch (_) {
        // inner.record contract says no throw; defensive swallow.
      }
    }
    await inner.flush();
  }

  @override
  Future<void> close() async {
    await flush();
    await inner.close();
  }
}
