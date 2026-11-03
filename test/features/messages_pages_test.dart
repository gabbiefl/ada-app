// Testa as telas Mensagens e Mensagens - Editar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/messages/pages/message_edit_page.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/pages/messages_page.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void main() {
  testWidgets('Mensagens mostra as três mensagens', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MessagesController(),
        child: _app(const MessagesPage()),
      ),
    );

    expect(find.text('Modo perigo'), findsOneWidget);
    expect(find.text('Modo atenção'), findsOneWidget);
    expect(find.text('Cheguei bem'), findsOneWidget);
    expect(find.text('Editar'), findsNWidgets(3));
  });

  testWidgets('Mensagens mostra o texto editado do controlador', (
    tester,
  ) async {
    final controller = MessagesController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: _app(const MessagesPage()),
      ),
    );

    controller.save(MessageKind.arrived, 'Cheguei! Beijos.');
    await tester.pump();

    expect(find.text('Cheguei! Beijos.'), findsOneWidget);
    expect(find.text(MessageKind.arrived.defaultText), findsNothing);
  });

  testWidgets('Editar: o contador acompanha o texto e o reset restaura', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const MessageEditPage()));
    expect(find.text('90/200'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Oi');
    await tester.pump();
    expect(find.text('2/200'), findsOneWidget);

    await tester.tap(find.text('Resetar para padrão'));
    await tester.pump();
    expect(find.text('90/200'), findsOneWidget);
  });
}
