// Testa a tela Horário de cobertura com controladores de verdade e relógio falso.
// Nada aqui liga, manda SMS ou usa o relógio do computador.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/pages/coverage_page.dart';
import 'package:ada_app/features/coverage/state/coverage_call_target_policy.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

int at(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

const _short = Duration(milliseconds: 300);
const _names = ['Gabriela', 'Yasmin', 'Milena', 'Tainá', 'Arthur'];

// O que um teste precisa para conferir e mexer depois.
class _Setup {
  _Setup(this.network, this.coverage);

  final ContactsController network;
  final CoverageController coverage;

  String idOf(String name) =>
      network.contacts.firstWhere((c) => c.name == name).id;
}

// As 5 faixas do Figma: 8-13 Gabriela, 13-18 Yasmin, 18-23 Milena, 23-4 Tainá,
// 4-8 Arthur.
void _addFigmaRules(_Setup setup) {
  const chain = [
    ('Gabriela', '8:00', '13:00'),
    ('Yasmin', '13:00', '18:00'),
    ('Milena', '18:00', '23:00'),
    ('Tainá', '23:00', '4:00'),
    ('Arthur', '4:00', '8:00'),
  ];
  for (final (name, start, end) in chain) {
    setup.coverage.add(
      contactId: setup.idOf(name),
      start: at(start),
      end: at(end),
    );
  }
}

// Monta a tela com [contacts] contatos (os primeiros nomes de _names) e o relógio
// em [clock]. Tela alta: a lista cabe sem rolar.
Future<_Setup> _pump(
  WidgetTester tester, {
  int contacts = 5,
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final network = ContactsController();
  for (var i = 0; i < contacts; i++) {
    network.add(name: _names[i], phone: '5199999000${i + 1}');
  }
  final coverage = CoverageController();
  final alert = AlertController(
    locationService: FakeLocationService(
      const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
    ),
    actions: FakeAlertActions(),
    callTarget: CoverageCallTargetPolicy(coverage: coverage, now: clock),
  );
  for (final c in [network, coverage, alert]) {
    addTearDown(c.dispose);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: network),
        ChangeNotifierProvider.value(value: coverage),
        ChangeNotifierProvider.value(value: alert),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const CoveragePage()),
    ),
  );
  return _Setup(network, coverage);
}

