// Testa o "Apagar meus dados" (RF10): os controladores, a função que apaga tudo
// em ordem e o que sobra no armazenamento. Nada aqui envia SMS ou liga.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
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
import 'package:ada_app/features/settings/utils/erase_all_data.dart';

// Deixa o primeiro SMS esperando o teste liberar, para simular um alerta "no meio".
class _GatedActions extends FakeAlertActions {
  final gate = Completer<void>();

  @override
  Future<ActionResult> sendSms(String phone, String text) async {
    await gate.future;
    return super.sendSms(phone, text);
  }
}

// Repositório de contatos que falha ao LER (como se o armazenamento estivesse
// indisponível ao abrir o app), mas guarda o que for gravado.
class _UnreadableContactsRepository implements ContactsRepository {
  List<Contact> stored;

  _UnreadableContactsRepository(this.stored);

  @override
  Future<List<Contact>> load() async => throw Exception('ilegível');

  @override
  Future<void> save(List<Contact> contacts) async => stored = contacts;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  const maria = Contact(id: 'm', name: 'Maria', phone: '51999990001');
  const ana = Contact(id: 'a', name: 'Ana', phone: '51999990002');
  const rule = CoverageRule(id: 'r', contactId: 'm', start: 480, end: 780);
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

  group('clear dos controladores', () {
    test('contatos: apaga da tela e do armazenamento', () async {
      final repository = InMemoryContactsRepository([maria, ana]);
      final controller = ContactsController(repository: repository);
      await controller.load();

      await controller.clear();

      expect(controller.contacts, isEmpty);
      expect(await repository.load(), isEmpty);
    });

    test('contatos: avisa as telas', () async {
      final controller = ContactsController()
        ..add(name: 'Maria', phone: '51999990001');
      var avisos = 0;
      controller.addListener(() => avisos++);

      await controller.clear();

      expect(avisos, 1);
    });

    test(
      'contatos: grava o vazio mesmo se a leitura falhou ao abrir o app',
      () async {
        // A lista está vazia em memória (a leitura falhou), mas há contatos
        // guardados: "apagar tudo" precisa apagar esses também.
        final repository = _UnreadableContactsRepository([maria, ana]);
        final controller = ContactsController(repository: repository);
        await controller.load();
        expect(controller.contacts, isEmpty);

        await controller.clear();

        expect(repository.stored, isEmpty);
      },
    );

    test(
      'mensagens: voltam todas ao texto padrão, na tela e no armazenamento',
      () async {
        final repository = InMemoryMessagesRepository({
          MessageKind.danger: 'Texto meu.',
          MessageKind.arrived: 'Cheguei!',
        });
        final controller = MessagesController(repository: repository);
        await controller.load();

        await controller.resetAll();

        for (final kind in MessageKind.values) {
          expect(controller.textOf(kind), kind.defaultText);
          expect(controller.isCustomized(kind), isFalse);
        }
        expect(await repository.load(), isEmpty);
      },
    );

    test('faixas: apaga da tela e do armazenamento', () async {
      final repository = InMemoryCoverageRepository([rule]);
      final controller = CoverageController(repository: repository);
      await controller.load();

      await controller.clear();

      expect(controller.rules, isEmpty);
      expect(await repository.load(), isEmpty);
    });

    test('clear completa só depois de gravar (dá para esperar)', () async {
      final repository = InMemoryCoverageRepository([rule]);
      final controller = CoverageController(repository: repository);
      await controller.load();

      final done = controller.clear();
      // Sem settle(): se clear() não esperasse a gravação, o repositório ainda
      // teria a faixa aqui.
      await done;

      expect(await repository.load(), isEmpty);
    });
  });

