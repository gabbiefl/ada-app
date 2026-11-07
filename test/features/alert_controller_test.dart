// Testa o fluxo do alerta sem enviar SMS nem ligar: localização e ações falsas.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// Deixa a primeira mensagem de SMS esperando o teste liberar, para simular um
// alerta "no meio do caminho".
class _GatedActions extends FakeAlertActions {
  final gate = Completer<void>();

  @override
  Future<ActionResult> sendSms(String phone, String text) async {
    await gate.future;
    return super.sendSms(phone, text);
  }
}

// Ações que lançam erro, para provar que o alerta não para por uma surpresa.
class _ThrowingActions extends FakeAlertActions {
  @override
  Future<bool> requestPermissions() async => throw StateError('boom');

  @override
  Future<ActionResult> sendSms(String phone, String text) async =>
      throw StateError('boom');
}

void main() {
  const maria = Contact(id: '1', name: 'Maria', phone: '51999990001');
  const ana = Contact(id: '2', name: 'Ana', phone: '51999990002');
  const bia = Contact(id: '3', name: 'Bia', phone: '51999990003');
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);
  const message = 'Preciso de ajuda.';

  late FakeLocationService location;
  late FakeAlertActions actions;
  late AlertController controller;

  AlertController build({bool demoMode = false}) => AlertController(
    locationService: location,
    actions: actions,
    demoMode: demoMode,
  );

  setUp(() {
    location = FakeLocationService(const LocationResult.success(porto));
    actions = FakeAlertActions();
    controller = build();
  });

  Future<void> startDanger([
    List<Contact> contacts = const [maria, ana, bia],
  ]) => controller.start(
    kind: MessageKind.danger,
    contacts: contacts,
    message: message,
  );

  List<String> phonesOf(AlertActionKind kind) => [
    for (final c in actions.calls)
      if (c.kind == kind) c.phone,
  ];

  group('Perigo', () {
    test('SMS para os outros contatos e ligação para o primeiro', () async {
      await startDanger();

      expect(phonesOf(AlertActionKind.sendSms), ['51999990002', '51999990003']);
      expect(phonesOf(AlertActionKind.call), ['51999990001']);
      expect(controller.phase, AlertPhase.done);
    });

    test('os SMS saem ANTES da ligação (ela toma a tela)', () async {
      await startDanger();

      expect(actions.calls.map((c) => c.kind), [
        AlertActionKind.sendSms,
        AlertActionKind.sendSms,
        AlertActionKind.call,
      ]);
    });

    test('o SMS leva a mensagem e o link da localização', () async {
      await startDanger();

      final text = actions.calls.first.text!;
      expect(text, startsWith(message));
      expect(
        text,
        contains('https://maps.google.com/?q=-30.034600,-51.217700'),
      );
      expect(controller.text, text);
      expect(controller.location, porto);
    });

    test('cada contato fica com o resultado da sua ação', () async {
      await startDanger();

      final byName = {for (final d in controller.deliveries) d.contact.name: d};
      expect(byName['Ana']!.action, DeliveryAction.sms);
      expect(byName['Bia']!.action, DeliveryAction.sms);
      expect(byName['Maria']!.action, DeliveryAction.call);
      expect(
        controller.deliveries.every((d) => d.status == DeliveryStatus.sent),
        isTrue,
      );
    });

    test('com um único contato, ele recebe o SMS e a ligação', () async {
      await startDanger([maria]);

      expect(phonesOf(AlertActionKind.sendSms), ['51999990001']);
      expect(phonesOf(AlertActionKind.call), ['51999990001']);
    });
  });

  group('Atenção e outras mensagens', () {
    test('Atenção: SMS para todos e nenhuma ligação', () async {
      await controller.start(
        kind: MessageKind.attention,
        contacts: [maria, ana, bia],
        message: 'Estou insegura.',
      );

      expect(phonesOf(AlertActionKind.sendSms).length, 3);
      expect(actions.count(AlertActionKind.call), 0);
      expect(controller.phase, AlertPhase.done);
    });

    test('"Cheguei bem" também só manda SMS', () async {
      await controller.start(
        kind: MessageKind.arrived,
        contacts: [maria, ana],
        message: 'Cheguei.',
      );

      expect(actions.count(AlertActionKind.sendSms), 2);
      expect(actions.count(AlertActionKind.call), 0);
    });
  });

  group('Sem contatos', () {
    test('termina sem enviar, sem ligar e sem buscar a localização', () async {
      await startDanger([]);

      expect(controller.phase, AlertPhase.done);
      expect(controller.hasNoContacts, isTrue);
      expect(actions.calls, isEmpty);
      expect(location.requests, 0);
    });
  });

  group('Localização', () {
    test('sem localização o alerta sai mesmo assim, avisando', () async {
      location.result = const LocationResult.failure(LocationFailure.timeout);

      await startDanger();

      final text = actions.calls.first.text!;
      expect(text, contains('Não consegui compartilhar a minha localização.'));
      expect(text, isNot(contains('http')));
      expect(controller.location, isNull);
      expect(controller.locationFailure, LocationFailure.timeout);
      expect(actions.count(AlertActionKind.call), 1);
    });
  });

  group('Falhas', () {
    test('um SMS que falha não impede os outros', () async {
      actions.results[AlertActionKind.sendSms] = const ActionResult.failure(
        ActionFailure.permissionDenied,
      );

      await startDanger();

      expect(actions.count(AlertActionKind.sendSms), 2); // tentou os dois
      final sms = controller.deliveries.where(
        (d) => d.action == DeliveryAction.sms,
      );
      expect(sms.every((d) => d.status == DeliveryStatus.failed), isTrue);
      expect(
        sms.every((d) => d.failure == ActionFailure.permissionDenied),
        isTrue,
      );
      // A ligação continua mesmo assim.
      expect(actions.count(AlertActionKind.call), 1);
    });

    test('ligação direta negada abre o discador (plano B)', () async {
      actions.results[AlertActionKind.call] = const ActionResult.failure(
        ActionFailure.permissionDenied,
      );

      await startDanger();

      expect(phonesOf(AlertActionKind.openDialer), ['51999990001']);
      final call = controller.deliveries.firstWhere(
        (d) => d.action == DeliveryAction.call,
      );
      expect(call.status, DeliveryStatus.sent);
      expect(call.viaFallback, isTrue);
    });

    test('se nem o discador abrir, a ligação fica como falha', () async {
      actions.results[AlertActionKind.call] = const ActionResult.failure(
        ActionFailure.notAvailable,
      );
      actions.results[AlertActionKind.openDialer] = const ActionResult.failure(
        ActionFailure.notAvailable,
      );

      await startDanger();

      final call = controller.deliveries.firstWhere(
        (d) => d.action == DeliveryAction.call,
      );
      expect(call.status, DeliveryStatus.failed);
      expect(call.failure, ActionFailure.notAvailable);
    });

    test('ligação que funciona não abre o discador', () async {
      await startDanger();

      expect(actions.count(AlertActionKind.openDialer), 0);
    });

    test('exceção inesperada vira falha e o alerta termina', () async {
      final throwing = _ThrowingActions();
      controller = AlertController(
        locationService: location,
        actions: throwing,
      );

      await startDanger();

      expect(controller.phase, AlertPhase.done);
      final sms = controller.deliveries.where(
        (d) => d.action == DeliveryAction.sms,
      );
      expect(sms.every((d) => d.status == DeliveryStatus.failed), isTrue);
    });
  });

  group('Permissões', () {
    test('pede as permissões uma vez, antes de enviar', () async {
      await startDanger();

      expect(actions.permissionRequests, 1);
    });

    test(
      'mesmo com a permissão negada o alerta segue (cada ação decide)',
      () async {
        actions.permissionsGranted = false;

        await startDanger();

        expect(controller.phase, AlertPhase.done);
        expect(actions.count(AlertActionKind.sendSms), 2);
      },
    );
  });

  group('Modo de demonstração', () {
    test('não envia, não liga e não pede permissão', () async {
      controller = build(demoMode: true);

      await startDanger();

      expect(actions.calls, isEmpty);
      expect(actions.permissionRequests, 0);
      expect(controller.phase, AlertPhase.done);
    });

    test('marca tudo como enviado e simulado', () async {
      controller = build(demoMode: true);

      await startDanger();

      expect(controller.deliveries.length, 3);
      expect(
        controller.deliveries.every(
          (d) => d.status == DeliveryStatus.sent && d.simulated,
        ),
        isTrue,
      );
    });

    test('ainda monta o texto com a localização, para a prévia', () async {
      controller = build(demoMode: true);

      await startDanger();

      expect(controller.text, contains('maps.google.com'));
    });

    test('ligar e desligar o modo avisa quem ouve só se mudar', () {
      var avisos = 0;
      controller.addListener(() => avisos++);

      controller.demoMode = true;
      controller.demoMode = true;

      expect(avisos, 1);
      expect(controller.demoMode, isTrue);
    });
  });

  group('Uma vez por ativação', () {
    test('um segundo start durante o alerta é ignorado', () async {
      await startDanger();
      await startDanger();

      expect(actions.count(AlertActionKind.call), 1);
      expect(actions.count(AlertActionKind.sendSms), 2);
    });

    test('depois de reset, um novo alerta pode sair', () async {
      await startDanger();
      controller.reset();
      await startDanger();

      expect(actions.count(AlertActionKind.call), 2);
    });
  });

  group('reset', () {
    test('apaga tudo e volta ao início', () async {
      await startDanger();

      controller.reset();

      expect(controller.phase, AlertPhase.idle);
      expect(controller.deliveries, isEmpty);
      expect(controller.text, isNull);
      expect(controller.location, isNull);
      expect(controller.kind, isNull);
    });

    test('desativar no meio do alerta PARA os envios que faltam', () async {
      final gated = _GatedActions();
      controller = AlertController(locationService: location, actions: gated);

      final running = startDanger();
      await Future<void>.delayed(Duration.zero);
      controller.reset(); // a usuária desativou o alerta
      gated.gate.complete(); // o primeiro SMS termina
      await running;

      // Nenhum SMS depois do que já estava em andamento, e nenhuma ligação.
      expect(gated.count(AlertActionKind.call), 0);
      expect(gated.count(AlertActionKind.sendSms), lessThanOrEqualTo(1));
      expect(controller.phase, AlertPhase.idle);
    });
  });

  group('Fases e avisos', () {
    test('passa por preparando, enviando e terminou', () async {
      final phases = <AlertPhase>[];
      controller.addListener(() {
        if (phases.isEmpty || phases.last != controller.phase) {
          phases.add(controller.phase);
        }
      });

      await startDanger();

      expect(phases, [
        AlertPhase.preparing,
        AlertPhase.sending,
        AlertPhase.done,
      ]);
    });

    test('fechar a tela durante o alerta não quebra', () async {
      final gated = _GatedActions();
      controller = AlertController(locationService: location, actions: gated);

      final running = startDanger();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      gated.gate.complete();

      await running; // não pode lançar erro por notificar um controlador morto
    });

    test('o toString de uma entrega não revela dados pessoais', () async {
      await startDanger();

      for (final delivery in controller.deliveries) {
        expect(delivery.toString(), isNot(contains('Maria')));
        expect(delivery.toString(), isNot(contains('51999')));
      }
    });
  });

  group('Tentar de novo', () {
    test('refaz só o envio que falhou', () async {
      actions.results[AlertActionKind.sendSms] = const ActionResult.failure(
        ActionFailure.failed,
      );
      await startDanger();
      expect(actions.count(AlertActionKind.sendSms), 2);

      actions.results.remove(AlertActionKind.sendSms); // agora vai funcionar
      await controller.retry(ana);

      expect(actions.count(AlertActionKind.sendSms), 3);
      final byName = {for (final d in controller.deliveries) d.contact.name: d};
      expect(byName['Ana']!.status, DeliveryStatus.sent);
      expect(byName['Bia']!.status, DeliveryStatus.failed); // não foi refeito
    });

    test('quem já foi enviado não é refeito', () async {
      await startDanger();

      await controller.retry(ana);

      expect(actions.count(AlertActionKind.sendSms), 2);
    });

    test('não faz nada enquanto o alerta ainda não terminou', () async {
      await controller.retry(ana);

      expect(actions.calls, isEmpty);
    });
  });

  group('Ações manuais', () {
    test('WhatsApp abre com o texto do alerta', () async {
      await startDanger();

      final result = await controller.openWhatsApp(ana);

      expect(result.isSuccess, isTrue);
      final call = actions.calls.last;
      expect(call.kind, AlertActionKind.openWhatsApp);
      expect(call.phone, '51999990002');
      expect(call.text, controller.text);
    });

    test('compositor de SMS abre com o texto do alerta', () async {
      await startDanger();

      await controller.openSmsComposer(bia);

      final call = actions.calls.last;
      expect(call.kind, AlertActionKind.openSmsComposer);
      expect(call.text, controller.text);
    });

    test('sem texto pronto (alerta não começou), as ações falham', () async {
      final result = await controller.openWhatsApp(ana);

      expect(result.isSuccess, isFalse);
      expect(actions.calls, isEmpty);
    });

    test('ligar para um contato usa a ligação direta', () async {
      await startDanger();
      actions.calls.clear();

      final result = await controller.callContact(ana);

      expect(result.isSuccess, isTrue);
      expect(actions.calls.map((c) => c.kind), [AlertActionKind.call]);
    });

    test('ligar com a direta negada abre o discador', () async {
      await startDanger();
      actions.calls.clear();
      actions.results[AlertActionKind.call] = const ActionResult.failure(
        ActionFailure.permissionDenied,
      );

      final result = await controller.callContact(ana);

      expect(result.isSuccess, isTrue);
      expect(actions.calls.map((c) => c.kind), [
        AlertActionKind.call,
        AlertActionKind.openDialer,
      ]);
    });

    test('no modo de demonstração, ligar não liga de verdade', () async {
      controller = build(demoMode: true);
      await startDanger();

      final result = await controller.callContact(ana);

      expect(result.isSuccess, isTrue);
      expect(actions.calls, isEmpty);
    });

    test('tentar de novo no modo de demonstração continua simulado', () async {
      controller = build(demoMode: true);
      await startDanger();

      await controller.retry(ana); // nada falhou: não faz nada

      expect(actions.calls, isEmpty);
    });
  });
}
