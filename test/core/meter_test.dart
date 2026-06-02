import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

class _CapturingSink extends MeterSink {
  _CapturingSink();
  final List<MeterEvent> received = <MeterEvent>[];
  int flushCount = 0;
  int closeCount = 0;

  @override
  Future<void> record(MeterEvent event) async {
    received.add(event);
  }

  @override
  Future<void> flush() async {
    flushCount += 1;
  }

  @override
  Future<void> close() async {
    closeCount += 1;
  }
}

class _ThrowingSink extends MeterSink {
  _ThrowingSink();
  @override
  Future<void> record(MeterEvent event) async {
    throw StateError('boom');
  }
}

MeterEvent _evt({
  String model = 'gpt-5',
  int tokensIn = 100,
  int tokensOut = 50,
  double cost = 0,
  int latencyMs = 100,
}) => MeterEvent(
  provider: 'openai',
  model: model,
  tokensIn: tokensIn,
  tokensOut: tokensOut,
  costUsd: cost,
  latency: Duration(milliseconds: latencyMs),
  timestamp: DateTime.utc(2026, 6, 1),
);

void main() {
  setUp(() {
    LlmMeter.init(MeterConfig.defaults);
    LlmMeter.instance.clear();
  });

  group('LlmMeter.record', () {
    test('adds event to the buffer', () {
      LlmMeter.instance.record(_evt(cost: 0.01));
      expect(LlmMeter.instance.events().length, 1);
      expect(LlmMeter.instance.events().first.costUsd, 0.01);
    });

    test('computes cost when caller passes 0 and model is known', () {
      final MeterEvent e = LlmMeter.instance.record(
        _evt(tokensIn: 1000, tokensOut: 2000),
      );
      // gpt-5: 1000 * 1.25e-6 + 2000 * 10e-6 = 0.02125
      expect(e.costUsd, closeTo(0.02125, 1e-9));
    });

    test('respects caller-supplied cost', () {
      final MeterEvent e = LlmMeter.instance.record(_evt(cost: 0.99));
      expect(e.costUsd, 0.99);
    });

    test('unknown model with 0 cost stays at 0', () {
      final MeterEvent e = LlmMeter.instance.record(_evt(model: 'not-a-model'));
      expect(e.costUsd, 0);
    });

    test('pricing overrides win', () {
      LlmMeter.init(
        const MeterConfig(
          pricingOverrides: <String, ModelPricing>{
            'gpt-5': ModelPricing.perMillion(
              inputPerMillion: 100.0,
              outputPerMillion: 100.0,
            ),
          },
        ),
      );
      final MeterEvent e = LlmMeter.instance.record(
        _evt(tokensIn: 1000, tokensOut: 1000),
      );
      // 1000 * 100e-6 + 1000 * 100e-6 = 0.2
      expect(e.costUsd, closeTo(0.2, 1e-9));
    });

    test('buffer caps at config.bufferCapacity', () {
      LlmMeter.init(const MeterConfig(bufferCapacity: 3));
      for (int i = 0; i < 5; i++) {
        LlmMeter.instance.record(_evt(cost: 0.0001 * i));
      }
      expect(LlmMeter.instance.events().length, 3);
    });
  });

  group('LlmMeter.stream', () {
    test('emits each recorded event in order', () async {
      final List<MeterEvent> seen = <MeterEvent>[];
      final StreamSubscription<MeterEvent> sub = LlmMeter.instance.stream
          .listen(seen.add);
      LlmMeter.instance.record(_evt(cost: 0.01));
      LlmMeter.instance.record(_evt(cost: 0.02));
      LlmMeter.instance.record(_evt(cost: 0.03));
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((MeterEvent e) => e.costUsd), <double>[0.01, 0.02, 0.03]);
      await sub.cancel();
    });

    test('is a broadcast stream — supports multiple listeners', () async {
      final List<MeterEvent> a = <MeterEvent>[];
      final List<MeterEvent> b = <MeterEvent>[];
      final StreamSubscription<MeterEvent> sa = LlmMeter.instance.stream.listen(
        a.add,
      );
      final StreamSubscription<MeterEvent> sb = LlmMeter.instance.stream.listen(
        b.add,
      );
      LlmMeter.instance.record(_evt(cost: 0.01));
      await Future<void>.delayed(Duration.zero);
      expect(a.length, 1);
      expect(b.length, 1);
      await sa.cancel();
      await sb.cancel();
    });

    test('new subscribers only get future events', () async {
      LlmMeter.instance.record(_evt(cost: 0.01));
      await Future<void>.delayed(Duration.zero);
      final List<MeterEvent> seen = <MeterEvent>[];
      final StreamSubscription<MeterEvent> sub = LlmMeter.instance.stream
          .listen(seen.add);
      LlmMeter.instance.record(_evt(cost: 0.02));
      await Future<void>.delayed(Duration.zero);
      expect(seen.length, 1);
      expect(seen.first.costUsd, 0.02);
      await sub.cancel();
    });
  });

  group('LlmMeter sinks', () {
    test('record fans out to every sink', () async {
      final _CapturingSink a = _CapturingSink();
      final _CapturingSink b = _CapturingSink();
      LlmMeter.init(MeterConfig(sinks: <MeterSink>[a, b]));
      LlmMeter.instance.record(_evt(cost: 0.01));
      await Future<void>.delayed(Duration.zero);
      expect(a.received.length, 1);
      expect(b.received.length, 1);
    });

    test('a throwing sink does not break others', () async {
      final _CapturingSink ok = _CapturingSink();
      LlmMeter.init(MeterConfig(sinks: <MeterSink>[_ThrowingSink(), ok]));
      LlmMeter.instance.record(_evt(cost: 0.01));
      await Future<void>.delayed(Duration.zero);
      expect(ok.received.length, 1);
    });
  });

  group('LlmMeter.stats', () {
    test('reflects buffered events', () {
      LlmMeter.instance
        ..record(_evt(cost: 0.01, latencyMs: 100))
        ..record(_evt(cost: 0.02, latencyMs: 200))
        ..record(_evt(cost: 0.03, latencyMs: 300));
      final MeterStats s = LlmMeter.instance.stats();
      expect(s.eventCount, 3);
      expect(s.totalCostUsd, closeTo(0.06, 1e-9));
    });

    test('clear resets stats', () {
      LlmMeter.instance.record(_evt(cost: 0.01));
      LlmMeter.instance.clear();
      expect(LlmMeter.instance.stats().eventCount, 0);
    });
  });
}
