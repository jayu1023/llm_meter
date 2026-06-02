/// Lightweight currency formatter for HUD display.
///
/// Intentionally avoids `package:intl` — keeps the runtime dep surface zero so
/// `llm_meter` can be added to any Flutter app without dragging in
/// `package:intl` transitively (which can balloon AOT size in small apps).
library;

import 'package:flutter/foundation.dart';

/// Currency that costs can be displayed in. USD is the canonical unit costs
/// are recorded in; everything else is converted at display time.
@immutable
class Currency {
  /// Build a currency definition.
  const Currency({
    required this.code,
    required this.symbol,
    required this.usdRate,
    this.decimals = 4,
    this.symbolPosition = SymbolPosition.prefix,
  });

  /// US dollar — the canonical unit costs are stored in.
  static const Currency usd = Currency(code: 'USD', symbol: r'$', usdRate: 1.0);

  /// Euro — rate is a sensible default snapshot; override for accuracy.
  static const Currency eur = Currency(code: 'EUR', symbol: '€', usdRate: 0.92);

  /// British pound.
  static const Currency gbp = Currency(code: 'GBP', symbol: '£', usdRate: 0.78);

  /// Indian rupee.
  static const Currency inr = Currency(code: 'INR', symbol: '₹', usdRate: 83.0);

  /// Swedish krona.
  static const Currency sek = Currency(
    code: 'SEK',
    symbol: 'kr',
    usdRate: 10.5,
    symbolPosition: SymbolPosition.suffix,
  );

  /// Swiss franc.
  static const Currency chf = Currency(
    code: 'CHF',
    symbol: 'CHF',
    usdRate: 0.88,
  );

  /// ISO 4217 code, e.g. `USD`.
  final String code;

  /// Glyph or short code displayed alongside the amount, e.g. `$` or `kr`.
  final String symbol;

  /// Multiplier `1 USD = usdRate <currency>`.
  final double usdRate;

  /// Number of fractional digits shown in [format].
  final int decimals;

  /// Whether the [symbol] goes before or after the amount.
  final SymbolPosition symbolPosition;

  /// Format a USD amount in this currency.
  String format(double usd) {
    final double value = usd * usdRate;
    final String s = value.toStringAsFixed(decimals);
    return symbolPosition == SymbolPosition.prefix ? '$symbol$s' : '$s $symbol';
  }

  @override
  bool operator ==(Object other) =>
      other is Currency &&
      other.code == code &&
      other.symbol == symbol &&
      other.usdRate == usdRate &&
      other.decimals == decimals &&
      other.symbolPosition == symbolPosition;

  @override
  int get hashCode =>
      Object.hash(code, symbol, usdRate, decimals, symbolPosition);
}

/// Whether the currency symbol prints before or after the number.
enum SymbolPosition {
  /// `$1.23`.
  prefix,

  /// `1.23 kr`.
  suffix,
}