  group('eraseAllData', () {
    late ModeController mode;
    late AlertController alert;
    late ContactsController contacts;
    late MessagesController messages;
    late CoverageController coverage;
    late LocationController location;
    late FakeAlertActions actions;
    late InMemoryContactsRepository contactsRepo;
    late InMemoryMessagesRepository messagesRepo;
    late InMemoryCoverageRepository coverageRepo;

    Future<void> setUpAll({FakeAlertActions? withActions}) async {
      actions = withActions ?? FakeAlertActions();
      contactsRepo = InMemoryContactsRepository([maria, ana]);
      messagesRepo = InMemoryMessagesRepository({
        MessageKind.danger: 'Texto meu.',
      });
      coverageRepo = InMemoryCoverageRepository([rule]);

      mode = ModeController();
      contacts = ContactsController(repository: contactsRepo);
      messages = MessagesController(repository: messagesRepo);
      coverage = CoverageController(repository: coverageRepo);
      final service = FakeLocationService(const LocationResult.success(porto));
      alert = AlertController(locationService: service, actions: actions);
      location = LocationController(service: service);
      await Future.wait([contacts.load(), messages.load(), coverage.load()]);
    }

    Future<void> erase() => eraseAllData(
      mode: mode,
      alert: alert,
      contacts: contacts,
      messages: messages,
      coverage: coverage,
      location: location,
    );

    test('apaga contatos, faixas e mensagens editadas, na memória e no armazenamento', () async {
      await setUpAll();

      await erase();

      expect(contacts.contacts, isEmpty);
      expect(coverage.rules, isEmpty);
      expect(
        messages.textOf(MessageKind.danger),
        MessageKind.danger.defaultText,
      );
      expect(await contactsRepo.load(), isEmpty);
      expect(await coverageRepo.load(), isEmpty);
      expect(await messagesRepo.load(), isEmpty);
    });

    test(
      'desfaz o modo, o alerta e a localização guardada na memória',
      () async {
        await setUpAll();
        mode.activate(SecurityMode.danger);
        await alert.start(
          kind: MessageKind.danger,
          contacts: contacts.contacts.toList(),
          message: 'Socorro.',
        );
        await location.refresh();
        expect(alert.phase, AlertPhase.done);
        expect(location.point, porto);

        await erase();

        expect(mode.mode, SecurityMode.normal);
        expect(alert.phase, AlertPhase.idle);
        expect(alert.deliveries, isEmpty);
        expect(alert.text, isNull);
        expect(location.point, isNull);
        expect(location.status, LocationStatus.idle);
      },
    );

    test('apagar no meio de um alerta PARA os envios que faltam', () async {
      final gated = _GatedActions();
      await setUpAll(withActions: gated);
      mode.activate(SecurityMode.danger);

      final running = alert.start(
        kind: MessageKind.danger,
        contacts: contacts.contacts.toList(),
        message: 'Socorro.',
      );
      await settle();

      await erase(); // a usuária apagou tudo no meio do envio
      gated.gate.complete();
      await running;

      // Nada novo saiu depois de apagar, e nenhuma ligação foi feita.
      expect(gated.count(AlertActionKind.call), 0);
      expect(gated.count(AlertActionKind.sendSms), lessThanOrEqualTo(1));
      expect(alert.phase, AlertPhase.idle);
    });

    test('apagar de novo, sem nada guardado, não dá erro', () async {
      await setUpAll();

      await erase();
      await erase();

      expect(contacts.contacts, isEmpty);
      expect(coverage.rules, isEmpty);
    });

    test('um novo app aberto depois de apagar começa vazio', () async {
      await setUpAll();
      await erase();

      // "Fecha e reabre o app": controladores novos, o mesmo armazenamento.
      final reopenedContacts = ContactsController(repository: contactsRepo);
      final reopenedMessages = MessagesController(repository: messagesRepo);
      final reopenedCoverage = CoverageController(repository: coverageRepo);
      await Future.wait([
        reopenedContacts.load(),
        reopenedMessages.load(),
        reopenedCoverage.load(),
      ]);

      expect(reopenedContacts.contacts, isEmpty);
      expect(reopenedCoverage.rules, isEmpty);
      expect(
        reopenedMessages.textOf(MessageKind.danger),
        MessageKind.danger.defaultText,
      );
    });

    test('depois de apagar, dá para cadastrar tudo de novo', () async {
      await setUpAll();
      await erase();

      expect(contacts.add(name: 'Bia', phone: '51999990003'), isNull);
      expect(contacts.contacts.single.name, 'Bia');
    });
  });
}
