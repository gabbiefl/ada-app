// Fluxo completo do horário de cobertura no app de verdade: a faixa aparece na
// tela de cobertura e o Modo Perigo liga para quem a hora manda. O relógio, o GPS
// e o envio de SMS são falsos: nenhum teste liga ou manda mensagem.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/pages/alert_page.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';

const _short = Duration(milliseconds: 600);

// Três contatos; a faixa das 8:00 às 13:00 é do SEGUNDO (Ana).
const _bia = Contact(id: 'b', name: 'Bia', phone: '51999990001');
const _ana = Contact(id: 'a', name: 'Ana', phone: '51999990002');
const _cris = Contact(id: 'c', name: 'Cris', phone: '51999990003');
const _anaMorning = CoverageRule(
  id: 'r1',
  contactId: 'a',
  start: 8 * 60,
  end: 13 * 60,
);

Future<FakeAlertActions> _pumpApp(
  WidgetTester tester, {
  required DateTime now,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final actions = FakeAlertActions();
  // O appRouter é global: começa sempre pelas Configurações neste teste.
  appRouter.go(AppRoutes.settings);
  await tester.pumpWidget(
    AdaApp(
      locationService: FakeLocationService(
        const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
      ),
      alertActions: actions,
      contactsRepository: InMemoryContactsRepository([_bia, _ana, _cris]),
      messagesRepository: InMemoryMessagesRepository(),
      coverageRepository: InMemoryCoverageRepository([_anaMorning]),
      clock: () => now,
    ),
  );
  await tester.pump(_short);
  return actions;
}

Future<void> _openCoverage(WidgetTester tester) async {
  await tester.tap(find.text('Horário de cobertura'));
  await tester.pump(_short);
}

Future<void> _activateDanger(WidgetTester tester) async {
  appRouter.go(AppRoutes.home);
  await tester.pump(_short);
  await tester.tap(find.text('MODO PERIGO'));
  await tester.pump(_short);
  await tester.tap(find.text('Ativar'));
  await tester.pump(_short);
}

List<String> _called(FakeAlertActions actions) => [
  for (final c in actions.calls)
    if (c.kind == AlertActionKind.call) c.phone,
];

void main() {
  testWidgets('dentro da faixa: a tela diz quem seria ligado e o Perigo liga', (
    tester,
  ) async {
    final actions = await _pumpApp(tester, now: DateTime(2026, 11, 8, 10, 0));

    await _openCoverage(tester);
    // A tela mostra a faixa e diz quem seria ligado agora.
    expect(find.text('8:00 - 13:00'), findsOneWidget);
    expect(find.text('Agora, o ADA ligaria para Ana.'), findsOneWidget);

    await _activateDanger(tester);

    // E o Perigo liga para essa mesma pessoa, avisando as outras por SMS.
    expect(find.byType(AlertPage), findsOneWidget);
    expect(find.text('Ligando para Ana'), findsOneWidget);
    expect(_called(actions), [_ana.phone]);
    final sms = actions.calls
        .where((c) => c.kind == AlertActionKind.sendSms)
        .map((c) => c.phone);
    expect(sms, [_bia.phone, _cris.phone]);
  });

  testWidgets('fora da faixa: liga para o primeiro da lista', (tester) async {
    final actions = await _pumpApp(tester, now: DateTime(2026, 11, 8, 20, 0));

    await _openCoverage(tester);
    expect(find.text('Agora, o ADA ligaria para Bia.'), findsOneWidget);

    await _activateDanger(tester);

    expect(find.text('Ligando para Bia'), findsOneWidget);
    expect(_called(actions), [_bia.phone]);
  });

  testWidgets('desligar a faixa pela chave muda quem o Perigo liga', (
    tester,
  ) async {
    final actions = await _pumpApp(tester, now: DateTime(2026, 11, 8, 10, 0));

    await _openCoverage(tester);
    expect(find.text('Agora, o ADA ligaria para Ana.'), findsOneWidget);

    await tester.tap(find.byType(Switch)); // desliga a faixa da Ana
    await tester.pump(_short);
    expect(find.text('Agora, o ADA ligaria para Bia.'), findsOneWidget);

    await _activateDanger(tester);

    expect(_called(actions), [_bia.phone]);
  });

  testWidgets('na hora exata em que a faixa acaba, vale a regra de fora', (
    tester,
  ) async {
    final actions = await _pumpApp(tester, now: DateTime(2026, 11, 8, 13, 0));

    await _activateDanger(tester);

    expect(_called(actions), [_bia.phone]); // o fim (13:00) não conta
  });

  testWidgets('remover o contato da faixa apaga a faixa e volta ao primeiro', (
    tester,
  ) async {
    final actions = await _pumpApp(tester, now: DateTime(2026, 11, 8, 10, 0));

    // A Ana sai da rede: a faixa dela deixa de existir.
    Provider.of<ContactsController>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    ).remove('a');
    await tester.pump(_short);

    await _openCoverage(tester);
    expect(find.text('8:00 - 13:00'), findsNothing);
    expect(find.text('Nenhuma faixa criada'), findsOneWidget);

    await _activateDanger(tester);

    expect(_called(actions), [_bia.phone]);
  });
}
