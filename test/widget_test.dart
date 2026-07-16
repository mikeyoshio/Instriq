import 'package:flutter_test/flutter_test.dart';

import 'package:instrumental_qx/main.dart';

void main() {
  testWidgets('Home screen shows main menu', (WidgetTester tester) async {
    await tester.pumpWidget(const InstrumentalApp());

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Mi progreso'), findsOneWidget);
  });
}
