// Testa a navegação do app: barra inferior, telas internas e voltar.
//
// Não usamos pumpAndSettle porque a Home tem uma animação que nunca termina
// (os anéis pulsando): ele esperaria para sempre. `pump` com duração avança o
// relógio do teste por um tempo fixo, o suficiente para a transição de tela.

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/features/home/pages/home_page.dart';

Future<void> _passTime(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

void main() {
  testWidgets('A barra inferior leva às abas', (tester) async {
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);
    expect(find.text('Olá, Gabriela'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.users));
    await _passTime(tester);
    expect(find.text('Rede de contatos'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.mapPin));
    await _passTime(tester);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('Configurações abre Mensagens e a edição, e dá para voltar', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);

    await tester.tap(find.byIcon(LucideIcons.settings));
    await _passTime(tester);
    await tester.tap(find.text('Mensagens personalizadas'));
    await _passTime(tester);
    expect(find.text('Modo atenção'), findsOneWidget);

    await tester.tap(find.text('Editar').first);
    await _passTime(tester);
    expect(find.text('Texto da mensagem'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await _passTime(tester);
    expect(find.text('Modo atenção'), findsOneWidget);
  });

  testWidgets('Adicionar contato abre o cadastro e Cancelar volta', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);

    await tester.tap(find.byIcon(LucideIcons.users));
    await _passTime(tester);
    await tester.tap(find.text('Adicionar contato').first);
    await _passTime(tester);
    expect(find.text('Novo contato'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await _passTime(tester);
    expect(find.text('Rede de contatos'), findsOneWidget);
  });

  testWidgets('Horário abre a tela de cobertura e as rotas do formulário', (
    tester,
  ) async {
    // O appRouter é um só para o app inteiro e guarda o lugar onde parou no
    // teste anterior. `go` o leva direto a Configurações (a vantagem de rotas
    // por caminho: ir a qualquer tela sem tocar na barra).
    appRouter.go(AppRoutes.settings);
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);

    await tester.tap(find.text('Horário de cobertura'));
    await _passTime(tester);
    // A tela de verdade. Sem contatos cadastrados ela explica isso, e esse texto
    // só existe nela (o título e o subtítulo também aparecem no menu).
    expect(find.textContaining('ainda não tem contatos'), findsOneWidget);

    // A seta de voltar é a que fecha a tela.
    appRouter.pop();
    await _passTime(tester);
    expect(find.textContaining('ainda não tem contatos'), findsNothing);

    // As rotas do formulário existem no app de verdade (nova faixa e edição).
    appRouter.go(AppRoutes.newCoverage);
    await _passTime(tester);
    expect(find.text('Nova faixa'), findsOneWidget);

    appRouter.go(AppRoutes.editCoverage('fantasma'));
    await _passTime(tester);
    expect(find.text('Faixa não encontrada'), findsOneWidget);

  });

  testWidgets('A seta de Mensagens volta para Configurações', (tester) async {
    appRouter.go(AppRoutes.settings);
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);

    await tester.tap(find.text('Mensagens personalizadas'));
    await _passTime(tester);
    expect(find.text('Modo atenção'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await _passTime(tester);
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('O app fornece o ModeController, começando no Normal', (
    tester,
  ) async {
    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(const AdaApp());
    await _passTime(tester);

    // `context.read` em um widget da Home: acha o controlador que o provider
    // pendurou acima do MaterialApp.
    final context = tester.element(find.byType(HomePage));
    expect(context.read<ModeController>().mode, SecurityMode.normal);
  });
}
