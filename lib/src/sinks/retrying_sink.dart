/// Decorator that retries failed sends with exponential backoff and keeps
/// failures in an offline queue.
library;

import 'dart:async';
import 'dart:math' as math;

import '../core/meter_event.dart';
import 'meter_sink.dart';

/// Wraps another [MeterSink] and retries on failure.
///
/// "Failure" means the inner sink throws. Most well-behaved sinks swallow
/// network errors internally, so this decorator is most useful when you wrap
/// a thin HTTP sink that *does* throw on non-2xx.
///
/// Backoff: `delay = baseDelay * 2^(attempt - 1)`, capped at [maxDelay].
class RetryingSink extends MeterSink {
  /// Build a retry decorator.
  RetryingSink({
    required this.inner,
    this.maxAttempts = 5,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 30),
    this.offlineQueueLimit = 1000,
  }) : assert(maxAttempts > 0, 'maxAttempts must be > 0');

  /// The wrapped sink.
  final MeterSink inner;

  /// Max attempts per event before parking it in the offline queue.
  final int maxAttempts;

  /// Initial backoff delay.
  final Duration baseDelay;

  /// Backoff cap.
  final Duration maxDelay;

  /// Hard cap on offline queue size. Oldest events are dropped first.
  final int offlineQueueLimit;

  final List<MeterEvent> _offlineQueue = <MeterEvent>[];

  /// Snapshot of currently-queued events that haven't reached the inner sink.
  List<MeterEvent> get offlineQueue =>
      List<MeterEvent>.unmodifiable(_offlineQueue);

  @override
  Future<void> record(MeterEvent event) async {
    final bool delivered = await _attempt(event);
    if (!delivered) _park(event);
  }

  Future<bool> _attempt(MeterEvent event) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await inner.record(event);
        return true;
      } on Object catch (_) {
        if (attempt == maxAttempts) return false;
        final int ms = math.min(
          maxDelay.inMilliseconds,
          baseDelay.inMilliseconds * (1 << (attempt - 1)),
        );
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
    }
    return false;
  }

  void _park(MeterEvent e) {
    if (_offlineQueue.length >= offlineQueueLimit) {
      _offlineQueue.removeAt(0);
    }
    _offlineQueue.add(e);
  }

  /// Try to deliver every parked event. Successful ones leave the queue.
  /// Failed ones stay parked.
  Future<void> drainOfflineQueue() async {
    final List<MeterEvent> snapshot = List<MeterEvent>.from(_offlineQueue);
    _offlineQueue.clear();
    for (final MeterEvent e in snapshot) {
      final bool ok = await _attempt(e);
      if (!ok) _park(e);
    }
  }

  @override
  Future<void> flush() async {
    await drainOfflineQueue();
    await inner.flush();
  }

  @override
  Future<void> close() async {
    await inner.close();
  }
}
