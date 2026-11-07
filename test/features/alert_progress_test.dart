// Testa os cartões de progresso do alerta (título, detalhe e estado de cada
// etapa), sem desenhar nenhuma tela.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/alerts/state/alert_progress.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// Localização que só responde quando o teste mandar.
class _SlowLocation implements LocationService {
  final completer = Completer<LocationResult>();

  @override
  Future<LocationResult> current() => completer.future;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  const maria = Contact(id: '1', name: 'Maria', phone: '51999990001');
  const ana = Contact(id: '2', name: 'Ana', phone: '51999990002');
  const bia = Contact(id: '3', name: 'Bia', phone: '51999990003');
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

  late FakeLocationService location;
  late FakeAlertActions actions;
  late AlertController controller;

  setUp(() {
    location = FakeLocationService(const LocationResult.success(porto));
    actions = FakeAlertActions();
    controller = AlertController(locationService: location, actions: actions);
  });

  Future<void> danger([List<Contact> contacts = const [maria, ana, bia]]) =>
      controller.start(
        kind: MessageKind.danger,
        contacts: contacts,
        message: 'Socorro.',
      );

  test('sem alerta, não há cartões', () {
    expect(buildProgressSteps(controller), isEmpty);
  });

  test('sem contatos, não há cartões (a tela explica a rede vazia)', () async {
    await danger([]);

    expect(buildProgressSteps(controller), isEmpty);
  });

  test(
    'Perigo concluído: localização, mensagens e ligação, nesta ordem',
    () async {
      await danger();

      final steps = buildProgressSteps(controller);

      expect(steps.map((s) => s.title), [
        'Localização compartilhada',
        'Mensagens enviadas',
        'Ligando para Maria',
      ]);
      expect(steps.every((s) => s.state == ProgressState.done), isTrue);
      expect(steps[1].detail, '2 de 2 enviadas');
      expect(steps[2].detail, 'Ligação iniciada');
    },
  );

  test('Atenção não tem a etapa de ligação', () async {
    await controller.start(
      kind: MessageKind.attention,
      contacts: [maria, ana],
      message: 'Oi.',
    );

    final steps = buildProgressSteps(controller);

    expect(steps.length, 2);
    expect(steps.map((s) => s.title), contains('Mensagens enviadas'));
    expect(steps.any((s) => s.title.contains('Ligando')), isFalse);
  });

  test(
    'buscando a localização: ela gira e as outras etapas aguardam',
    () async {
      final slow = _SlowLocation();
      controller = AlertController(locationService: slow, actions: actions);

      final running = danger();
      final steps = buildProgressSteps(controller);

      expect(steps[0].state, ProgressState.loading);
      expect(steps[0].title, 'Compartilhando localização');
      expect(steps[1].state, ProgressState.pending);
      expect(steps[1].detail, 'Aguardando a localização…');
      expect(steps[2].state, ProgressState.pending);
      expect(steps[2].title, 'Ligar para Maria');

      slow.completer.complete(const LocationResult.success(porto));
      await running;
    },
  );

  test('sem localização: etapa com ressalva, e as mensagens saem', () async {
    location.result = const LocationResult.failure(LocationFailure.timeout);

    await danger();

    final steps = buildProgressSteps(controller);
    expect(steps[0].state, ProgressState.warning);
    expect(steps[0].title, 'Localização indisponível');
    expect(steps[1].state, ProgressState.done);
  });

  test('algumas mensagens falharam: ressalva; todas falharam: falha', () async {
    // Nenhum SMS saiu.
    actions.results[AlertActionKind.sendSms] = const ActionResult.failure(
      ActionFailure.failed,
    );
    await danger();

    var messages = buildProgressSteps(controller)[1];
    expect(messages.state, ProgressState.failed);
    expect(messages.title, 'Algumas mensagens falharam');
    expect(messages.detail, '0 de 2 enviadas. Veja os detalhes abaixo.');

    // Agora uma sai e a outra não: o primeiro SMS funciona, o segundo falha.
    controller.reset();
    actions.results.remove(AlertActionKind.sendSms);
    final flaky = _FlakyActions();
    controller = AlertController(locationService: location, actions: flaky);
    await danger();

    messages = buildProgressSteps(controller)[1];
    expect(messages.state, ProgressState.warning);
    expect(messages.detail, '1 de 2 enviadas. Veja os detalhes abaixo.');
  });

  test('ligação pelo discador (plano B) e ligação que falhou', () async {
    actions.results[AlertActionKind.call] = const ActionResult.failure(
      ActionFailure.permissionDenied,
    );
    await danger();

    var call = buildProgressSteps(controller)[2];
    expect(call.state, ProgressState.done);
    expect(call.detail, 'Discador aberto');

    // Agora nem o discador abre.
    controller.reset();
    actions.results[AlertActionKind.openDialer] = const ActionResult.failure(
      ActionFailure.notAvailable,
    );
    await danger();

    call = buildProgressSteps(controller)[2];
    expect(call.state, ProgressState.failed);
    expect(call.title, 'Não foi possível ligar para Maria');
    expect(call.detail, 'Sem permissão para ligar');
  });

  test('modo de demonstração deixa claro que é simulado', () async {
    controller = AlertController(
      locationService: location,
      actions: actions,
      demoMode: true,
    );

    await danger();

    final steps = buildProgressSteps(controller);
    expect(steps[1].detail, '2 de 2 enviadas (simulado)');
    expect(steps[2].detail, 'Ligação simulada');
  });
}

// Faz o primeiro SMS funcionar e os seguintes falharem.
class _FlakyActions extends FakeAlertActions {
  int _sms = 0;

  @override
  Future<ActionResult> sendSms(String phone, String text) async {
    _sms++;
    await super.sendSms(phone, text);
    return _sms == 1
        ? const ActionResult.success()
        : const ActionResult.failure(ActionFailure.failed);
  }
}
