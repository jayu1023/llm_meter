import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  group('Currency.format — built-ins', () {
    test('USD prefixes \$ with 4 decimals', () {
      expect(Currency.usd.format(1.2345), r'$1.2345');
    });

    test('EUR prefixes € and converts at the snapshot rate', () {
      expect(Currency.eur.format(1.0), '€0.9200');
    });

    test('GBP prefixes £', () {
      expect(Currency.gbp.format(1.0), '£0.7800');
    });

    test('INR prefixes ₹', () {
      expect(Currency.inr.format(1.0), '₹83.0000');
    });

    test('SEK suffixes kr', () {
      expect(Currency.sek.format(1.0), '10.5000 kr');
    });

    test('CHF prefixes the code', () {
      expect(Currency.chf.format(1.0), 'CHF0.8800');
    });

    test('zero formats cleanly', () {
      expect(Currency.usd.format(0), r'$0.0000');
    });
  });

  group('Currency custom', () {
    test('custom decimals respected', () {
      const Currency c = Currency(
        code: 'USD',
        symbol: r'$',
        usdRate: 1.0,
        decimals: 2,
      );
      expect(c.format(1.2345), r'$1.23');
    });

    test('custom suffix currency', () {
      const Currency c = Currency(
        code: 'AAA',
        symbol: 'A',
        usdRate: 2.0,
        symbolPosition: SymbolPosition.suffix,
        decimals: 1,
      );
      expect(c.format(0.5), '1.0 A');
    });
  });

  group('Currency equality', () {
    test('identical const instances are equal', () {
      expect(Currency.usd, Currency.usd);
    });

    test('different rates are not equal', () {
      const Currency a = Currency(code: 'X', symbol: 'x', usdRate: 1.0);
      const Currency b = Currency(code: 'X', symbol: 'x', usdRate: 2.0);
      expect(a, isNot(b));
    });
  });
}
