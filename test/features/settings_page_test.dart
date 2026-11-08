// Testa a tela Configurações: o menu, a chave do modo de demonstração e o
// "Apagar meus dados". Nada aqui envia SMS, liga ou depende do aparelho.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';
import 'package:ada_app/features/settings/pages/settings_page.dart';

const _short = Duration(milliseconds: 300);

// Tudo o que os testes precisam para conferir depois.
class _Setup {
  _Setup({
    required this.mode,
    required this.alert,
    required this.contacts,
    required this.messages,
    required this.coverage,
    required this.contactsRepo,
  });

  final ModeController mode;
  final AlertController alert;
  final ContactsController contacts;
  final MessagesController messages;
  final CoverageController coverage;
  final InMemoryContactsRepository contactsRepo;
}

// Monta as Configurações com dados já guardados: 2 contatos, 1 faixa e uma
// mensagem editada.
Future<_Setup> _pump(WidgetTester tester) async {
  // Tela alta: o último item do menu cabe sem rolar.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = FakeLocationService(
    const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
  );
  final contactsRepo = InMemoryContactsRepository(const [
    Contact(id: 'm', name: 'Maria', phone: '51999990001'),
    Contact(id: 'a', name: 'Ana', phone: '51999990002'),
  ]);
  final setup = _Setup(
    mode: ModeController(),
    alert: AlertController(
      locationService: service,
      actions: FakeAlertActions(),
    ),
    contacts: ContactsController(repository: contactsRepo),
    messages: MessagesController(
      repository: InMemoryMessagesRepository({
        MessageKind.danger: 'Texto meu.',
      }),
    ),
    coverage: CoverageController(
      repository: InMemoryCoverageRepository(const [
        CoverageRule(id: 'r', contactId: 'm', start: 480, end: 780),
      ]),
    ),
    contactsRepo: contactsRepo,
  );
  final location = LocationController(service: service);
  await Future.wait([
    setup.contacts.load(),
    setup.messages.load(),
    setup.coverage.load(),
  ]);
  for (final c in [
    setup.mode,
    setup.alert,
    setup.contacts,
    setup.messages,
    setup.coverage,
    location,
  ]) {
    addTearDown(c.dispose);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: setup.mode),
        ChangeNotifierProvider.value(value: setup.alert),
        ChangeNotifierProvider.value(value: setup.contacts),
        ChangeNotifierProvider.value(value: setup.messages),
        ChangeNotifierProvider.value(value: setup.coverage),
        ChangeNotifierProvider.value(value: location),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
    ),
  );
  return setup;
}

void main() {
  testWidgets('Configurações mostra os itens do menu', (tester) async {
    await _pump(tester);

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Horário de cobertura'), findsOneWidget);
    // Não existe histórico de alertas: o ADA não guarda que um alerta foi enviado.
    expect(find.text('Histórico de alertas'), findsNothing);
    expect(find.text('Mensagens personalizadas'), findsOneWidget);
    expect(find.text('Modo de demonstração'), findsOneWidget);
    expect(find.text('Apagar meus dados'), findsOneWidget);
  });

  testWidgets('A chave do modo de demonstração liga e desliga', (tester) async {
    final setup = await _pump(tester);

    // Começa desligado.
    expect(setup.alert.demoMode, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(setup.alert.demoMode, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(setup.alert.demoMode, isFalse);
  });

  group('Apagar meus dados', () {
    testWidgets('pergunta antes, com um texto claro, e nada é apagado ainda', (
      tester,
    ) async {
      final setup = await _pump(tester);

      await tester.tap(find.text('Apagar meus dados'));
      await tester.pump(_short);

      expect(find.text('Apagar todos os dados?'), findsOneWidget);
      expect(find.textContaining('Não dá para desfazer'), findsOneWidget);
      expect(setup.contacts.contacts.length, 2);
      expect(setup.coverage.rules.length, 1);
    });

    testWidgets('"Cancelar" não apaga nada', (tester) async {
      final setup = await _pump(tester);

      await tester.tap(find.text('Apagar meus dados'));
      await tester.pump(_short);
      await tester.tap(find.text('Cancelar'));
      await tester.pump(_short);

      expect(find.text('Apagar todos os dados?'), findsNothing);
      expect(setup.contacts.contacts.length, 2);
      expect(setup.coverage.rules.length, 1);
      expect(setup.messages.textOf(MessageKind.danger), 'Texto meu.');
      expect(find.text('Seus dados foram apagados.'), findsNothing);
    });

    testWidgets('"Apagar tudo" apaga, avisa e desfaz o modo', (tester) async {
      final setup = await _pump(tester);
      setup.mode.activate(SecurityMode.attention);

      await tester.tap(find.text('Apagar meus dados'));
      await tester.pump(_short);
      await tester.tap(find.text('Apagar tudo'));
      await tester.pump(_short);

      expect(setup.contacts.contacts, isEmpty);
      expect(setup.coverage.rules, isEmpty);
      expect(
        setup.messages.textOf(MessageKind.danger),
        MessageKind.danger.defaultText,
      );
      expect(setup.mode.mode, SecurityMode.normal);
      expect(find.text('Seus dados foram apagados.'), findsOneWidget);
      // E o armazenamento também ficou vazio.
      expect(await setup.contactsRepo.load(), isEmpty);
    });
  });
}
