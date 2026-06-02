import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

MeterEvent e({
  String model = 'gpt-5',
  int tokensIn = 100,
  int tokensOut = 50,
  int cached = 0,
  double cost = 0.001,
  int latencyMs = 200,
  DateTime? ts,
}) => MeterEvent(
  provider: 'openai',
  model: model,
  tokensIn: tokensIn,
  tokensOut: tokensOut,
  cachedTokensIn: cached,
  costUsd: cost,
  latency: Duration(milliseconds: latencyMs),
  timestamp: ts ?? DateTime.utc(2026, 6, 1),
);

void main() {
  group('MeterStats.compute', () {
    test('empty list returns empty snapshot', () {
      const MeterStats empty = MeterStats.empty();
      final MeterStats s = MeterStats.compute(const <MeterEvent>[]);
      expect(s.eventCount, empty.eventCount);
      expect(s.totalCostUsd, empty.totalCostUsd);
      expect(s.perModel, isEmpty);
    });

    test('aggregates totals across events', () {
      final MeterStats s = MeterStats.compute(<MeterEvent>[
        e(tokensIn: 100, tokensOut: 50, cost: 0.01, latencyMs: 100),
        e(tokensIn: 200, tokensOut: 100, cost: 0.02, latencyMs: 300),
        e(tokensIn: 300, tokensOut: 150, cost: 0.03, latencyMs: 500),
      ]);
      expect(s.eventCount, 3);
      expect(s.totalTokensIn, 600);
      expect(s.totalTokensOut, 300);
      expect(s.totalCostUsd, closeTo(0.06, 1e-9));
    });

    test('p50 and p99 latency', () {
      final List<MeterEvent> events = <MeterEvent>[
        for (int i = 1; i <= 100; i++) e(latencyMs: i * 10),
      ];
      final MeterStats s = MeterStats.compute(events);
      // p50 of 1..100 (10ms steps) ~ index 49.5 -> 500..510 -> 505 rounded
      expect(s.p50LatencyMs, inInclusiveRange(495, 515));
      // p99 of 1..100 (10ms steps) ~ index 98.01 -> ~991
      expect(s.p99LatencyMs, inInclusiveRange(980, 1000));
    });

    test('single-event p50 == p99 == event latency', () {
      final MeterStats s = MeterStats.compute(<MeterEvent>[e(latencyMs: 420)]);
      expect(s.p50LatencyMs, 420);
      expect(s.p99LatencyMs, 420);
    });

    test('cache hit ratio over the window', () {
      final MeterStats s = MeterStats.compute(<MeterEvent>[
        e(tokensIn: 200, cached: 800),
        e(tokensIn: 800, cached: 200),
      ]);
      // total in = 1000, total cached = 1000 -> ratio = 0.5
      expect(s.cacheHitRatio, 0.5);
    });

    test('per-model breakdown sums costs and tokens', () {
      final MeterStats s = MeterStats.compute(<MeterEvent>[
        e(model: 'gpt-5', cost: 0.01, tokensIn: 100, tokensOut: 50),
        e(model: 'gpt-5', cost: 0.02, tokensIn: 200, tokensOut: 100),
        e(
          model: 'claude-sonnet-4-6',
          cost: 0.05,
          tokensIn: 300,
          tokensOut: 150,
        ),
      ]);
      expect(s.perModel['gpt-5']!.eventCount, 2);
      expect(s.perModel['gpt-5']!.totalCostUsd, closeTo(0.03, 1e-9));
      expect(s.perModel['gpt-5']!.tokensIn, 300);
      expect(s.perModel['claude-sonnet-4-6']!.eventCount, 1);
      expect(
        s.perModel['claude-sonnet-4-6']!.totalCostUsd,
        closeTo(0.05, 1e-9),
      );
    });

    test('last* tracks the most recently added event', () {
      final MeterStats s = MeterStats.compute(<MeterEvent>[
        e(cost: 0.01, latencyMs: 100),
        e(cost: 0.02, latencyMs: 200),
        e(cost: 0.99, latencyMs: 999),
      ]);
      expect(s.lastCostUsd, 0.99);
      expect(s.lastLatencyMs, 999);
    });
  });
}
