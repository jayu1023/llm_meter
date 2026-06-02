import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 6, 1, 12, 0);

  MeterEvent base() => MeterEvent(
    provider: 'openai',
    model: 'gpt-5',
    tokensIn: 1000,
    tokensOut: 500,
    costUsd: 0.0075,
    latency: const Duration(milliseconds: 420),
    timestamp: t0,
  );

  group('MeterEvent', () {
    test('totalTokens sums in/out/cached', () {
      final MeterEvent e = base().copyWith(cachedTokensIn: 200);
      expect(e.totalTokens, 1700);
    });

    test('cacheHitRatio is cached / (in + cached)', () {
      final MeterEvent e = base().copyWith(tokensIn: 800, cachedTokensIn: 200);
      expect(e.cacheHitRatio, 0.2);
    });

    test('cacheHitRatio is 0 when no input tokens at all', () {
      final MeterEvent e = base().copyWith(tokensIn: 0, cachedTokensIn: 0);
      expect(e.cacheHitRatio, 0);
    });

    test('copyWith preserves untouched fields', () {
      final MeterEvent e = base().copyWith(costUsd: 1.0);
      expect(e.provider, 'openai');
      expect(e.model, 'gpt-5');
      expect(e.tokensIn, 1000);
      expect(e.costUsd, 1.0);
    });

    test('toJson is JSON-safe (only primitives + maps + lists)', () {
      final Map<String, Object?> json = base()
          .copyWith(
            conversationId: 'c1',
            requestId: 'r1',
            streaming: true,
            metadata: const <String, Object?>{'tag': 'demo'},
          )
          .toJson();
      expect(json['provider'], 'openai');
      expect(json['model'], 'gpt-5');
      expect(json['tokens_in'], 1000);
      expect(json['tokens_out'], 500);
      expect(json['cost_usd'], 0.0075);
      expect(json['latency_ms'], 420);
      expect(json['timestamp'], '2026-06-01T12:00:00.000Z');
      expect(json['conversation_id'], 'c1');
      expect(json['request_id'], 'r1');
      expect(json['streaming'], true);
      expect(json['metadata'], const <String, Object?>{'tag': 'demo'});
    });

    test('toJson omits null optional fields', () {
      final Map<String, Object?> json = base().toJson();
      expect(json.containsKey('conversation_id'), isFalse);
      expect(json.containsKey('request_id'), isFalse);
      expect(json.containsKey('error'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('equality holds across identical fields', () {
      expect(base(), base());
      expect(base().hashCode, base().hashCode);
    });

    test('inequality on changed field', () {
      expect(base(), isNot(base().copyWith(tokensIn: 999)));
    });
  });
}
