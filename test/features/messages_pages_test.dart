// Testa as telas Mensagens e Mensagens - Editar.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
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

  Widget editApp(MessagesController controller, MessageKind kind) =>
      ChangeNotifierProvider.value(
        value: controller,
        child: _app(MessageEditPage(kind: kind)),
      );

  testWidgets('Editar: o contador acompanha o texto e o reset restaura', (
    tester,
  ) async {
    await tester.pumpWidget(editApp(MessagesController(), MessageKind.danger));
    expect(find.text('90/200'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Oi');
    await tester.pump();
    expect(find.text('2/200'), findsOneWidget);

    await tester.tap(find.text('Resetar para padrão'));
    await tester.pump();
    expect(find.text('90/200'), findsOneWidget);
  });

  testWidgets('Editar: abre com o texto e o título da mensagem escolhida', (
    tester,
  ) async {
    await tester.pumpWidget(
      editApp(MessagesController(), MessageKind.attention),
    );

    expect(find.text('Editando: Modo atenção'), findsOneWidget);
    expect(find.text(MessageKind.attention.defaultText), findsOneWidget);
  });

  testWidgets('Editar: texto vazio não salva e mostra explicação', (
    tester,
  ) async {
    final controller = MessagesController();
    await tester.pumpWidget(editApp(controller, MessageKind.danger));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Salvar mensagem'));
    await tester.pump();

    expect(find.text('Escreva uma mensagem antes de salvar.'), findsOneWidget);
    expect(controller.isCustomized(MessageKind.danger), isFalse);
  });

  // Fluxo completo no app de verdade: usa o appRouter global, então volta à Home
  // antes de começar.
  testWidgets('Fluxo: editar uma mensagem, salvar e ver na lista', (
    tester,
  ) async {
    appRouter.go(AppRoutes.messages);
    await tester.pumpWidget(const AdaApp());
    await tester.pump(const Duration(milliseconds: 300));

    // O 2º "Editar" é o do Modo atenção.
    await tester.tap(find.text('Editar').at(1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Editando: Modo atenção'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Estou insegura.');
    await tester.tap(find.text('Salvar mensagem'));
    await tester.pump(const Duration(milliseconds: 500));

    // Voltou à lista: texto novo na atenção, perigo intacto.
    expect(find.text('Estou insegura.'), findsOneWidget);
    expect(find.text(MessageKind.danger.defaultText), findsOneWidget);

    appRouter.go(AppRoutes.home);
  });

  // "Fechar e abrir o app": o armazenamento já tem um texto salvo antes de o app
  // nascer, e a tela Mensagens precisa mostrá-lo.
  testWidgets('Fluxo: mensagem salva antes aparece ao abrir o app', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'ada_messages': '{"arrived":"Cheguei, mãe!"}',
    });
    appRouter.go(AppRoutes.messages);
    await tester.pumpWidget(const AdaApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cheguei, mãe!'), findsOneWidget);
    expect(find.text(MessageKind.arrived.defaultText), findsNothing);

    FlutterSecureStorage.setMockInitialValues({});
    appRouter.go(AppRoutes.home);
  });
}
