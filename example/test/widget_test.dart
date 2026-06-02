import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const LlmMeterDemoApp());
    expect(find.text('llm_meter demo'), findsOneWidget);
    expect(find.text('Send one'), findsOneWidget);
  });
}
