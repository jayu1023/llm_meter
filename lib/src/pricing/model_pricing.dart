/// Per-model token pricing record.
library;

import 'package:flutter/foundation.dart';

/// Per-token price for a single model variant, expressed in USD per token.
///
/// Provider price sheets are usually quoted *per 1M tokens*. The factory
/// [ModelPricing.perMillion] converts that to the per-token unit this package
/// uses internally.
@immutable
class ModelPricing {
  /// Build pricing where rates are already in USD-per-token.
  const ModelPricing({
    required this.inputRate,
    required this.outputRate,
    this.cachedInputRate,
  });

  /// Build pricing from provider-style "USD per 1M tokens" numbers.
  ///
  /// ```dart
  /// // Anthropic Claude 4.7 Sonnet: $3 / 1M input, $15 / 1M output,
  /// // cache reads $0.30 / 1M.
  /// const ModelPricing.perMillion(
  ///   inputPerMillion: 3.0,
  ///   outputPerMillion: 15.0,
  ///   cachedInputPerMillion: 0.30,
  /// );
  /// ```
  const ModelPricing.perMillion({
    required double inputPerMillion,
    required double outputPerMillion,
    double? cachedInputPerMillion,
  }) : inputRate = inputPerMillion / 1000000,
       outputRate = outputPerMillion / 1000000,
       cachedInputRate = cachedInputPerMillion == null
           ? null
           : cachedInputPerMillion / 1000000;

  /// Free-tier pricing (everything is $0).
  static const ModelPricing free = ModelPricing(
    inputRate: 0,
    outputRate: 0,
    cachedInputRate: 0,
  );

  /// USD per input token (non-cached).
  final double inputRate;

  /// USD per output token.
  final double outputRate;

  /// USD per cached input token. `null` ⇒ no separate cache rate (falls back
  /// to [inputRate]).
  final double? cachedInputRate;

  /// Calculate the total billed cost for a single call.
  double cost({
    required int tokensIn,
    required int tokensOut,
    int cachedTokensIn = 0,
  }) {
    final double cacheRate = cachedInputRate ?? inputRate;
    return tokensIn * inputRate +
        tokensOut * outputRate +
        cachedTokensIn * cacheRate;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelPricing &&
        other.inputRate == inputRate &&
        other.outputRate == outputRate &&
        other.cachedInputRate == cachedInputRate;
  }

  @override
  int get hashCode => Object.hash(inputRate, outputRate, cachedInputRate);

  @override
  String toString() =>
      'ModelPricing(in=\$${(inputRate * 1000000).toStringAsFixed(2)}/1M, '
      'out=\$${(outputRate * 1000000).toStringAsFixed(2)}/1M, '
      'cache=${cachedInputRate == null ? "n/a" : "\$${(cachedInputRate! * 1000000).toStringAsFixed(2)}/1M"})';
}
