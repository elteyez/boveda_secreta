import 'package:flutter_test/flutter_test.dart';

import 'package:boveda_segura/main.dart';

void main() {
  testWidgets('La bóveda empieza bloqueada', (WidgetTester tester) async {
    await tester.pumpWidget(const BovedaApp());
    expect(find.text('Bóveda segura'), findsOneWidget);
    expect(find.text('Desbloquear con huella'), findsOneWidget);
    expect(find.text('Contenido secreto'), findsNothing);
  });
}
