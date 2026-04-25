import 'package:flutter_test/flutter_test.dart';

import 'package:soutify/app.dart';

void main() {
  testWidgets('Soutify app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoutifyApp());
    expect(find.text('Soutify'), findsOneWidget);
  });
}