void main() {
  testWidgets('mostra o cabeçalho do Figma', (tester) async {
    await _pump(tester);

    expect(find.text('Horário de cobertura'), findsOneWidget);
    expect(
      find.text('Priorize para quem ligar de acordo com o horário.'),
      findsOneWidget,
    );
  });

  testWidgets('sem contatos: explica e não mostra faixas', (tester) async {
    await _pump(tester, contacts: 0);

    expect(find.textContaining('ainda não tem contatos'), findsOneWidget);
    expect(find.textContaining('Cobertura'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  group('com as 5 faixas do Figma', () {
    testWidgets('cobrem as 24 horas, sem buracos', (tester) async {
      final setup = await _pump(tester);
      _addFigmaRules(setup);
      await tester.pump(_short);

      expect(find.text('Cobertura das 24 horas'), findsOneWidget);
      expect(find.textContaining('Sem faixa'), findsNothing);
    });

    testWidgets('listam cada faixa com horário e contato', (tester) async {
      final setup = await _pump(tester);
      _addFigmaRules(setup);
      await tester.pump(_short);

      for (final range in [
        '8:00 - 13:00',
        '13:00 - 18:00',
        '18:00 - 23:00',
        '23:00 - 4:00',
        '4:00 - 8:00',
      ]) {
        expect(find.text(range), findsOneWidget, reason: range);
      }
      expect(
        find.textContaining('Ligar para', findRichText: true),
        findsNWidgets(5),
      );
      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('mostram o ícone de cada período: sol, pôr do sol e lua', (
      tester,
    ) async {
      final setup = await _pump(tester);
      _addFigmaRules(setup);
      await tester.pump(_short);

      expect(find.byIcon(LucideIcons.sun), findsNWidgets(2)); // 8h e 13h
      expect(find.byIcon(LucideIcons.sunset), findsOneWidget); // 18h
      expect(find.byIcon(LucideIcons.moonStar), findsNWidgets(2)); // 23h e 4h
    });
  });

  group('cobertura com buracos', () {
    testWidgets('sem faixas: diz que liga sempre para o primeiro da lista', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Nenhuma faixa criada'), findsOneWidget);
      expect(
        find.text(
          'Sem faixas, o ADA liga sempre para Gabriela (o primeiro da lista).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('desligar uma faixa abre um buraco e o cartão diz qual', (
      tester,
    ) async {
      final setup = await _pump(tester);
      _addFigmaRules(setup);
      await tester.pump(_short);

      // Desliga a 2ª faixa (13:00 às 18:00): fica um buraco de 5 horas.
      await tester.tap(find.byType(Switch).at(1));
      await tester.pump(_short);

      expect(find.text('Cobertura de 19 horas'), findsOneWidget);
      expect(find.textContaining('Sem faixa: 13:00 - 18:00.'), findsOneWidget);
      expect(
        find.textContaining('o ADA liga para Gabriela (o primeiro da lista)'),
        findsOneWidget,
      );
    });

    testWidgets('com todas desligadas: nenhuma faixa ligada', (tester) async {
      final setup = await _pump(tester);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('13:00'),
        enabled: false,
      );
      await tester.pump(_short);

      expect(find.text('Nenhuma faixa ligada'), findsOneWidget);
    });

    testWidgets('um buraco no começo e no fim do dia aparece nos dois', (
      tester,
    ) async {
      final setup = await _pump(tester);
      setup.coverage.add(
        contactId: setup.idOf('Gabriela'),
        start: at('8:00'),
        end: at('18:00'),
      );
      await tester.pump(_short);

      expect(find.text('Cobertura de 10 horas'), findsOneWidget);
      expect(
        find.textContaining('Sem faixa: 0:00 - 8:00, 18:00 - 24:00.'),
        findsOneWidget,
      );
    });
  });

  group('quem seria ligado agora', () {
    testWidgets('é o contato da faixa da hora do relógio', (tester) async {
      final setup = await _pump(
        tester,
        clock: () => DateTime(2026, 11, 7, 15, 0),
      );
      _addFigmaRules(setup);
      await tester.pump(_short);

      expect(find.text('Agora, o ADA ligaria para Yasmin.'), findsOneWidget);
    });

    testWidgets('na madrugada, a faixa que atravessa a meia-noite', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        clock: () => DateTime(2026, 11, 8, 0, 30),
      );
      _addFigmaRules(setup);
      await tester.pump(_short);

      expect(find.text('Agora, o ADA ligaria para Tainá.'), findsOneWidget);
    });

    testWidgets('sem faixa para a hora, é o primeiro da lista', (tester) async {
      await _pump(tester, clock: () => DateTime(2026, 11, 7, 10, 0));

      expect(find.text('Agora, o ADA ligaria para Gabriela.'), findsOneWidget);
    });

    testWidgets('desligar a faixa muda quem seria ligado', (tester) async {
      final setup = await _pump(
        tester,
        clock: () => DateTime(2026, 11, 7, 15, 0),
      );
      _addFigmaRules(setup);
      await tester.pump(_short);
      expect(find.text('Agora, o ADA ligaria para Yasmin.'), findsOneWidget);

      await tester.tap(find.byType(Switch).at(1)); // a faixa da Yasmin
      await tester.pump(_short);

      expect(find.text('Agora, o ADA ligaria para Gabriela.'), findsOneWidget);
    });

    testWidgets('acompanha o relógio quando a hora vira (a cada 30 s)', (
      tester,
    ) async {
      var now = DateTime(2026, 11, 7, 12, 59);
      final setup = await _pump(tester, clock: () => now);
      _addFigmaRules(setup);
      await tester.pump(_short);
      expect(find.text('Agora, o ADA ligaria para Gabriela.'), findsOneWidget);

      now = DateTime(2026, 11, 7, 13, 0); // a faixa da Gabriela acabou
      await tester.pump(const Duration(seconds: 31));

      expect(find.text('Agora, o ADA ligaria para Yasmin.'), findsOneWidget);
    });
  });

  group('chave liga/desliga', () {
    testWidgets('desligar deixa a faixa apagada e salva', (tester) async {
      final setup = await _pump(tester);
      _addFigmaRules(setup);
      await tester.pump(_short);

      await tester.tap(find.byType(Switch).first);
      await tester.pump(_short);

      expect(setup.coverage.rules.first.enabled, isFalse);
      expect(setup.coverage.rules.length, 5); // continua salva
      expect(
        find.textContaining('Desligada', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
      'religar uma faixa que cruzaria é recusado e explica com qual',
      (tester) async {
        final setup = await _pump(tester);
        // A 1ª está desligada; a 2ª entra por cima dela (permitido, pois a 1ª está
        // desligada). Religar a 1ª agora cruzaria com a 2ª.
        setup.coverage.add(
          contactId: setup.idOf('Gabriela'),
          start: at('8:00'),
          end: at('13:00'),
          enabled: false,
        );
        setup.coverage.add(
          contactId: setup.idOf('Yasmin'),
          start: at('9:00'),
          end: at('12:00'),
        );
        await tester.pump(_short);

        await tester.tap(find.byType(Switch).first);
        await tester.pump(_short);

        expect(
          setup.coverage.rules.first.enabled,
          isFalse,
        ); // continua desligada
        expect(
          find.textContaining('Essa faixa cruza com 9:00 - 12:00 (Yasmin)'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('faixa de contato removido não aparece na lista', (tester) async {
    final setup = await _pump(tester);
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
    await tester.pump(_short);
    expect(find.byType(Switch), findsNWidgets(2));

    setup.network.remove(setup.idOf('Yasmin')); // a faixa dela vira órfã
    await tester.pump(_short);

    // Aqui não há o ouvinte do app que apaga as órfãs: a tela só as esconde.
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('13:00 - 18:00'), findsNothing);
  });
}
