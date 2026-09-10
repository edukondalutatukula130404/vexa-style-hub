import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('VexaMobileApp builds initial Splash screen cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const VexaMobileApp());

    // Verify VEXA app title text exists on splash screen
    expect(find.text('VEXA'), findsOneWidget);
    expect(find.text('STYLE HUB'), findsOneWidget);
  });
}
