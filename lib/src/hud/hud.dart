/// Floating, draggable HUD that shows live cost / latency / cache stats.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../aggregation/rolling_stats.dart';
import '../core/meter.dart';
import '../core/meter_event.dart';
import '../pricing/currency.dart';

/// Corner anchor for the HUD card.
enum HudCorner {
  /// Top-left of the parent.
  topLeft,

  /// Top-right of the parent.
  topRight,

  /// Bottom-left of the parent.
  bottomLeft,

  /// Bottom-right of the parent.
  bottomRight,
}

/// Drop-in widget that overlays a small floating card showing the live cost,
/// latency, and cache stats reported by [LlmMeter].
///
/// ```dart
/// runApp(MaterialApp(
///   home: Stack(children: [
///     MyChatPage(),
///     const LlmMeterHud(),
///   ]),
/// ));
/// ```
///
/// In a release build the HUD silently renders nothing unless [forceShow] is
/// `true`. Tap once to expand into a per-event log; tap again to collapse.
/// Drag the card freely; it snaps to the nearest corner when released.
class LlmMeterHud extends StatefulWidget {
  /// Build the HUD widget.
  const LlmMeterHud({
    super.key,
    this.corner = HudCorner.bottomRight,
    this.padding = const EdgeInsets.all(12),
    this.forceShow = false,
    this.displayCurrency,
    this.maxEventsInLog = 20,
  });

  /// Initial corner the HUD snaps to before any user drag.
  final HudCorner corner;

  /// Padding from the screen edges.
  final EdgeInsets padding;

  /// Force the HUD to render in release builds. Off by default — leave off
  /// for production. Useful for staging builds with a debug overlay.
  final bool forceShow;

  /// Currency to display amounts in. Defaults to `LlmMeter.instance.config
  /// .displayCurrency`.
  final Currency? displayCurrency;

  /// Max number of recent events to show in the expanded log.
  final int maxEventsInLog;

  @override
  State<LlmMeterHud> createState() => _LlmMeterHudState();
}

class _LlmMeterHudState extends State<LlmMeterHud> {
  StreamSubscription<MeterEvent>? _sub;
  Offset? _userOffset;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _sub = LlmMeter.instance.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && !widget.forceShow) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const Size cardSize = Size(220, 124);
        final Size expandedSize = Size(
          260,
          140 + 18.0 * widget.maxEventsInLog.clamp(1, 8),
        );
        final Size effective = _expanded ? expandedSize : cardSize;
        final Offset anchor = _cornerOffset(
          widget.corner,
          parent: Size(constraints.maxWidth, constraints.maxHeight),
          card: effective,
          padding: widget.padding,
        );
        final Offset pos = _userOffset ?? anchor;

        return Stack(
          children: <Widget>[
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                onPanUpdate: (DragUpdateDetails d) {
                  setState(() {
                    final Offset next = (_userOffset ?? anchor) + d.delta;
                    _userOffset = Offset(
                      next.dx.clamp(
                        0,
                        constraints.maxWidth - effective.width,
                      ),
                      next.dy.clamp(
                        0,
                        constraints.maxHeight - effective.height,
                      ),
                    );
                  });
                },
                onPanEnd: (_) {
                  // Snap to nearest corner.
                  final Offset center = (_userOffset ?? anchor) +
                      Offset(effective.width / 2, effective.height / 2);
                  final HudCorner nearest = _nearestCorner(
                    center,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );
                  setState(() {
                    _userOffset = _cornerOffset(
                      nearest,
                      parent: Size(constraints.maxWidth, constraints.maxHeight),
                      card: effective,
                      padding: widget.padding,
                    );
                  });
                },
                child: _HudCard(
                  size: effective,
                  expanded: _expanded,
                  currency: widget.displayCurrency ??
                      LlmMeter.instance.config.displayCurrency,
                  maxEventsInLog: widget.maxEventsInLog,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _cornerOffset(
    HudCorner c, {
    required Size parent,
    required Size card,
    required EdgeInsets padding,
  }) {
    switch (c) {
      case HudCorner.topLeft:
        return Offset(padding.left, padding.top);
      case HudCorner.topRight:
        return Offset(parent.width - card.width - padding.right, padding.top);
      case HudCorner.bottomLeft:
        return Offset(
          padding.left,
          parent.height - card.height - padding.bottom,
        );
      case HudCorner.bottomRight:
        return Offset(
          parent.width - card.width - padding.right,
          parent.height - card.height - padding.bottom,
        );
    }
  }

  HudCorner _nearestCorner(Offset center, Size parent) {
    final bool left = center.dx < parent.width / 2;
    final bool top = center.dy < parent.height / 2;
    if (top && left) return HudCorner.topLeft;
    if (top && !left) return HudCorner.topRight;
    if (!top && left) return HudCorner.bottomLeft;
    return HudCorner.bottomRight;
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({
    required this.size,
    required this.expanded,
    required this.currency,
    required this.maxEventsInLog,
  });

  final Size size;
  final bool expanded;
  final Currency currency;
  final int maxEventsInLog;

  @override
  Widget build(BuildContext context) {
    final MeterStats stats = LlmMeter.instance.stats();
    return Material(
      color: Colors.transparent,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: Container(
          width: size.width,
          decoration: BoxDecoration(
            color: const Color(0xCC101418),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x66000000), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'monospace',
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            decoration: TextDecoration.none,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.bolt, color: Colors.tealAccent, size: 13),
                  const SizedBox(width: 4),
                  const Text(
                    'llm_meter',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${stats.eventCount} evt',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _HudRow(
                label: 'total',
                value: currency.format(stats.totalCostUsd),
                emphasis: true,
              ),
              _HudRow(
                label: 'last',
                value:
                    '${currency.format(stats.lastCostUsd)} · ${stats.lastLatencyMs}ms',
              ),
              _HudRow(
                label: 'p50/p99',
                value: '${stats.p50LatencyMs}/${stats.p99LatencyMs}ms',
              ),
              _HudRow(
                label: 'cache',
                value: '${(stats.cacheHitRatio * 100).toStringAsFixed(0)}%',
              ),
              if (expanded) ...<Widget>[
                const Divider(color: Color(0x33FFFFFF), height: 10),
                const Text(
                  'recent',
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 18.0 * maxEventsInLog.clamp(1, 8),
                  child: _RecentList(
                    events: LlmMeter.instance.events(),
                    currency: currency,
                    max: maxEventsInLog,
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _HudRow extends StatelessWidget {
  const _HudRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: emphasis ? Colors.tealAccent : Colors.white,
                fontWeight:
                    emphasis ? FontWeight.w600 : FontWeight.w400,
                fontSize: emphasis ? 12 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.events,
    required this.currency,
    required this.max,
  });

  final List<MeterEvent> events;
  final Currency currency;
  final int max;

  @override
  Widget build(BuildContext context) {
    final List<MeterEvent> recent = events.length <= max
        ? events.reversed.toList()
        : events.sublist(events.length - max).reversed.toList();
    return ListView.builder(
      itemCount: recent.length,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context, int i) {
        final MeterEvent e = recent[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  e.model,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency.format(e.costUsd),
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${e.latency.inMilliseconds}ms',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
