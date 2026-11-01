// Testa a tela Rede de contatos lendo o ContactsController.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/contacts/pages/contacts_page.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';

void main() {
  late ContactsController controller;

  setUp(() => controller = ContactsController());
  tearDown(() => controller.dispose());

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(theme: AppTheme.light, home: const ContactsPage()),
    ),
  );

  testWidgets('Sem contatos: 0/5 e cinco espaços para adicionar', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Rede de contatos'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('Adicionar contato'), findsNWidgets(5));
  });

  testWidgets('Mostra os contatos do controlador, com telefone formatado', (
    tester,
  ) async {
    controller.add(name: 'Gabriela Flores', phone: '51999990001');
    controller.add(name: 'Yasmin Chervenski', phone: '51999990002');
    controller.add(name: 'Milena Alves', phone: '5133330003');
    await pumpPage(tester);

    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Gabriela Flores'), findsOneWidget);
    expect(find.text('(51) 99999-0001'), findsOneWidget);
    expect(find.text('(51) 3333-0003'), findsOneWidget); // fixo, 10 dígitos
    // Iniciais calculadas a partir do nome.
    expect(find.text('YC'), findsOneWidget);
    expect(find.text('Adicionar contato'), findsNWidgets(2));
  });

  testWidgets('A tela se atualiza quando um contato entra no controlador', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Maria Silva'), findsNothing);

    controller.add(name: 'Maria Silva', phone: '51999990001');
    await tester.pump();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Adicionar contato'), findsNWidgets(4));
  });
}
