/// Top-level configuration for [LlmMeter].
library;

import 'package:flutter/foundation.dart';

import '../pricing/currency.dart';
import '../pricing/model_pricing.dart';
import '../sinks/meter_sink.dart';

/// One-line setup passed to [LlmMeter.init].
///
/// ```dart
/// LlmMeter.init(const MeterConfig(
///   sinks: <MeterSink>[ConsoleSink()],
///   displayCurrency: Currency.eur,
/// ));
/// ```
@immutable
class MeterConfig {
  /// Build a configuration. All fields have sensible defaults.
  const MeterConfig({
    this.bufferCapacity = 1000,
    this.sinks = const <MeterSink>[],
    this.pricingOverrides = const <String, ModelPricing>{},
    this.displayCurrency = Currency.usd,
    this.logPromptText = false,
    this.gdprMode = false,
  }) : assert(bufferCapacity > 0, 'bufferCapacity must be > 0');

  /// Default config — no sinks, USD display, prompt logging off.
  static const MeterConfig defaults = MeterConfig();

  /// Max events held in memory for the HUD / aggregation window.
  ///
  /// When the buffer fills up the oldest event is dropped. Stats are computed
  /// over the events currently in the buffer.
  final int bufferCapacity;

  /// Sinks that receive every recorded event. Failures in one sink do not
  /// affect the others.
  final List<MeterSink> sinks;

  /// Override or extend the built-in pricing table. Keys are model ids in any
  /// of the supported normalization forms.
  final Map<String, ModelPricing> pricingOverrides;

  /// Currency shown in the HUD (cost is always *recorded* in USD).
  final Currency displayCurrency;

  /// When `true` the meter is allowed to log full prompt + completion text to
  /// sinks. **Off by default** — keep off unless you fully trust every sink.
  final bool logPromptText;

  /// When `true` sinks should scrub user-ids, IPs, and any PII before
  /// transmitting. Defaults to `false`.
  ///
  /// Sinks decide *how* to scrub; see e.g. `gdprScrub` in `meter_sink.dart`.
  final bool gdprMode;

  /// Copy with overrides.
  MeterConfig copyWith({
    int? bufferCapacity,
    List<MeterSink>? sinks,
    Map<String, ModelPricing>? pricingOverrides,
    Currency? displayCurrency,
    bool? logPromptText,
    bool? gdprMode,
  }) => MeterConfig(
    bufferCapacity: bufferCapacity ?? this.bufferCapacity,
    sinks: sinks ?? this.sinks,
    pricingOverrides: pricingOverrides ?? this.pricingOverrides,
    displayCurrency: displayCurrency ?? this.displayCurrency,
    logPromptText: logPromptText ?? this.logPromptText,
    gdprMode: gdprMode ?? this.gdprMode,
  );
}
