import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soutify/app.dart';

void main() {
  testWidgets('Soutify app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SoutifyApp());
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsWidgets);
  });
}
