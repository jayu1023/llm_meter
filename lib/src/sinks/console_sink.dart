/// Simple stdout sink — handy in development.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/meter_event.dart';
import 'meter_sink.dart';

/// Prints every event with [debugPrint] (no-op in release unless
/// [printInRelease] is set).
class ConsoleSink extends MeterSink {
  /// Build a console sink.
  const ConsoleSink({this.printInRelease = false});

  /// When `true` the sink still prints in release builds.
  final bool printInRelease;

  @override
  Future<void> record(MeterEvent event) async {
    if (kReleaseMode && !printInRelease) return;
    debugPrint('[llm_meter] ${event.toString()}');
  }
}
