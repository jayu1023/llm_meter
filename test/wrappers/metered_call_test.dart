import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

class _FakeResponse {
  const _FakeResponse(this.promptTokens, this.completionTokens);
  final int promptTokens;
  final int completionTokens;
}

void main() {
  setUp(() {
    LlmMeter.init(MeterConfig.defaults);
    LlmMeter.instance.clear();
  });

  group('MeteredCall.run — happy path', () {
    test('records an event with extracted usage', () async {
      final _FakeResponse r = await MeteredCall.run<_FakeResponse>(
        provider: 'openai',
        model: 'gpt-5',
        call: () async => const _FakeResponse(1000, 2000),
        extract: (_FakeResponse r) => MeterUsage(
          tokensIn: r.promptTokens,
          tokensOut: r.completionTokens,
        ),
      );
      expect(r.promptTokens, 1000);
      expect(LlmMeter.instance.events().length, 1);
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.provider, 'openai');
      expect(e.model, 'gpt-5');
      expect(e.tokensIn, 1000);
      expect(e.tokensOut, 2000);
      // Auto-priced: 1000 * 1.25e-6 + 2000 * 10e-6 = 0.02125
      expect(e.costUsd, closeTo(0.02125, 1e-9));
      expect(e.streaming, isFalse);
      expect(e.error, isNull);
    });

    test('latency is non-zero', () async {
      await MeteredCall.run<int>(
        provider: 'anthropic',
        model: 'claude-sonnet-4-6',
        call: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 42;
        },
        extract: (_) => const MeterUsage(tokensIn: 100, tokensOut: 50),
      );
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.latency.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('forwards metadata + ids', () async {
      await MeteredCall.run<int>(
        provider: 'openai',
        model: 'gpt-5',
        call: () async => 1,
        extract: (_) => const MeterUsage(tokensIn: 10, tokensOut: 5),
        conversationId: 'chat-42',
        requestId: 'req-7',
        metadata: const <String, Object?>{'feature': 'rephrase'},
      );
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.conversationId, 'chat-42');
      expect(e.requestId, 'req-7');
      expect(e.metadata['feature'], 'rephrase');
    });
  });

  group('MeteredCall.run — errors', () {
    test('records zero-cost event with error and rethrows', () async {
      expect(
        () => MeteredCall.run<int>(
          provider: 'openai',
          model: 'gpt-5',
          call: () async => throw StateError('rate-limited'),
          extract: (_) => MeterUsage.empty,
        ),
        throwsStateError,
      );
      // Give the recorded event a tick to land.
      await Future<void>.delayed(Duration.zero);
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.costUsd, 0);
      expect(e.error, contains('rate-limited'));
      expect(e.tokensIn, 0);
    });
  });
}
