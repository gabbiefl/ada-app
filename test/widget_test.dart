// Teste de widget: monta o app em um ambiente de teste (sem emulador)
// e verifica o que aparece na tela.
//
// Rode com: flutter test
//
// Nada aqui envia SMS, liga ou usa GPS de verdade: o alerta usa serviços falsos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/pages/alert_page.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/state/coverage_call_target_policy.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/home/pages/home_page.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

// Tela de teste mais alta, para os dois cards caberem sem rolar.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Tudo o que um teste da Home precisa para conferir depois.
class _Home {
  _Home(this.mode, this.alert, this.actions);

  final ModeController mode;
  final AlertController alert;
  final FakeAlertActions actions;
}

const _short = Duration(milliseconds: 600);

// Monta a Home com uma rede de [contacts] contatos e o alerta com serviços
// falsos. Usa um GoRouter próprio (só a Home e a tela Alerta), porque tocar em
// "Ativar" abre a tela de progresso.
Future<_Home> _pumpHome(
  WidgetTester tester, {
  int contacts = 3,
  ContactsController? network,
  MessagesController? messages,
  CoverageController? coverage,
  DateTime Function()? now, // o "relógio" do teste (padrão: a hora real)
}) async {
  _tallScreen(tester);

  final actions = FakeAlertActions();
  final mode = ModeController();
  final coverageController = coverage ?? CoverageController();
  final alert = AlertController(
    locationService: FakeLocationService(
      const LocationResult.success(
        GeoPoint(latitude: -30.0346, longitude: -51.2177),
      ),
    ),
    actions: actions,
    // Quem o Perigo liga vem do horário de cobertura (sem faixas: o primeiro).
    callTarget: CoverageCallTargetPolicy(
      coverage: coverageController,
      now: now,
    ),
  );
  final contactsController = network ?? ContactsController();
  if (network == null) {
    for (var i = 1; i <= contacts; i++) {
      contactsController.add(name: 'Contato $i', phone: '5199999000$i');
    }
  }
  final messagesController = messages ?? MessagesController();
  for (final controller in [
    mode,
    alert,
    contactsController,
    messagesController,
    coverageController,
  ]) {
    addTearDown(controller.dispose);
  }

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.alert, builder: (_, _) => const AlertPage()),
    ],
  );

  // .value: fornece controladores que já existem (o teste guarda a referência
  // para conferir e mudar o estado depois).
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: mode),
        ChangeNotifierProvider.value(value: alert),
        ChangeNotifierProvider.value(value: contactsController),
        ChangeNotifierProvider.value(value: messagesController),
        ChangeNotifierProvider.value(value: coverageController),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return _Home(mode, alert, actions);
}

// Repositório que só entrega os contatos quando o teste mandar (ou nunca): simula
// o armazenamento ainda lendo na hora em que o alerta é ativado.
class _SlowContactsRepository implements ContactsRepository {
  final _completer = Completer<List<Contact>>();

  void finish(List<Contact> contacts) => _completer.complete(contacts);

  @override
  Future<List<Contact>> load() => _completer.future;

  @override
  Future<void> save(List<Contact> contacts) async {}
}

// Repositório de faixas que só entrega quando o teste mandar.
class _SlowCoverageRepository implements CoverageRepository {
  final _completer = Completer<List<CoverageRule>>();

  void finish(List<CoverageRule> rules) => _completer.complete(rules);

  @override
  Future<List<CoverageRule>> load() => _completer.future;

  @override
  Future<void> save(List<CoverageRule> rules) async {}
}

List<String> _phones(FakeAlertActions actions, AlertActionKind kind) => [
  for (final c in actions.calls)
    if (c.kind == kind) c.phone,
];

