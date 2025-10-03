import 'package:flutter_test/flutter_test.dart';

import 'package:quoridor_game/main.dart';

void main() {
  testWidgets('Tela inicial do Quoridor é carregada', (tester) async {
    await tester.pumpWidget(const QuoridorApp());

    expect(find.text('Quoridor'), findsWidgets);
    expect(find.text('Iniciar partida'), findsOneWidget);
  });
}
