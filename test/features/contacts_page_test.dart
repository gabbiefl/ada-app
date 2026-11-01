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

  testWidgets('Remover: pede confirmação e Cancelar mantém o contato', (
    tester,
  ) async {
    controller.add(name: 'Maria Silva', phone: '51999990001');
    await pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Remover Maria Silva'));
    await tester.pumpAndSettle();
    expect(find.text('Remover contato?'), findsOneWidget);
    expect(
      find.textContaining('Remover Maria Silva da sua rede'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Remover contato?'), findsNothing);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(controller.count, 1);
  });

  testWidgets('Remover: confirmar tira o contato da rede', (tester) async {
    controller.add(name: 'Maria Silva', phone: '51999990001');
    await pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Remover Maria Silva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsNothing);
    expect(find.text('0/5'), findsOneWidget);
    expect(controller.contacts, isEmpty);
  });

  testWidgets('Rede cheia: some o "Adicionar contato" e aparece o aviso', (
    tester,
  ) async {
    for (var i = 1; i <= 5; i++) {
      controller.add(name: 'Contato $i', phone: '5199999000$i');
    }
    await pumpPage(tester);
    // A lista é longa: rola até o aviso, no fim da tela.
    await tester.scrollUntilVisible(
      find.textContaining('Sua rede está completa'),
      200,
    );

    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('Adicionar contato'), findsNothing);
    expect(find.textContaining('Sua rede está completa (5/5)'), findsOneWidget);
  });

  testWidgets('Com espaço livre, o aviso de rede cheia não aparece', (
    tester,
  ) async {
    controller.add(name: 'Maria Silva', phone: '51999990001');
    await pumpPage(tester);

    expect(find.textContaining('Sua rede está completa'), findsNothing);
  });

  testWidgets('Remover um contato da rede cheia reabre um espaço', (
    tester,
  ) async {
    for (var i = 1; i <= 5; i++) {
      controller.add(name: 'Contato $i', phone: '5199999000$i');
    }
    await pumpPage(tester);

    controller.remove(controller.contacts.first.id);
    await tester.pump();

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Adicionar contato'), findsOneWidget);
    expect(find.textContaining('Sua rede está completa'), findsNothing);
  });
}
