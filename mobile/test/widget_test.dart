import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Chat screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Sleep Chat'), findsOneWidget);
    expect(find.text('Type your message...'), findsOneWidget);
  });
}
