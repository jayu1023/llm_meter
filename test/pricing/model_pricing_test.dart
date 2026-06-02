import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  group('ModelPricing.perMillion', () {
    test('converts per-million to per-token correctly', () {
      const ModelPricing p = ModelPricing.perMillion(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
        cachedInputPerMillion: 0.30,
      );
      expect(p.inputRate, closeTo(3.0e-6, 1e-15));
      expect(p.outputRate, closeTo(15.0e-6, 1e-15));
      expect(p.cachedInputRate, closeTo(0.30e-6, 1e-15));
    });

    test('cachedInputRate is nullable when omitted', () {
      const ModelPricing p = ModelPricing.perMillion(
        inputPerMillion: 1.0,
        outputPerMillion: 2.0,
      );
      expect(p.cachedInputRate, isNull);
    });

    test('free pricing is all zero', () {
      expect(ModelPricing.free.inputRate, 0);
      expect(ModelPricing.free.outputRate, 0);
      expect(ModelPricing.free.cachedInputRate, 0);
    });
  });

  group('ModelPricing.cost', () {
    const ModelPricing sonnet = ModelPricing.perMillion(
      inputPerMillion: 3.0,
      outputPerMillion: 15.0,
      cachedInputPerMillion: 0.30,
    );

    test('mixed call with cache', () {
      final double c = sonnet.cost(
        tokensIn: 1000,
        tokensOut: 500,
        cachedTokensIn: 2000,
      );
      // 1000*3e-6 + 500*15e-6 + 2000*0.3e-6
      // = 0.003 + 0.0075 + 0.0006 = 0.0111
      expect(c, closeTo(0.0111, 1e-9));
    });

    test('cache rate defaults to inputRate when null', () {
      const ModelPricing p = ModelPricing.perMillion(
        inputPerMillion: 1.0,
        outputPerMillion: 1.0,
      );
      expect(
        p.cost(tokensIn: 0, tokensOut: 0, cachedTokensIn: 1000),
        closeTo(0.001, 1e-12),
      );
    });

    test('large-scale call (1M each) stays numerically stable', () {
      final double c =
          sonnet.cost(tokensIn: 1000000, tokensOut: 1000000, cachedTokensIn: 1000000);
      // 3 + 15 + 0.30 = 18.30
      expect(c, closeTo(18.30, 1e-9));
    });
  });

  group('ModelPricing equality + hashing', () {
    test('two perMillion(3,15,0.3) instances are equal', () {
      const ModelPricing a = ModelPricing.perMillion(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
        cachedInputPerMillion: 0.30,
      );
      const ModelPricing b = ModelPricing.perMillion(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
        cachedInputPerMillion: 0.30,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different rates => not equal', () {
      const ModelPricing a = ModelPricing.perMillion(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
      );
      const ModelPricing b = ModelPricing.perMillion(
        inputPerMillion: 4.0,
        outputPerMillion: 15.0,
      );
      expect(a, isNot(b));
    });
  });

  group('ModelPricing.toString', () {
    test('prints per-million values', () {
      const ModelPricing p = ModelPricing.perMillion(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
        cachedInputPerMillion: 0.30,
      );
      final String s = p.toString();
      expect(s, contains(r'$3.00/1M'));
      expect(s, contains(r'$15.00/1M'));
      expect(s, contains(r'$0.30/1M'));
    });
  });
}
