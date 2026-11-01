// Testa a tela Novo contato: campos, validação e salvamento.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/contacts/pages/contact_form_page.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';

void main() {
  late ContactsController controller;

  setUp(() => controller = ContactsController());
  tearDown(() => controller.dispose());

  Future<void> pumpForm(WidgetTester tester, {String? contactId}) =>
      tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: ContactFormPage(contactId: contactId),
          ),
        ),
      );

  Finder field(String hint) => find.widgetWithText(TextFormField, hint);

  testWidgets('O cadastro mostra os campos, os botões e a posição na rede', (
    tester,
  ) async {
    controller.add(name: 'Maria', phone: '51999990001');
    await pumpForm(tester);

    expect(find.text('Novo contato'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget); // será o segundo contato
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Salvar contato'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('Salvar vazio mostra os erros e não cadastra', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Salvar contato'));
    await tester.pump();

    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe o telefone.'), findsOneWidget);
    expect(controller.contacts, isEmpty);
  });

  testWidgets('Telefone inválido mostra a mensagem do validador', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(field('Nome do contato'), 'Maria Silva');
    await tester.enterText(field('(51) 99999-0000'), '123');
    await tester.tap(find.text('Salvar contato'));
    await tester.pump();

    expect(find.text('Informe o nome.'), findsNothing);
    expect(find.textContaining('Digite o DDD'), findsOneWidget);
    expect(controller.contacts, isEmpty);
  });

  testWidgets('Telefone que já está na rede mostra o aviso', (tester) async {
    controller.add(name: 'Maria', phone: '51999990001');
    await pumpForm(tester);

    await tester.enterText(field('Nome do contato'), 'Outra Pessoa');
    await tester.enterText(field('(51) 99999-0000'), '(51) 99999-0001');
    await tester.tap(find.text('Salvar contato'));
    await tester.pump();

    expect(find.text('Este telefone já está na sua rede.'), findsOneWidget);
    expect(controller.count, 1);
  });

  testWidgets('O campo de telefone ignora letras', (tester) async {
    await pumpForm(tester);

    await tester.enterText(field('(51) 99999-0000'), '51abc99');

    expect(find.text('5199'), findsOneWidget);
  });

  testWidgets('Salvar cadastra o contato e volta para a Rede', (tester) async {
    appRouter.go(AppRoutes.contacts);
    await tester.pumpWidget(const AdaApp());
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Adicionar contato').first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(field('Nome do contato'), 'Maria Silva');
    await tester.enterText(field('(51) 99999-0000'), '51999990001');
    await tester.tap(find.text('Salvar contato'));
    await tester.pump(const Duration(milliseconds: 600));

    // Voltou para a Rede, já com o contato na lista.
    expect(find.text('Rede de contatos'), findsOneWidget);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('(51) 99999-0001'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('Editar: campos preenchidos, sem o card da agenda', (
    tester,
  ) async {
    controller.add(name: 'Maria Silva', phone: '51999990001');
    await pumpForm(tester, contactId: controller.contacts.single.id);

    expect(find.text('Editar contato'), findsOneWidget);
    expect(find.text('Novo contato'), findsNothing);
    expect(find.text('Escolher da agenda'), findsNothing);
    expect(find.text('ou preencha'), findsNothing);
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('(51) 99999-0001'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('Editar: tocar no card, trocar o nome e salvar', (tester) async {
    appRouter.go(AppRoutes.contacts);
    await tester.pumpWidget(const AdaApp());
    await tester.pump(const Duration(milliseconds: 600));

    // Cadastra um contato pela própria interface.
    await tester.tap(find.text('Adicionar contato').first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(field('Nome do contato'), 'Maria Silva');
    await tester.enterText(field('(51) 99999-0000'), '51999990001');
    await tester.tap(find.text('Salvar contato'));
    await tester.pump(const Duration(milliseconds: 600));

    // Toca no card: abre a edição.
    await tester.tap(find.text('Maria Silva'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Editar contato'), findsOneWidget);

    await tester.enterText(field('Nome do contato'), 'Maria Souza');
    await tester.tap(find.text('Salvar contato'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Rede de contatos'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Maria Silva'), findsNothing);
    expect(find.text('1/5'), findsOneWidget); // editou, não duplicou
  });

  test('o botão principal do tema é azul-marinho', () {
    final cor = AppTheme.light.colorScheme.primary;
    expect(cor, const Color(0xFF172033));
  });
}
