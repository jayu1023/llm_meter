import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/src/aggregation/rolling_stats.dart';

void main() {
  group('RingBuffer', () {
    test('starts empty', () {
      final RingBuffer<int> b = RingBuffer<int>(4);
      expect(b.length, 0);
      expect(b.isEmpty, isTrue);
      expect(b.isNotEmpty, isFalse);
      expect(b.toList(), <int>[]);
    });

    test('grows up to capacity', () {
      final RingBuffer<int> b = RingBuffer<int>(3)
        ..add(1)
        ..add(2);
      expect(b.length, 2);
      expect(b.toList(), <int>[1, 2]);
    });

    test('drops oldest when over capacity', () {
      final RingBuffer<int> b = RingBuffer<int>(3)
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4)
        ..add(5);
      expect(b.length, 3);
      expect(b.toList(), <int>[3, 4, 5]);
    });

    test('handles many wraparounds correctly', () {
      final RingBuffer<int> b = RingBuffer<int>(5);
      for (int i = 0; i < 1000; i++) {
        b.add(i);
      }
      expect(b.length, 5);
      expect(b.toList(), <int>[995, 996, 997, 998, 999]);
    });

    test('clear resets state', () {
      final RingBuffer<int> b = RingBuffer<int>(3)
        ..add(1)
        ..add(2)
        ..clear();
      expect(b.length, 0);
      expect(b.toList(), <int>[]);
      b.add(99);
      expect(b.toList(), <int>[99]);
    });

    test('toList returns an unmodifiable view', () {
      final RingBuffer<int> b = RingBuffer<int>(2)..add(1);
      expect(() => b.toList().add(2), throwsUnsupportedError);
    });

    test('asserts capacity > 0', () {
      expect(() => RingBuffer<int>(0), throwsA(isA<AssertionError>()));
    });
  });
}
