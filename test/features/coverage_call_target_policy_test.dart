// Testa a política que escolhe quem ligar pelo horário, com um relógio falso, e a
// sua ligação com o alerta. Nada aqui liga ou manda SMS de verdade.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/state/coverage_call_target_policy.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// Uma política que conta quantas vezes foi consultada.
class _CountingPolicy implements CallTargetPolicy {
  _CountingPolicy(this.inner);

  final CallTargetPolicy inner;
  int picks = 0;

  @override
  Contact? pick(List<Contact> contacts) {
    picks++;
    return inner.pick(contacts);
  }
}

void main() {
  const gabriela = Contact(id: 'g', name: 'Gabriela', phone: '51999990001');
  const yasmin = Contact(id: 'y', name: 'Yasmin', phone: '51999990002');
  const taina = Contact(id: 't', name: 'Tainá', phone: '51999990004');
  const contacts = [gabriela, yasmin, taina];

  // Faixas: 8:00 às 13:00 Yasmin; 23:00 às 4:00 Tainá.
  late CoverageController coverage;
  late DateTime clock;
  late CoverageCallTargetPolicy policy;

  setUp(() {
    coverage = CoverageController()
      ..add(contactId: 'y', start: 8 * 60, end: 13 * 60)
      ..add(contactId: 't', start: 23 * 60, end: 4 * 60);
    clock = DateTime(2026, 11, 7, 10, 0);
    policy = CoverageCallTargetPolicy(coverage: coverage, now: () => clock);
  });

  group('CoverageCallTargetPolicy', () {
    test('escolhe o contato da faixa que cobre a hora do relógio', () {
      expect(policy.pick(contacts), yasmin);
    });

    test(
      'acompanha o relógio: a mesma política dá outro contato em outra hora',
      () {
        clock = DateTime(2026, 11, 7, 23, 30);
        expect(policy.pick(contacts), taina);

        clock = DateTime(
          2026,
          11,
          8,
          0,
          0,
        ); // meia-noite, ainda a faixa da madrugada
        expect(policy.pick(contacts), taina);

        clock = DateTime(2026, 11, 8, 4, 0); // o fim não conta
        expect(policy.pick(contacts), gabriela);
      },
    );

    test('fora de todas as faixas, o primeiro da lista', () {
      clock = DateTime(2026, 11, 7, 18, 0);

      expect(policy.pick(contacts), gabriela);
    });

    test('lê as faixas na hora: mudar a regra vale na próxima pergunta', () {
      expect(policy.pick(contacts), yasmin);

      final id = coverage.rules.first.id;
      coverage.setEnabled(id, false); // a faixa das 8:00 às 13:00

      expect(policy.pick(contacts), gabriela);
    });

    test('sem contatos, ninguém', () {
      expect(policy.pick(const []), isNull);
    });

    test('sem faixas, o primeiro da lista (o comportamento de antes)', () {
      final empty = CoverageCallTargetPolicy(
        coverage: CoverageController(),
        now: () => clock,
      );

      expect(empty.pick(contacts), gabriela);
    });

    test('sem relógio informado, usa a hora de verdade sem quebrar', () {
      final real = CoverageCallTargetPolicy(coverage: CoverageController());

      expect(real.pick(contacts), gabriela);
    });
  });

  group('com o alerta', () {
    late FakeAlertActions actions;

    AlertController buildAlert(CallTargetPolicy callTarget) => AlertController(
      locationService: FakeLocationService(
        const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
      ),
      actions: actions,
      callTarget: callTarget,
    );

    Future<void> danger(AlertController alert) => alert.start(
      kind: MessageKind.danger,
      contacts: contacts,
      message: 'Preciso de ajuda.',
    );

    String? calledPhone() {
      final calls = actions.calls.where((c) => c.kind == AlertActionKind.call);
      return calls.isEmpty ? null : calls.single.phone;
    }

    setUp(() => actions = FakeAlertActions());

    test(
      'de manhã o Perigo liga para quem a faixa manda e avisa os outros',
      () async {
        await danger(buildAlert(policy));

        expect(calledPhone(), yasmin.phone);
        final sms = actions.calls
            .where((c) => c.kind == AlertActionKind.sendSms)
            .map((c) => c.phone);
        expect(sms, [gabriela.phone, taina.phone]);
      },
    );

    test('de madrugada o Perigo liga para outra pessoa', () async {
      clock = DateTime(2026, 11, 7, 2, 0);

      await danger(buildAlert(policy));

      expect(calledPhone(), taina.phone);
    });

    test('o contato é escolhido UMA vez, no começo do alerta', () async {
      final counting = _CountingPolicy(policy);

      await danger(buildAlert(counting));

      expect(counting.picks, 1);
    });

    test('a Atenção não consulta a política: não liga ninguém', () async {
      final counting = _CountingPolicy(policy);
      final alert = buildAlert(counting);

      await alert.start(
        kind: MessageKind.attention,
        contacts: contacts,
        message: 'Estou insegura.',
      );

      expect(counting.picks, 0);
      expect(calledPhone(), isNull);
    });

    test('a faixa de um contato removido não faz o alerta ligar para ele', () async {
      // Só a Gabriela e a Yasmin continuam na rede; a faixa da madrugada era da
      // Tainá, que foi removida.
      clock = DateTime(2026, 11, 7, 2, 0);
      final alert = buildAlert(policy);

      await alert.start(
        kind: MessageKind.danger,
        contacts: const [gabriela, yasmin],
        message: 'Preciso de ajuda.',
      );

      expect(calledPhone(), gabriela.phone); // volta ao primeiro da lista
    });
  });
}
