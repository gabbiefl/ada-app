// Fluxo completo dos modos no app de verdade (rotas, providers, confirmações e
// tela de alerta). O GPS e o envio de SMS são falsos: nenhum teste manda
// mensagem ou liga de verdade.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/pages/alert_page.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';

void main() {
  testWidgets('Fluxo: Normal -> Atenção -> Perigo -> Normal', (tester) async {
    // Tela alta: os dois cards cabem sem rolar.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final actions = FakeAlertActions();

    // O appRouter é global: começa sempre pela Home.
    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(
      AdaApp(
        locationService: FakeLocationService(
          const LocationResult.success(
            GeoPoint(latitude: -30.0346, longitude: -51.2177),
          ),
        ),
        alertActions: actions,
        // Armazenamento falso: o real não responde no ambiente de teste.
        contactsRepository: InMemoryContactsRepository(),
        messagesRepository: InMemoryMessagesRepository(),
        coverageRepository: InMemoryCoverageRepository(),
      ),
    );
    const short = Duration(milliseconds: 600);
    await tester.pump(short);

    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);

    // Atenção: card + Ativar (2 toques), e abre a tela do alerta.
    await tester.tap(find.text('MODO ATENÇÃO'));
    await tester.pump(short);
    await tester.tap(find.text('Ativar'));
    await tester.pump(short);
    expect(find.byType(AlertPage), findsOneWidget);
    expect(find.text('MODO ATENÇÃO'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump(short);
    expect(find.text('Modo atenção ativo'), findsOneWidget); // chip da Home

    // Perigo: 2 toques (card + Ativar), e abre a tela do alerta.
    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(short);
    await tester.tap(find.text('Ativar'));
    await tester.pump(short);
    expect(find.byType(AlertPage), findsOneWidget);
    expect(find.text('MODO PERIGO'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump(short);

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

    // Sem contatos cadastrados nada foi enviado nem ligado.
    expect(actions.calls, isEmpty);
  });
}
