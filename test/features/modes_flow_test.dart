// Fluxo completo dos modos no app de verdade (com rotas, providers e vibração
// real do sistema, que no teste simplesmente não faz nada).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';

void main() {
  testWidgets('Fluxo: Normal -> Atenção -> Perigo -> Normal', (tester) async {
    // Tela alta: os dois cards cabem sem rolar.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // O appRouter é global: começa sempre pela Home.
    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(const AdaApp());
    const short = Duration(milliseconds: 300);
    await tester.pump(short);

    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);

    // Atenção: 1 toque.
    await tester.tap(find.text('MODO ATENÇÃO'));
    await tester.pump(short);
    expect(find.text('Modo atenção ativo'), findsOneWidget);

    // Perigo: 2 toques (card + Ativar).
    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(short);
    await tester.tap(find.text('Ativar'));
    await tester.pump(short);
    expect(find.text('Modo perigo ativo'), findsOneWidget);
    expect(find.text('Modo atenção ativo'), findsNothing);

    // Do Perigo, o card Atenção é recusado e o alerta continua.
    await tester.tap(find.text('MODO ATENÇÃO'));
    await tester.pump(short);
    expect(
      find.text('Desative o Modo perigo antes de mudar para Atenção.'),
      findsOneWidget,
    );
    expect(find.text('Modo perigo ativo'), findsOneWidget);

    // Desativar: símbolo + Desativar.
    await tester.tap(find.bySemanticsLabel('Desativar alerta'));
    await tester.pump(short);
    await tester.tap(find.text('Desativar'));
    await tester.pump(short);
    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
  });
}
