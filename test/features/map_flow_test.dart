// Fluxo da aba Mapa no app de verdade (rotas, providers e o serviço real).
//
// Num teste não existe GPS nem plugin: a chamada ao aparelho nunca responde, e
// a tela fica em "Buscando…". Serve para conferir o caminho completo (barra
// inferior -> aba Mapa -> botão -> busca em andamento). Os casos de sucesso e de
// erro, com um GPS "de mentira", estão em map_page_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';

void main() {
  testWidgets('Fluxo: Home -> Mapa -> tocar no botão inicia a busca', (
    tester,
  ) async {
    // O appRouter é global: começa sempre pela Home.
    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(const AdaApp());
    const short = Duration(milliseconds: 600);
    await tester.pump(short);

    await tester.tap(find.byIcon(LucideIcons.mapPin));
    await tester.pump(short);

    // Antes de tocar: a explicação do uso da localização.
    expect(find.text('Mapa'), findsOneWidget);
    expect(
      find.textContaining('Ela não é guardada no aparelho.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump(short);

    // A busca começou: indicador de progresso e botão desligado.
    expect(find.text('Buscando…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    appRouter.go(AppRoutes.home);
  });
}
