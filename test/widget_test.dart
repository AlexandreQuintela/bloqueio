import 'package:flutter_test/flutter_test.dart';

import 'package:quoridor_game/main.dart';

void main() {
  testWidgets('Tela inicial do Quoridor é carregada', (tester) async {
    await tester.pumpWidget(const QuoridorApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Quoridor'), findsWidgets);
    expect(find.text('Iniciar partida'), findsOneWidget);
  });
}
