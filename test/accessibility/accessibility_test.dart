// Auditoria de ACESSIBILIDADE das telas, feita por testes automáticos.
//
// Cada tela passa por três verificações:
//   1. alvo de toque: tudo o que se toca tem pelo menos 48 x 48 (Android);
//   2. nome: tudo o que se toca tem um nome para o leitor de tela;
//   3. texto grande: com a fonte do sistema em 2x, a tela não estoura (overflow).
//
// As duas primeiras usam as "guidelines" do próprio Flutter (meetsGuideline). A
// terceira abre a tela com a fonte aumentada: se algo não couber, o Flutter lança
// um erro de overflow e o teste falha.
//
// O CONTRASTE fica em contrast_test.dart: a guideline de contraste do Flutter mede
// por captura de tela e se confunde com o texto fino do ADA (peso 300), então lá o
// cálculo é exato (fórmula do WCAG), par de cores por par de cores.
//
// Um achado que ainda não foi corrigido fica em [_knownIssues], com o motivo: o
// teste é PULADO (skip) e aparece no relatório. Ao corrigir, a linha é apagada e
// o teste passa a valer. Assim a suíte fica verde e a dívida fica visível.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/profile/data/profile_repository.dart';

import '../support/app_font.dart';

const _short = Duration(milliseconds: 600);

// As quatro verificações.
enum Check { tapTarget, label, bigText }

// Achados conhecidos e ainda não corrigidos: "tela|verificação" -> motivo.
// (Esta lista é preenchida pela auditoria e esvaziada pelas correções. Está vazia:
// todos os achados da Fase 11 foram corrigidos.)
const _knownIssues = <String, String>{};

// Uma tela da auditoria: um nome e como chegar nela.
class _Screen {
  const _Screen(this.name, this.open);

  final String name;
  final Future<void> Function(WidgetTester tester) open;
}

// Dados de exemplo: três contatos e duas faixas de horário.
const _contacts = [
  Contact(id: 'm', name: 'Maria', phone: '51999990001'),
  Contact(id: 'a', name: 'Ana', phone: '51999990002'),
  Contact(id: 'b', name: 'Bia', phone: '51999990003'),
];
const _rules = [
  CoverageRule(id: 'r1', contactId: 'a', start: 8 * 60, end: 13 * 60),
  CoverageRule(id: 'r2', contactId: 'b', start: 13 * 60, end: 18 * 60),
];

// Abre o app inteiro com serviços falsos, num celular de tamanho realista.
Future<void> _pumpApp(WidgetTester tester, String route) async {
  // 393 x 873 pixels lógicos: um celular comum. É o tamanho real que importa para
  // os alvos de toque e para o texto grande.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  appRouter.go(route);
  await tester.pumpWidget(
    AdaApp(
      locationService: FakeLocationService(
        const LocationResult.success(
          GeoPoint(latitude: -30.0346, longitude: -51.2177),
        ),
      ),
      alertActions: FakeAlertActions(),
      contactsRepository: InMemoryContactsRepository(_contacts),
      messagesRepository: InMemoryMessagesRepository(),
      coverageRepository: InMemoryCoverageRepository(_rules),
      onboardingRepository: InMemoryOnboardingRepository(true),
      profileRepository: InMemoryProfileRepository('Ana'),
      clock: () => DateTime(2026, 11, 8, 10, 0),
    ),
  );
  await tester.pump(_short);
}

// Abre a tela do alerta ativando o Perigo (ou a Atenção) pela Home, como a usuária.
Future<void> _openAlert(WidgetTester tester, {required bool danger}) async {
  await _pumpApp(tester, AppRoutes.home);
  final card = find.text(danger ? 'MODO PERIGO' : 'MODO ATENÇÃO');
  // Com texto grande, o cartão pode ficar abaixo da área visível: a usuária rola a
  // tela até ele, e o teste também.
  await tester.ensureVisible(card);
  await tester.pump(_short);
  await tester.tap(card);
  await tester.pump(_short);
  await tester.tap(find.text('Ativar'));
  await tester.pump(_short);
}

// Abre o onboarding e avança [pages] telas com "Continuar".
Future<void> _openOnboarding(WidgetTester tester, int pages) async {
  await _pumpApp(tester, AppRoutes.onboarding);
  for (var i = 0; i < pages; i++) {
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump(_short);
    await tester.pump(_short);
  }
}

final _screens = <_Screen>[
  _Screen('Nome (primeira vez)', (t) => _pumpApp(t, AppRoutes.profileSetup)),
  _Screen('Onboarding 1', (t) => _openOnboarding(t, 0)),
  _Screen('Onboarding 2', (t) => _openOnboarding(t, 1)),
  _Screen('Onboarding 3', (t) => _openOnboarding(t, 2)),
  _Screen('Início', (t) => _pumpApp(t, AppRoutes.home)),
  _Screen('Rede', (t) => _pumpApp(t, AppRoutes.contacts)),
  _Screen('Novo contato', (t) => _pumpApp(t, AppRoutes.newContact)),
  _Screen('Mapa', (t) => _pumpApp(t, AppRoutes.map)),
  _Screen('Configurações', (t) => _pumpApp(t, AppRoutes.settings)),
  _Screen('Mensagens', (t) => _pumpApp(t, AppRoutes.messages)),
  _Screen(
    'Editar mensagem',
    (t) => _pumpApp(t, AppRoutes.editMessage(MessageKind.danger)),
  ),
  _Screen('Horário de cobertura', (t) => _pumpApp(t, AppRoutes.coverage)),
  _Screen('Nova faixa', (t) => _pumpApp(t, AppRoutes.newCoverage)),
  _Screen('Editar faixa', (t) => _pumpApp(t, AppRoutes.editCoverage('r1'))),
  _Screen('Alerta (Perigo)', (t) => _openAlert(t, danger: true)),
  _Screen('Alerta (Atenção)', (t) => _openAlert(t, danger: false)),
];

String _label(Check check) => switch (check) {
  Check.tapTarget => 'alvos de toque de 48',
  Check.label => 'nomes para o leitor de tela',
  Check.bigText => 'texto em tamanho duplo',
};

void main() {
  // A fonte de verdade (ver test/support/app_font.dart).
  setUpAll(loadAppFont);

  for (final screen in _screens) {
    group('Acessibilidade: ${screen.name}', () {
      for (final check in Check.values) {
        final issue = _knownIssues['${screen.name}|${check.name}'];

        testWidgets(_label(check), (tester) async {
          // Liga a árvore de semântica: é ela que o leitor de tela usa. Precisa
          // ser fechada ANTES de o teste acabar (por isso o try/finally).
          final semantics = tester.ensureSemantics();
          try {
            if (check == Check.bigText) {
              // Fonte do sistema em 2x, como quem usa texto grande.
              tester.platformDispatcher.textScaleFactorTestValue = 2.0;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
            }

            await screen.open(tester);

            switch (check) {
              case Check.tapTarget:
                await expectLater(
                  tester,
                  meetsGuideline(androidTapTargetGuideline),
                );
              case Check.label:
                await expectLater(
                  tester,
                  meetsGuideline(labeledTapTargetGuideline),
                );
              case Check.bigText:
                // Um overflow já falha o teste sozinho; aqui só se confere que
                // nada foi reportado e que a tela segue com o seu conteúdo.
                expect(tester.takeException(), isNull);
                expect(find.byType(Scaffold), findsWidgets);
            }
          } finally {
            semantics.dispose();
          }
        }, skip: issue != null);
      }
    });
  }
}
