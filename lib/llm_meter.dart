/// llm_meter — Per-request token cost + latency + cache observability for any
/// Flutter LLM app. Drop-in wrapper, live HUD in dev, silent telemetry sink in
/// prod.
library;

export 'src/aggregation/rolling_stats.dart';
export 'src/core/meter.dart';
export 'src/core/meter_config.dart';
export 'src/core/meter_event.dart';
export 'src/hud/hud.dart';
export 'src/pricing/currency.dart';
export 'src/pricing/model_pricing.dart';
export 'src/pricing/pricing_table.dart';
export 'src/sinks/batching_sink.dart';
export 'src/sinks/console_sink.dart';
export 'src/sinks/meter_sink.dart';
export 'src/sinks/posthog_sink.dart';
export 'src/sinks/retrying_sink.dart';
export 'src/wrappers/metered_call.dart';
export 'src/wrappers/metered_stream.dart';
export 'src/wrappers/recipes.dart';
