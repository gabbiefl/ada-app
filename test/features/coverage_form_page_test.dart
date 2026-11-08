// Testa o formulário de faixa (criar, editar e remover) dentro da tela de
// cobertura de verdade. O seletor de horas é trocado por um falso, que devolve
// os horários combinados (o relógio do Material é difícil de operar num teste).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/pages/coverage_form_page.dart';
import 'package:ada_app/features/coverage/pages/coverage_page.dart';
import 'package:ada_app/features/coverage/state/coverage_call_target_policy.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

const _short = Duration(milliseconds: 600);

int at(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

TimeOfDay time(String hhmm) {
  final minutes = at(hhmm);
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

// Seletor falso: devolve as respostas combinadas, na ordem, e anota o horário
// inicial que a tela sugeriu em cada pedido. `null` = a usuária cancelou.
class _Picker {
  _Picker(this.answers);

  final List<TimeOfDay?> answers;
  final List<TimeOfDay> suggested = [];

  Future<TimeOfDay?> call(BuildContext context, TimeOfDay initial) async {
    suggested.add(initial);
    return answers.removeAt(0);
  }
}

class _Setup {
  _Setup(this.network, this.coverage, this.router);

  final ContactsController network;
  final CoverageController coverage;
  final GoRouter router;

  String idOf(String name) =>
      network.contacts.firstWhere((c) => c.name == name).id;
}

// Monta a tela de cobertura (na raiz) com as rotas do formulário. Os contatos
// são Gabriela, Yasmin e Milena.
Future<_Setup> _pump(WidgetTester tester, {_Picker? picker}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final network = ContactsController();
  for (final (i, name) in ['Gabriela', 'Yasmin', 'Milena'].indexed) {
    network.add(name: name, phone: '5199999000${i + 1}');
  }
  final coverage = CoverageController(
    contactExists: (id) => network.byId(id) != null,
  );
  final alert = AlertController(
    locationService: FakeLocationService(
      const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
    ),
    actions: FakeAlertActions(),
    callTarget: CoverageCallTargetPolicy(
      coverage: coverage,
      now: () => DateTime(2026, 11, 8, 10, 0),
    ),
  );
  for (final c in [network, coverage, alert]) {
    addTearDown(c.dispose);
  }

  final fake = picker ?? _Picker([]);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CoveragePage()),
      GoRoute(
        path: AppRoutes.newCoverage,
        builder: (_, _) => CoverageFormPage(pickTime: fake.call),
      ),
      GoRoute(
        path: '/settings/coverage/edit/:id',
        builder: (_, state) => CoverageFormPage(
          ruleId: state.pathParameters['id'],
          pickTime: fake.call,
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: network),
        ChangeNotifierProvider.value(value: coverage),
        ChangeNotifierProvider.value(value: alert),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return _Setup(network, coverage, router);
}

// Escolhe um contato no seletor da tela.
Future<void> _chooseContact(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pump(_short);
  await tester.tap(find.text(name).last);
  await tester.pump(_short);
}

Future<void> _openNew(WidgetTester tester) async {
  await tester.tap(find.text('Adicionar faixa'));
  await tester.pump(_short);
}

void main() {
  group('abrir o formulário a partir da tela', () {
    testWidgets('"Adicionar faixa" abre a tela de nova faixa', (tester) async {
      await _pump(tester);

      await _openNew(tester);

      expect(find.text('Nova faixa'), findsOneWidget);
      expect(find.text('Escolher'), findsNWidgets(2)); // início e fim vazios
      expect(find.text('Escolha o contato'), findsOneWidget);
      expect(find.text('Remover faixa'), findsNothing); // só ao editar
    });

    testWidgets('tocar numa faixa da lista abre a edição dela', (tester) async {
      final setup = await _pump(tester);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('13:00'),
      );
      await tester.pump(_short);

      await tester.tap(find.text('8:00 - 13:00'));
      await tester.pump(_short);

      expect(find.text('Editar faixa'), findsOneWidget);
    });

    testWidgets('"Cancelar" volta à lista sem salvar nada', (tester) async {
      final setup = await _pump(tester);
      await _openNew(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pump(_short);

      expect(find.text('Nova faixa'), findsNothing);
      expect(setup.coverage.rules, isEmpty);
    });
  });

  group('criar uma faixa', () {
    testWidgets('salvar sem preencher mostra o que falta e não salva', (
      tester,
    ) async {
      final setup = await _pump(tester);
      await _openNew(tester);

      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(find.text('Escolha quem será ligado.'), findsOneWidget);
      expect(find.text('Escolha o horário de início.'), findsOneWidget);
      expect(find.text('Escolha o horário de fim.'), findsOneWidget);
      expect(setup.coverage.rules, isEmpty);
      expect(find.text('Nova faixa'), findsOneWidget); // ficou na tela
    });

    testWidgets('contato, início e fim: salva e a lista mostra a faixa', (
      tester,
    ) async {
      final picker = _Picker([time('8:00'), time('13:00')]);
      final setup = await _pump(tester, picker: picker);
      await _openNew(tester);

      await _chooseContact(tester, 'Yasmin');
      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      final rule = setup.coverage.rules.single;
      expect(rule.contactId, setup.idOf('Yasmin'));
      expect(rule.start, at('8:00'));
      expect(rule.end, at('13:00'));
      expect(rule.enabled, isTrue);
      // De volta à lista, com a faixa nova.
      expect(find.text('Nova faixa'), findsNothing);
      expect(find.text('8:00 - 13:00'), findsOneWidget);
    });

    testWidgets('sugere 8:00 para o início e uma hora depois para o fim', (
      tester,
    ) async {
      final picker = _Picker([time('9:30'), time('12:00')]);
      await _pump(tester, picker: picker);
      await _openNew(tester);

      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);

      expect(picker.suggested, [time('8:00'), time('10:30')]);
    });

    testWidgets('ao reabrir o seletor, sugere o horário já escolhido', (
      tester,
    ) async {
      final picker = _Picker([time('9:30'), time('9:45')]);
      await _pump(tester, picker: picker);
      await _openNew(tester);

      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.text('9:30'));
      await tester.pump(_short);

      expect(picker.suggested.last, time('9:30'));
      expect(find.text('9:45'), findsOneWidget);
    });

    testWidgets('se a usuária cancela o seletor, o campo não muda', (
      tester,
    ) async {
      final picker = _Picker([null]);
      await _pump(tester, picker: picker);
      await _openNew(tester);

      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);

      expect(find.text('Escolher'), findsNWidgets(2));
    });

    testWidgets('o erro de um campo some quando ela escolhe o horário', (
      tester,
    ) async {
      final picker = _Picker([time('8:00')]);
      await _pump(tester, picker: picker);
      await _openNew(tester);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);
      expect(find.text('Escolha o horário de início.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);

      expect(find.text('Escolha o horário de início.'), findsNothing);
    });

    testWidgets('início igual ao fim é recusado com explicação', (
      tester,
    ) async {
      final picker = _Picker([time('8:00'), time('8:00')]);
      final setup = await _pump(tester, picker: picker);
      await _openNew(tester);

      await _chooseContact(tester, 'Gabriela');
      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(
        find.text('O fim precisa ser diferente do início.'),
        findsOneWidget,
      );
      expect(setup.coverage.rules, isEmpty);
    });

    testWidgets('faixa que atravessa a meia-noite é explicada e aceita', (
      tester,
    ) async {
      final picker = _Picker([time('23:00'), time('4:00')]);
      final setup = await _pump(tester, picker: picker);
      await _openNew(tester);

      await _chooseContact(tester, 'Milena');
      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);

      expect(
        find.textContaining('passa da meia-noite: vale das 23:00 até as 4:00'),
        findsOneWidget,
      );

      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(setup.coverage.rules.single.start, at('23:00'));
      expect(setup.coverage.rules.single.end, at('4:00'));
    });

    testWidgets('faixa que cruza com outra é recusada e diz com qual', (
      tester,
    ) async {
      final picker = _Picker([time('12:00'), time('14:00')]);
      final setup = await _pump(tester, picker: picker);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('13:00'),
      );
      await tester.pump(_short);
      await _openNew(tester);

      await _chooseContact(tester, 'Yasmin');
      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(
        find.textContaining('Esse horário cruza com 8:00 - 13:00 (Gabriela)'),
        findsOneWidget,
      );
      expect(setup.coverage.rules.length, 1); // nada foi salvo
      expect(find.text('Nova faixa'), findsOneWidget);
    });

    testWidgets('faixas coladas são aceitas', (tester) async {
      final picker = _Picker([time('13:00'), time('18:00')]);
      final setup = await _pump(tester, picker: picker);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('13:00'),
      );
      await tester.pump(_short);
      await _openNew(tester);

      await _chooseContact(tester, 'Yasmin');
      await tester.tap(find.byKey(const Key('time-field-Início')));
      await tester.pump(_short);
      await tester.tap(find.byKey(const Key('time-field-Fim')));
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(setup.coverage.rules.length, 2);
    });
  });

  group('editar uma faixa', () {
    late _Setup setup;
    late _Picker picker;
    late String id;

    // Uma faixa da Gabriela das 8:00 às 13:00 e outra da Yasmin das 13:00 às 18:00,
    // com a edição da primeira já aberta.
    Future<void> openEditing(
      WidgetTester tester,
      List<TimeOfDay?> picks,
    ) async {
      picker = _Picker(picks);
      setup = await _pump(tester, picker: picker);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('13:00'),
      );
      setup.coverage.add(
        contactId: setup.idOf('Yasmin'),
        start: at('13:00'),
        end: at('18:00'),
      );
      id = setup.coverage.rules.first.id;
      await tester.pump(_short);
      await tester.tap(find.text('8:00 - 13:00'));
      await tester.pump(_short);
    }

    testWidgets('abre já preenchida, com o botão de remover', (tester) async {
      await openEditing(tester, []);

      expect(find.text('Editar faixa'), findsOneWidget);
      expect(find.text('8:00'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('Gabriela'), findsWidgets);
      expect(find.text('Remover faixa'), findsOneWidget);
    });

    testWidgets('mudar o horário e salvar atualiza a faixa e a lista', (
      tester,
    ) async {
      await openEditing(tester, [time('12:00')]);

      await tester.tap(find.text('13:00')); // o campo "Fim"
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(setup.coverage.byId(id)!.end, at('12:00'));
      expect(setup.coverage.byId(id)!.contactId, setup.idOf('Gabriela'));
      expect(find.text('Editar faixa'), findsNothing);
      expect(find.text('8:00 - 12:00'), findsOneWidget);
    });

    testWidgets('trocar o contato mantém o horário', (tester) async {
      await openEditing(tester, []);

      await _chooseContact(tester, 'Milena');
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(setup.coverage.byId(id)!.contactId, setup.idOf('Milena'));
      expect(setup.coverage.byId(id)!.start, at('8:00'));
    });

    testWidgets('a faixa pode manter o próprio horário (não cruza consigo)', (
      tester,
    ) async {
      await openEditing(tester, []);

      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(find.text('Editar faixa'), findsNothing); // salvou e voltou
    });

    testWidgets('esticar o fim para dentro da vizinha é recusado', (
      tester,
    ) async {
      await openEditing(tester, [time('14:00')]);

      await tester.tap(find.text('13:00'));
      await tester.pump(_short);
      await tester.tap(find.text('Salvar faixa'));
      await tester.pump(_short);

      expect(
        find.textContaining('Esse horário cruza com 13:00 - 18:00 (Yasmin)'),
        findsOneWidget,
      );
      expect(setup.coverage.byId(id)!.end, at('13:00')); // não mudou
    });

    testWidgets('remover pergunta antes e "Cancelar" mantém a faixa', (
      tester,
    ) async {
      await openEditing(tester, []);

      await tester.tap(find.text('Remover faixa'));
      await tester.pump(_short);
      expect(find.text('Remover a faixa?'), findsOneWidget);

      await tester.tap(find.text('Cancelar').last);
      await tester.pump(_short);

      expect(setup.coverage.rules.length, 2);
      expect(find.text('Editar faixa'), findsOneWidget); // continua na tela
    });

    testWidgets('confirmar remove a faixa, volta à lista e libera o horário', (
      tester,
    ) async {
      await openEditing(tester, []);

      await tester.tap(find.text('Remover faixa'));
      await tester.pump(_short);
      await tester.tap(find.text('Remover'));
      await tester.pump(_short);

      expect(setup.coverage.byId(id), isNull);
      expect(setup.coverage.rules.length, 1);
      expect(find.text('Editar faixa'), findsNothing);
      expect(find.text('8:00 - 13:00'), findsNothing);
    });
  });

  testWidgets('editar uma faixa que não existe mais avisa e volta', (
    tester,
  ) async {
    final setup = await _pump(tester);

    setup.router.push('/settings/coverage/edit/fantasma');
    await tester.pump(_short);

    expect(find.text('Faixa não encontrada'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pump(_short);

    expect(find.text('Faixa não encontrada'), findsNothing);
  });
}
