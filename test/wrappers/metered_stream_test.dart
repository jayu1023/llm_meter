import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

class _Chunk {
  const _Chunk(this.text, {this.tokensIn = 0, this.tokensOut = 0});
  final String text;
  final int tokensIn;
  final int tokensOut;
}

void main() {
  setUp(() {
    LlmMeter.init(MeterConfig.defaults);
    LlmMeter.instance.clear();
  });

  group('MeteredStream.wrap', () {
    test('records one streaming event after the source completes', () async {
      final Stream<_Chunk> source = Stream<_Chunk>.fromIterable(<_Chunk>[
        const _Chunk('hello'),
        const _Chunk(' '),
        const _Chunk('world', tokensIn: 100, tokensOut: 50),
      ]);
      final Stream<_Chunk> wrapped = MeteredStream.wrap<_Chunk>(
        provider: 'openai',
        model: 'gpt-5',
        stream: source,
        extractChunk: (_Chunk c) => c.tokensOut == 0 && c.tokensIn == 0
            ? null
            : MeterUsage(tokensIn: c.tokensIn, tokensOut: c.tokensOut),
      );
      final List<String> seen = <String>[];
      await for (final _Chunk c in wrapped) {
        seen.add(c.text);
      }
      expect(seen, <String>['hello', ' ', 'world']);
      expect(LlmMeter.instance.events().length, 1);
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.streaming, isTrue);
      expect(e.tokensIn, 100);
      expect(e.tokensOut, 50);
      expect(e.costUsd, greaterThan(0));
    });

    test('handles per-chunk deltas (max wins)', () async {
      final Stream<_Chunk> source = Stream<_Chunk>.fromIterable(<_Chunk>[
        const _Chunk('a', tokensIn: 50, tokensOut: 10),
        const _Chunk('b', tokensIn: 50, tokensOut: 20),
        const _Chunk('c', tokensIn: 50, tokensOut: 30),
      ]);
      final Stream<_Chunk> wrapped = MeteredStream.wrap<_Chunk>(
        provider: 'openai',
        model: 'gpt-5',
        stream: source,
        extractChunk: (_Chunk c) =>
            MeterUsage(tokensIn: c.tokensIn, tokensOut: c.tokensOut),
      );
      await wrapped.drain<void>();
      // tokensIn stays at 50 (same across chunks), tokensOut climbs to 30
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.tokensIn, 50);
      expect(e.tokensOut, 30);
    });

    test('errors propagate AND get recorded with the error message', () async {
      final Stream<_Chunk> source = Stream<_Chunk>.multi((
        MultiStreamController<_Chunk> ctl,
      ) {
        ctl.add(const _Chunk('ok'));
        ctl.addError(StateError('mid-stream'));
      });
      final Stream<_Chunk> wrapped = MeteredStream.wrap<_Chunk>(
        provider: 'openai',
        model: 'gpt-5',
        stream: source,
        extractChunk: (_Chunk c) => null,
      );
      expect(() async {
        await for (final _ in wrapped) {
          // consume
        }
      }, throwsStateError);
      // Give recorder a tick.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.streaming, isTrue);
      expect(e.error, contains('mid-stream'));
    });

    test('cancellation mid-stream still records what we have', () async {
      final Completer<void> gate = Completer<void>();
      final Stream<_Chunk> source = Stream<_Chunk>.multi((
        MultiStreamController<_Chunk> ctl,
      ) {
        ctl.add(const _Chunk('one', tokensIn: 100, tokensOut: 100));
        // Park here until the consumer cancels.
        ctl.onCancel = gate.complete;
      });
      final Stream<_Chunk> wrapped = MeteredStream.wrap<_Chunk>(
        provider: 'openai',
        model: 'gpt-5',
        stream: source,
        extractChunk: (_Chunk c) =>
            MeterUsage(tokensIn: c.tokensIn, tokensOut: c.tokensOut),
      );
      final StreamSubscription<_Chunk> sub = wrapped.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      await gate.future;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(LlmMeter.instance.events().length, 1);
      final MeterEvent e = LlmMeter.instance.events().first;
      expect(e.error, 'cancelled');
      expect(e.tokensIn, 100);
    });
  });
}
