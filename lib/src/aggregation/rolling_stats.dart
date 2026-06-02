/// Rolling statistics over a window of [MeterEvent]s.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/meter_event.dart';

/// Snapshot of stats computed over the events currently held by [LlmMeter].
///
/// All getters are O(1) — values are pre-computed when the snapshot is built.
@immutable
class MeterStats {
  /// Build an empty snapshot.
  const MeterStats.empty()
    : eventCount = 0,
      totalCostUsd = 0,
      totalTokensIn = 0,
      totalTokensOut = 0,
      totalCachedTokensIn = 0,
      p50LatencyMs = 0,
      p99LatencyMs = 0,
      cacheHitRatio = 0,
      lastCostUsd = 0,
      lastLatencyMs = 0,
      perModel = const <String, ModelStats>{};

  /// Build a snapshot. Prefer [MeterStats.compute] over the raw constructor.
  const MeterStats({
    required this.eventCount,
    required this.totalCostUsd,
    required this.totalTokensIn,
    required this.totalTokensOut,
    required this.totalCachedTokensIn,
    required this.p50LatencyMs,
    required this.p99LatencyMs,
    required this.cacheHitRatio,
    required this.lastCostUsd,
    required this.lastLatencyMs,
    required this.perModel,
  });

  /// Compute a snapshot from a list of events.
  ///
  /// `events` is treated as time-ordered (oldest first). Empty list returns
  /// [MeterStats.empty].
  factory MeterStats.compute(List<MeterEvent> events) {
    if (events.isEmpty) return const MeterStats.empty();

    int totalIn = 0;
    int totalOut = 0;
    int totalCached = 0;
    double totalCost = 0;
    final List<int> latenciesMs = <int>[];
    final Map<String, _PerModelAccumulator> perModelAcc =
        <String, _PerModelAccumulator>{};

    for (final MeterEvent e in events) {
      totalIn += e.tokensIn;
      totalOut += e.tokensOut;
      totalCached += e.cachedTokensIn;
      totalCost += e.costUsd;
      latenciesMs.add(e.latency.inMilliseconds);
      final _PerModelAccumulator acc = perModelAcc.putIfAbsent(
        e.model,
        _PerModelAccumulator.new,
      );
      acc.add(e);
    }

    final MeterEvent last = events.last;
    final double cacheRatio = (totalIn + totalCached) == 0
        ? 0
        : totalCached / (totalIn + totalCached);

    return MeterStats(
      eventCount: events.length,
      totalCostUsd: totalCost,
      totalTokensIn: totalIn,
      totalTokensOut: totalOut,
      totalCachedTokensIn: totalCached,
      p50LatencyMs: _percentile(latenciesMs, 0.50),
      p99LatencyMs: _percentile(latenciesMs, 0.99),
      cacheHitRatio: cacheRatio,
      lastCostUsd: last.costUsd,
      lastLatencyMs: last.latency.inMilliseconds,
      perModel: <String, ModelStats>{
        for (final MapEntry<String, _PerModelAccumulator> e
            in perModelAcc.entries)
          e.key: e.value.toStats(),
      },
    );
  }

  /// Number of events in the window.
  final int eventCount;

  /// Sum of `costUsd` across the window.
  final double totalCostUsd;

  /// Sum of `tokensIn`.
  final int totalTokensIn;

  /// Sum of `tokensOut`.
  final int totalTokensOut;

  /// Sum of `cachedTokensIn`.
  final int totalCachedTokensIn;

  /// p50 (median) latency in milliseconds.
  final int p50LatencyMs;

  /// p99 latency in milliseconds.
  final int p99LatencyMs;

  /// Cache-hit ratio in `[0, 1]` — cached / (tokensIn + cachedTokensIn).
  final double cacheHitRatio;

  /// Cost in USD of the most recently recorded event.
  final double lastCostUsd;

  /// Latency in ms of the most recently recorded event.
  final int lastLatencyMs;

  /// Per-model breakdown.
  final Map<String, ModelStats> perModel;

