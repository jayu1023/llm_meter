/// The [LlmMeter] singleton — entry point for recording LLM calls and
/// observing rolling stats.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../aggregation/rolling_stats.dart';
import '../pricing/pricing_table.dart';
import '../sinks/meter_sink.dart';
import 'meter_config.dart';
import 'meter_event.dart';

/// The meter singleton.
///
/// Call [LlmMeter.init] once from `main()`, then [record] for each LLM call
/// (or use a `MeteredCall` wrapper). Listen to [stream] for live updates.
class LlmMeter {
  LlmMeter._() : _config = MeterConfig.defaults {
    _buffer = RingBuffer<MeterEvent>(_config.bufferCapacity);
  }

  /// The single global meter instance.
  static final LlmMeter instance = LlmMeter._();

  MeterConfig _config;
  late RingBuffer<MeterEvent> _buffer;
  final StreamController<MeterEvent> _events =
      StreamController<MeterEvent>.broadcast();

  /// The active [MeterConfig].
  MeterConfig get config => _config;

  /// Broadcast stream of every recorded [MeterEvent]. New listeners only see
  /// events recorded *after* they subscribe.
  Stream<MeterEvent> get stream => _events.stream;

  /// Initialize (or re-initialize) the meter.
  ///
  /// Safe to call multiple times — the new config replaces the old one and
  /// the event buffer is reset.
  static void init(MeterConfig config) => instance._init(config);

  void _init(MeterConfig config) {
    _config = config;
    _buffer = RingBuffer<MeterEvent>(config.bufferCapacity);
  }

  /// Record an event. Sinks fire asynchronously and do not block the caller.
  ///
  /// Returns the event after attaching a computed `costUsd` if the caller
  /// passed `0` and the model id resolves to a price.
  MeterEvent record(MeterEvent event) {
    final MeterEvent resolved = _resolveCost(event);
    _buffer.add(resolved);
    if (!_events.isClosed) {
      _events.add(resolved);
    }
    for (final MeterSink sink in _config.sinks) {
      // Fan out without blocking the caller. Sink contract says it never
      // throws, but we still guard so a stray exception cannot kill the
      // futures chain.
      unawaited(
        Future<void>(() => sink.record(resolved)).catchError((Object _) {}),
      );
    }
    return resolved;
  }

  MeterEvent _resolveCost(MeterEvent event) {
    if (event.costUsd != 0) return event;
    final double computed = priceForModel(
      model: event.model,
      tokensIn: event.tokensIn,
      tokensOut: event.tokensOut,
      cachedTokensIn: event.cachedTokensIn,
      overrides: _config.pricingOverrides,
    );
    if (computed == 0) return event;
    return event.copyWith(costUsd: computed);
  }

  /// Current snapshot of stats over the buffered window.
  MeterStats stats() => MeterStats.compute(_buffer.toList());

  /// Snapshot of the buffered events (oldest first). Returns an unmodifiable
  /// list — copy first if you intend to mutate.
  List<MeterEvent> events() => _buffer.toList();

  /// Wipe the buffer. Stats reset to zero. Sinks are *not* notified.
  void clear() => _buffer.clear();

  /// Flush every sink and tear down the broadcast stream. After [shutdown],
  /// [stream] is closed and [record] still buffers but no sink will fire.
  ///
  /// Mostly useful in tests and short-lived background isolates.
  @visibleForTesting
  Future<void> shutdown() async {
    for (final MeterSink sink in _config.sinks) {
      try {
        await sink.flush();
        await sink.close();
      } on Object catch (_) {
        // ignore — sinks are best-effort
      }
    }
    await _events.close();
  }
}
