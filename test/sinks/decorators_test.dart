import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

class _RecordingSink extends MeterSink {
  _RecordingSink();
  final List<MeterEvent> records = <MeterEvent>[];
  int flushCount = 0;
  int closeCount = 0;
  bool failNext = false;
  int failCount = 0;

  @override
  Future<void> record(MeterEvent event) async {
    if (failNext || failCount > 0) {
      if (failCount > 0) failCount -= 1;
      failNext = false;
      throw StateError('boom');
    }
    records.add(event);
  }

  @override
  Future<void> flush() async => flushCount += 1;

  @override
  Future<void> close() async => closeCount += 1;
}

MeterEvent _evt({double cost = 0.01}) => MeterEvent(
  provider: 'p',
  model: 'm',
  tokensIn: 1,
  tokensOut: 1,
  costUsd: cost,
  latency: const Duration(milliseconds: 10),
  timestamp: DateTime.utc(2026, 6, 1),
);

void main() {
  group('BatchingSink', () {
    test('flushes when maxBatchSize is reached', () async {
      final _RecordingSink inner = _RecordingSink();
      final BatchingSink b = BatchingSink(inner: inner, maxBatchSize: 3);
      await b.record(_evt());
      await b.record(_evt());
      expect(inner.records.length, 0);
      await b.record(_evt()); // triggers flush
      expect(inner.records.length, 3);
      expect(inner.flushCount, 1);
    });

    test('flushes after flushInterval', () async {
      final _RecordingSink inner = _RecordingSink();
      final BatchingSink b = BatchingSink(
        inner: inner,
        maxBatchSize: 100,
        flushInterval: const Duration(milliseconds: 50),
      );
      await b.record(_evt());
      await b.record(_evt());
      expect(inner.records.length, 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(inner.records.length, 2);
    });

    test('manual flush drains immediately', () async {
      final _RecordingSink inner = _RecordingSink();
      final BatchingSink b = BatchingSink(inner: inner, maxBatchSize: 100);
      await b.record(_evt());
      await b.flush();
      expect(inner.records.length, 1);
    });

    test('close flushes and closes inner', () async {
      final _RecordingSink inner = _RecordingSink();
      final BatchingSink b = BatchingSink(inner: inner, maxBatchSize: 100);
      await b.record(_evt());
      await b.close();
      expect(inner.records.length, 1);
      expect(inner.closeCount, 1);
    });

    test('failing inner does not throw out of batching', () async {
      final _RecordingSink inner = _RecordingSink()..failCount = 1;
      final BatchingSink b = BatchingSink(inner: inner, maxBatchSize: 2);
      await b.record(_evt());
      await b.record(_evt()); // triggers flush; first inner.record throws
      expect(inner.records.length, 1);
    });
  });

  group('RetryingSink', () {
    test('first attempt succeeds → delivers, queue empty', () async {
      final _RecordingSink inner = _RecordingSink();
      final RetryingSink r = RetryingSink(inner: inner, maxAttempts: 3);
      await r.record(_evt());
      expect(inner.records.length, 1);
      expect(r.offlineQueue, isEmpty);
    });

    test('retries on failure then succeeds', () async {
      final _RecordingSink inner = _RecordingSink()..failCount = 2;
      final RetryingSink r = RetryingSink(
        inner: inner,
        maxAttempts: 5,
        baseDelay: const Duration(milliseconds: 1),
      );
      await r.record(_evt());
      expect(inner.records.length, 1);
      expect(r.offlineQueue, isEmpty);
    });

    test('parks event in offline queue after maxAttempts', () async {
      final _RecordingSink inner = _RecordingSink()..failCount = 100;
      final RetryingSink r = RetryingSink(
        inner: inner,
        maxAttempts: 2,
        baseDelay: const Duration(milliseconds: 1),
      );
      await r.record(_evt());
      expect(inner.records.length, 0);
      expect(r.offlineQueue.length, 1);
    });

    test('drainOfflineQueue retries parked events', () async {
      final _RecordingSink inner = _RecordingSink()..failCount = 100;
      final RetryingSink r = RetryingSink(
        inner: inner,
        maxAttempts: 1,
        baseDelay: const Duration(milliseconds: 1),
      );
      await r.record(_evt());
      expect(r.offlineQueue.length, 1);
      inner.failCount = 0;
      await r.drainOfflineQueue();
      expect(r.offlineQueue, isEmpty);
      expect(inner.records.length, 1);
    });

    test('offline queue drops oldest when full', () async {
      final _RecordingSink inner = _RecordingSink()..failCount = 100;
      final RetryingSink r = RetryingSink(
        inner: inner,
        maxAttempts: 1,
        baseDelay: const Duration(milliseconds: 1),
        offlineQueueLimit: 2,
      );
      await r.record(_evt(cost: 0.01));
      await r.record(_evt(cost: 0.02));
      await r.record(_evt(cost: 0.03));
      expect(r.offlineQueue.length, 2);
      expect(r.offlineQueue.first.costUsd, 0.02);
      expect(r.offlineQueue.last.costUsd, 0.03);
    });
  });

  group('gdprScrub', () {
    test('drops conversation_id, request_id and user_* metadata', () {
      final MeterEvent e = MeterEvent(
        provider: 'p',
        model: 'm',
        tokensIn: 1,
        tokensOut: 1,
        costUsd: 0.01,
        latency: Duration.zero,
        timestamp: DateTime.utc(2026, 6, 1),
        conversationId: 'c1',
        requestId: 'r1',
        metadata: const <String, Object?>{
          'user_id': '42',
          'email': 'x@y',
          'feature': 'rephrase',
        },
      );
      final MeterEvent safe = gdprScrub(e);
      expect(safe.conversationId, isNull);
      expect(safe.requestId, isNull);
      expect(safe.metadata.containsKey('user_id'), isFalse);
      expect(safe.metadata.containsKey('email'), isFalse);
      expect(safe.metadata['feature'], 'rephrase');
    });
  });
}