  @override
  String toString() =>
      'MeterStats(events=$eventCount, \$${totalCostUsd.toStringAsFixed(6)}, '
      'p50=${p50LatencyMs}ms, p99=${p99LatencyMs}ms, '
      'cache=${(cacheHitRatio * 100).toStringAsFixed(0)}%)';
}

/// Per-model summary.
@immutable
class ModelStats {
  /// Build a per-model summary.
  const ModelStats({
    required this.model,
    required this.eventCount,
    required this.totalCostUsd,
    required this.tokensIn,
    required this.tokensOut,
    required this.cachedTokensIn,
  });

  /// Model id.
  final String model;

  /// Number of events for this model.
  final int eventCount;

  /// Sum of cost in USD for this model.
  final double totalCostUsd;

  /// Sum of input tokens.
  final int tokensIn;

  /// Sum of output tokens.
  final int tokensOut;

  /// Sum of cached input tokens.
  final int cachedTokensIn;
}

class _PerModelAccumulator {
  _PerModelAccumulator()
    : eventCount = 0,
      totalCost = 0,
      tokensIn = 0,
      tokensOut = 0,
      cachedTokensIn = 0,
      model = '';

  String model;
  int eventCount;
  double totalCost;
  int tokensIn;
  int tokensOut;
  int cachedTokensIn;

  void add(MeterEvent e) {
    model = e.model;
    eventCount += 1;
    totalCost += e.costUsd;
    tokensIn += e.tokensIn;
    tokensOut += e.tokensOut;
    cachedTokensIn += e.cachedTokensIn;
  }

  ModelStats toStats() => ModelStats(
    model: model,
    eventCount: eventCount,
    totalCostUsd: totalCost,
    tokensIn: tokensIn,
    tokensOut: tokensOut,
    cachedTokensIn: cachedTokensIn,
  );
}

/// Linear interpolation percentile over an unsorted integer list.
///
/// `ratio` must be in `[0, 1]`. Returns 0 for empty lists. Sort is done
/// in-place on a copy so the caller's list is untouched.
int _percentile(List<int> values, double ratio) {
  if (values.isEmpty) return 0;
  final List<int> sorted = List<int>.from(values)..sort();
  if (sorted.length == 1) return sorted.first;
  final double pos = (sorted.length - 1) * ratio;
  final int lo = pos.floor();
  final int hi = pos.ceil();
  if (lo == hi) return sorted[lo];
  final double frac = pos - lo;
  return (sorted[lo] + (sorted[hi] - sorted[lo]) * frac).round();
}

/// Fixed-capacity, O(1) push ring buffer. Drops the oldest entry when full.
class RingBuffer<T> {
  /// Build a ring buffer with [capacity] slots.
  RingBuffer(this.capacity)
    : assert(capacity > 0, 'capacity must be > 0'),
      _data = List<T?>.filled(capacity, null, growable: false);

  /// Maximum number of items held.
  final int capacity;
  final List<T?> _data;
  int _head = 0;
  int _size = 0;

  /// Current number of items (`<= capacity`).
  int get length => _size;

  /// `true` when at least one item has been added.
  bool get isNotEmpty => _size > 0;

  /// `true` when no items are held.
  bool get isEmpty => _size == 0;

  /// Add [item] to the buffer; drop oldest if at [capacity].
  void add(T item) {
    final int idx = (_head + _size) % capacity;
    _data[idx] = item;
    if (_size == capacity) {
      _head = (_head + 1) % capacity;
    } else {
      _size += 1;
    }
  }

  /// Remove all items.
  void clear() {
    for (int i = 0; i < capacity; i++) {
      _data[i] = null;
    }
    _head = 0;
    _size = 0;
  }

  /// Snapshot the buffer in insertion order (oldest first).
  List<T> toList() {
    final List<T> out = List<T>.generate(
      _size,
      (int i) => _data[(_head + i) % capacity]! as T,
      growable: false,
    );
    return UnmodifiableListView<T>(out);
  }
}