void main() {
  // `testWidgets` cria um teste que recebe um `tester`, o "controle remoto"
  // para montar widgets, tocar na tela e consultar o que está visível.
  testWidgets('A tela inicial mostra a saudação', (tester) async {
    // O app abre na splash; `go` leva direto à Home (o roteador é um só).
    appRouter.go(AppRoutes.home);
    // Monta o app e espera o primeiro quadro ser desenhado.
    await tester.pumpWidget(const AdaApp());

    // `find.text` procura um Text com exatamente esse conteúdo.
    expect(find.text('Olá!'), findsOneWidget);
    expect(find.text('Estamos com você!'), findsOneWidget);
    // Os dois cards dos modos aparecem.
    expect(find.text('MODO PERIGO'), findsOneWidget);
    expect(find.text('MODO ATENÇÃO'), findsOneWidget);
  });

  testWidgets('O app aplica o tema do ADA', (tester) async {
    await tester.pumpWidget(const AdaApp());

    // Procura o MaterialApp montado e confere o fundo do tema que ele recebeu.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
  });

  testWidgets('A Home acompanha o modo do controlador', (tester) async {
    final home = await _pumpHome(tester);

    // Começa no Normal.
    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    expect(find.text('Modo perigo ativo'), findsNothing);

    // Muda o modo: a Home deve se redesenhar sozinha.
    // pump(Duration) em vez de pumpAndSettle: os anéis pulsam para sempre.
    home.mode.activate(SecurityMode.danger);
    await tester.pump(_short);

    expect(find.text('Modo perigo ativo'), findsOneWidget);
    expect(find.text('Toque no ícone para desativar.'), findsOneWidget);
    expect(find.text('Nenhum alerta ativo no momento.'), findsNothing);

    // E volta ao Normal.
    home.mode.deactivate();
    await tester.pump(_short);

    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    expect(find.text('Modo perigo ativo'), findsNothing);
  });

  group('Modo Atenção', () {
    testWidgets('o toque no card pergunta; Ativar confirma e abre o alerta', (
      tester,
    ) async {
      final home = await _pumpHome(tester);

      await tester.tap(find.text('MODO ATENÇÃO'));
      await tester.pump(_short);

      // 1º toque: só o diálogo. O modo ainda não mudou e nada foi enviado.
      expect(find.text('Ativar o Modo atenção?'), findsOneWidget);
      expect(home.mode.mode, SecurityMode.normal);
      expect(home.actions.calls, isEmpty);

      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.attention);
      // Abriu a tela de progresso, e o alerta enviou SMS a todos, sem ligar.
      expect(find.byType(AlertPage), findsOneWidget);
      expect(find.text('MODO ATENÇÃO'), findsOneWidget);
      expect(_phones(home.actions, AlertActionKind.sendSms).length, 3);
      expect(home.actions.count(AlertActionKind.call), 0);
    });

    testWidgets('Cancelar não ativa nem envia nada', (tester) async {
      final home = await _pumpHome(tester);

      await tester.tap(find.text('MODO ATENÇÃO'));
      await tester.pump(_short);
      await tester.tap(find.text('Cancelar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
      expect(home.alert.phase, AlertPhase.idle);
      expect(home.actions.calls, isEmpty);
    });

    testWidgets('no Perigo, tocar na Atenção é recusado com aviso', (
      tester,
    ) async {
      final home = await _pumpHome(tester);
      home.mode.activate(SecurityMode.danger);
      await tester.pump(_short);

      await tester.tap(find.text('MODO ATENÇÃO'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.danger);
      expect(find.text('Ativar o Modo atenção?'), findsNothing); // sem diálogo
      expect(
        find.text('Desative o Modo perigo antes de mudar para Atenção.'),
        findsOneWidget,
      );
    });

    testWidgets('a Home mostra chip e instrução do modo', (tester) async {
      final home = await _pumpHome(tester);

      home.mode.activate(SecurityMode.attention);
      await tester.pump(_short);

      expect(find.text('Modo atenção ativo'), findsOneWidget);
      expect(find.text('Toque no ícone para desativar.'), findsOneWidget);
      expect(find.text('Modo perigo ativo'), findsNothing);
      expect(find.text('Nenhum alerta ativo no momento.'), findsNothing);
    });
  });

  group('Modo Perigo', () {
    testWidgets('o toque no card só pergunta; Ativar confirma e dispara', (
      tester,
    ) async {
      final home = await _pumpHome(tester);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);

      // 1º toque: só o diálogo. O modo ainda não mudou e nada foi enviado.
      expect(find.text('Ativar o Modo perigo?'), findsOneWidget);
      expect(home.mode.mode, SecurityMode.normal);
      expect(home.actions.calls, isEmpty);

      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.danger);
      // Sem nenhum toque a mais: abriu o progresso, mandou SMS aos outros dois
      // contatos e ligou para o primeiro.
      expect(find.byType(AlertPage), findsOneWidget);
      expect(find.text('MODO PERIGO'), findsOneWidget);
      expect(_phones(home.actions, AlertActionKind.sendSms), [
        '51999990002',
        '51999990003',
      ]);
      expect(_phones(home.actions, AlertActionKind.call), ['51999990001']);
    });

    testWidgets('Cancelar não ativa nem envia nada', (tester) async {
      final home = await _pumpHome(tester);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Cancelar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
      expect(find.text('Ativar o Modo perigo?'), findsNothing);
      expect(home.actions.calls, isEmpty);
    });

    testWidgets('o diálogo avisa o que o alerta vai fazer', (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);

      expect(find.textContaining('SMS'), findsOneWidget);
      expect(find.textContaining('ligar'), findsOneWidget);
    });

    testWidgets(
      'da Atenção, o Perigo encerra o alerta antigo e começa o novo',
      (tester) async {
        final home = await _pumpHome(tester);
        home.mode.activate(SecurityMode.attention);
        await tester.pump(_short);

        await tester.tap(find.text('MODO PERIGO'));
        await tester.pump(_short);
        await tester.tap(find.text('Ativar'));
        await tester.pump(_short);

        expect(home.mode.mode, SecurityMode.danger);
        expect(home.alert.kind, MessageKind.danger);
        expect(home.actions.count(AlertActionKind.call), 1);
      },
    );

    testWidgets('sem contatos, abre a tela explicando e não envia nada', (
      tester,
    ) async {
      final home = await _pumpHome(tester, contacts: 0);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.danger);
      expect(find.textContaining('ainda não tem contatos'), findsOneWidget);
      expect(home.actions.calls, isEmpty);
    });
  });

  group('Desativar', () {
    testWidgets('tocar no símbolo pergunta; Desativar confirma', (
      tester,
    ) async {
      final home = await _pumpHome(tester);
      home.mode.activate(SecurityMode.danger);
      await tester.pump(_short);

      await tester.tap(find.bySemanticsLabel('Desativar alerta'));
      await tester.pump(_short);

      expect(find.text('Desativar o alerta?'), findsOneWidget);
      expect(home.mode.mode, SecurityMode.danger); // ainda ativo

      await tester.tap(find.text('Desativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
    });

    testWidgets('Cancelar mantém o alerta ativo', (tester) async {
      final home = await _pumpHome(tester);
      home.mode.activate(SecurityMode.danger);
      await tester.pump(_short);

      await tester.tap(find.bySemanticsLabel('Desativar alerta'));
      await tester.pump(_short);
      await tester.tap(find.text('Cancelar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.danger);
    });

    testWidgets('desativar apaga o alerta em andamento', (tester) async {
      final home = await _pumpHome(tester);
      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);
      expect(home.alert.phase, AlertPhase.done);

      // Volta à Home e desativa.
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump(_short);
      await tester.tap(find.bySemanticsLabel('Desativar alerta'));
      await tester.pump(_short);
      await tester.tap(find.text('Desativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
      expect(home.alert.phase, AlertPhase.idle);
      expect(home.alert.deliveries, isEmpty);
    });

    testWidgets('a Atenção também desativa com confirmação', (tester) async {
      final home = await _pumpHome(tester);
      home.mode.activate(SecurityMode.attention);
      await tester.pump(_short);

      await tester.tap(find.bySemanticsLabel('Desativar alerta'));
      await tester.pump(_short);
      await tester.tap(find.text('Desativar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
      expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    });

    testWidgets('no modo Normal, tocar no símbolo não abre diálogo', (
      tester,
    ) async {
      await _pumpHome(tester);

      await tester.tap(find.byType(Image).at(1)); // o símbolo central
      await tester.pump(_short);

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  testWidgets('"Ver alerta" reabre a tela de progresso', (tester) async {
    final home = await _pumpHome(tester);
    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(_short);
    await tester.tap(find.text('Ativar'));
    await tester.pump(_short);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump(_short);
    expect(find.byType(AlertPage), findsNothing); // de volta à Home

    await tester.tap(find.text('Ver alerta'));
    await tester.pump(_short);

    expect(find.byType(AlertPage), findsOneWidget);
    // Reabrir não envia nada de novo.
    expect(home.actions.count(AlertActionKind.call), 1);
  });

  group('Cancelar alerta (na tela de progresso)', () {
    Future<_Home> openDangerAlert(WidgetTester tester) async {
      final home = await _pumpHome(tester);
      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);
      return home;
    }

    testWidgets('pergunta antes e, confirmado, volta ao Normal e à Home', (
      tester,
    ) async {
      final home = await openDangerAlert(tester);

      await tester.tap(find.text('Cancelar alerta'));
      await tester.pump(_short);

      // Só o diálogo: nada mudou ainda.
      expect(find.text('Cancelar o alerta?'), findsOneWidget);
      expect(home.mode.mode, SecurityMode.danger);

      // O botão do diálogo tem o mesmo rótulo; é o último da tela.
      await tester.tap(find.text('Cancelar alerta').last);
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.normal);
      expect(home.alert.phase, AlertPhase.idle);
      expect(find.byType(AlertPage), findsNothing); // voltou à Home
      expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    });

    testWidgets('"Continuar" mantém o alerta como está', (tester) async {
      final home = await openDangerAlert(tester);

      await tester.tap(find.text('Cancelar alerta'));
      await tester.pump(_short);
      await tester.tap(find.text('Continuar'));
      await tester.pump(_short);

      expect(home.mode.mode, SecurityMode.danger);
      expect(home.alert.phase, AlertPhase.done);
      expect(find.byType(AlertPage), findsOneWidget);
    });
  });

  group('Dados ainda carregando na hora de ativar', () {
    const maria = Contact(id: '1', name: 'Maria', phone: '51999990001');
    const ana = Contact(id: '2', name: 'Ana', phone: '51999990002');

    testWidgets('o alerta espera a rede carregar em vez de ver a lista vazia', (
      tester,
    ) async {
      final repository = _SlowContactsRepository();
      final network = ContactsController(repository: repository)..load();
      final home = await _pumpHome(tester, network: network);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);

      // A rede ainda não carregou: o alerta aguarda, e nada saiu.
      expect(find.byType(AlertPage), findsNothing);
      expect(home.actions.calls, isEmpty);

      repository.finish([maria, ana]);
      await tester.pump(_short);

      // Carregou: o alerta sai para a rede de verdade, sem "rede vazia".
      expect(find.byType(AlertPage), findsOneWidget);
      expect(find.textContaining('ainda não tem contatos'), findsNothing);
      expect(_phones(home.actions, AlertActionKind.sendSms), ['51999990002']);
      expect(_phones(home.actions, AlertActionKind.call), ['51999990001']);
    });

    testWidgets('se a leitura travar, o alerta sai mesmo assim após o prazo', (
      tester,
    ) async {
      final network = ContactsController(repository: _SlowContactsRepository())
        ..load(); // nunca termina
      final home = await _pumpHome(tester, network: network);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);
      expect(find.byType(AlertPage), findsNothing); // ainda esperando

      await tester.pump(const Duration(seconds: 3)); // passou do prazo

      // Não ficou preso: o modo está ativo e a tela do alerta abriu.
      expect(home.mode.mode, SecurityMode.danger);
      expect(find.byType(AlertPage), findsOneWidget);
    });

    testWidgets('o alerta usa a mensagem que a usuária editou', (tester) async {
      final messages = MessagesController(
        repository: InMemoryMessagesRepository({
          MessageKind.danger: 'Texto que eu mesma escrevi.',
        }),
      )..load();
      final home = await _pumpHome(tester, messages: messages);

      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);

      final sms = home.actions.calls.firstWhere(
        (c) => c.kind == AlertActionKind.sendSms,
      );
      expect(sms.text, startsWith('Texto que eu mesma escrevi.'));
    });
  });

  group('Horário de cobertura: quem o Perigo liga', () {
    // Uma rede de 3 contatos ("Contato 1", "Contato 2", "Contato 3") e uma faixa
    // das 8:00 às 13:00 para o SEGUNDO.
    ContactsController network3() {
      final network = ContactsController();
      for (var i = 1; i <= 3; i++) {
        network.add(name: 'Contato $i', phone: '5199999000$i');
      }
      return network;
    }

    CoverageController morningForSecond(ContactsController network) {
      final coverage = CoverageController();
      coverage.add(
        contactId: network.contacts[1].id,
        start: 8 * 60,
        end: 13 * 60,
      );
      return coverage;
    }

    Future<void> activateDanger(WidgetTester tester) async {
      await tester.tap(find.text('MODO PERIGO'));
      await tester.pump(_short);
      await tester.tap(find.text('Ativar'));
      await tester.pump(_short);
    }

    testWidgets('dentro da faixa, liga para o contato dela', (tester) async {
      final network = network3();
      final home = await _pumpHome(
        tester,
        network: network,
        coverage: morningForSecond(network),
        now: () => DateTime(2026, 11, 7, 10, 0),
      );

      await activateDanger(tester);

      expect(_phones(home.actions, AlertActionKind.call), ['51999990002']);
      // Os outros dois recebem o SMS.
      expect(_phones(home.actions, AlertActionKind.sendSms), [
        '51999990001',
        '51999990003',
      ]);
      expect(find.text('Ligando para Contato 2'), findsOneWidget);
    });

    testWidgets('fora da faixa, liga para o primeiro da lista', (tester) async {
      final network = network3();
      final home = await _pumpHome(
        tester,
        network: network,
        coverage: morningForSecond(network),
        now: () => DateTime(2026, 11, 7, 20, 0),
      );

      await activateDanger(tester);

      expect(_phones(home.actions, AlertActionKind.call), ['51999990001']);
    });

    testWidgets('na hora exata em que a faixa acaba, já vale a regra de fora', (
      tester,
    ) async {
      final network = network3();
      final home = await _pumpHome(
        tester,
        network: network,
        coverage: morningForSecond(network),
        now: () => DateTime(2026, 11, 7, 13, 0), // o fim não conta
      );

      await activateDanger(tester);

      expect(_phones(home.actions, AlertActionKind.call), ['51999990001']);
    });

    testWidgets('as faixas ainda carregando: o alerta espera e usa a regra', (
      tester,
    ) async {
      final network = network3();
      final repository = _SlowCoverageRepository();
      final coverage = CoverageController(repository: repository)..load();
      final home = await _pumpHome(
        tester,
        network: network,
        coverage: coverage,
        now: () => DateTime(2026, 11, 7, 10, 0),
      );

      await activateDanger(tester);
      // Ainda lendo as faixas: o alerta aguarda e nada saiu.
      expect(find.byType(AlertPage), findsNothing);
      expect(home.actions.calls, isEmpty);

      repository.finish([
        CoverageRule(
          id: '1',
          contactId: network.contacts[1].id,
          start: 8 * 60,
          end: 13 * 60,
        ),
      ]);
      await tester.pump(_short);

      // Carregou: liga para o contato da faixa, e não para o primeiro da lista.
      expect(_phones(home.actions, AlertActionKind.call), ['51999990002']);
    });
  });
}
