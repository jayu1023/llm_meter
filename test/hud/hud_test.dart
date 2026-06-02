import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

MeterEvent _evt({String model = 'gpt-5', double cost = 0.01, int ms = 100}) =>
    MeterEvent(
      provider: 'openai',
      model: model,
      tokensIn: 100,
      tokensOut: 50,
      costUsd: cost,
      latency: Duration(milliseconds: ms),
      timestamp: DateTime.utc(2026, 6, 1),
    );

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 400,
      height: 800,
      child: Stack(children: <Widget>[child]),
    ),
  ),
);

void main() {
  setUp(() {
    LlmMeter.init(MeterConfig.defaults);
    LlmMeter.instance.clear();
  });

  testWidgets('renders header + total row', (WidgetTester tester) async {
    LlmMeter.instance.record(_evt(cost: 0.05));
    await tester.pumpWidget(_wrap(const LlmMeterHud()));
    await tester.pump();
    expect(find.text('llm_meter'), findsOneWidget);
    expect(find.textContaining(r'$0.0500'), findsAtLeastNWidgets(1));
  });

  testWidgets('updates when a new event is recorded',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LlmMeterHud()));
    await tester.pump();
    expect(find.textContaining(r'$0.0000'), findsAtLeastNWidgets(1));

    LlmMeter.instance.record(_evt(cost: 0.10));
    await tester.pump(); // flush stream listener
    await tester.pump(); // flush setState

    expect(find.textContaining(r'$0.1000'), findsAtLeastNWidgets(1));
  });

  testWidgets('tap expands to show recent events',
      (WidgetTester tester) async {
    LlmMeter.instance.record(_evt(model: 'gpt-5', cost: 0.01));
    LlmMeter.instance.record(_evt(model: 'claude-sonnet-4-6', cost: 0.02));
    await tester.pumpWidget(_wrap(const LlmMeterHud()));
    await tester.pump();
    expect(find.text('recent'), findsNothing);

    await tester.tap(find.text('llm_meter'));
    await tester.pumpAndSettle();
    expect(find.text('recent'), findsOneWidget);
    expect(find.text('gpt-5'), findsOneWidget);
    expect(find.text('claude-sonnet-4-6'), findsOneWidget);
  });

  testWidgets('drag updates position', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LlmMeterHud()));
    await tester.pump();
    final Offset before = tester.getTopLeft(find.text('llm_meter'));
    await tester.drag(find.text('llm_meter'), const Offset(-100, -100));
    await tester.pumpAndSettle();
    final Offset after = tester.getTopLeft(find.text('llm_meter'));
    expect(after, isNot(before));
  });
}
