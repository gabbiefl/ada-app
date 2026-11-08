// Testa a ligação, no app inteiro, entre a rede de contatos e as faixas de
// cobertura: remover um contato apaga as faixas dele.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';

// Repositório de contatos que sempre falha ao ler (simula o armazenamento
// indisponível).
class _BrokenContactsRepository implements ContactsRepository {
  @override
  Future<List<Contact>> load() async => throw Exception('ilegível');

  @override
  Future<void> save(List<Contact> contacts) async {}
}

const _short = Duration(milliseconds: 300);

Widget _app({
  required ContactsRepository contacts,
  required CoverageRepository coverage,
}) => AdaApp(
  locationService: FakeLocationService(
    const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
  ),
  alertActions: FakeAlertActions(),
  contactsRepository: contacts,
  messagesRepository: InMemoryMessagesRepository(),
  coverageRepository: coverage,
);

// Pega um controlador do app já montado (o MaterialApp está abaixo dos provedores).
T _read<T>(WidgetTester tester) =>
    Provider.of<T>(tester.element(find.byType(MaterialApp)), listen: false);

void main() {
  const maria = Contact(id: 'm', name: 'Maria', phone: '51999990001');
  const ana = Contact(id: 'a', name: 'Ana', phone: '51999990002');
  const mariaRule = CoverageRule(id: '1', contactId: 'm', start: 480, end: 780);
  const anaRule = CoverageRule(id: '2', contactId: 'a', start: 780, end: 1080);

  testWidgets('remover um contato apaga as faixas dele e só as dele', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        contacts: InMemoryContactsRepository([maria, ana]),
        coverage: InMemoryCoverageRepository([mariaRule, anaRule]),
      ),
    );
    await tester.pump(_short);
    final coverage = _read<CoverageController>(tester);
    expect(coverage.rules.length, 2);

    _read<ContactsController>(tester).remove('a');
    await tester.pump(_short);

    expect(coverage.rules, [mariaRule]);
  });

  testWidgets('as faixas continuam salvas depois de apagar as órfãs', (
    tester,
  ) async {
    final repository = InMemoryCoverageRepository([mariaRule, anaRule]);
    await tester.pumpWidget(
      _app(
        contacts: InMemoryContactsRepository([maria, ana]),
        coverage: repository,
      ),
    );
    await tester.pump(_short);

    _read<ContactsController>(tester).remove('a');
    await tester.pump(_short);

    expect(await repository.load(), [mariaRule]);
  });

  testWidgets('uma leitura de contatos que falha NÃO apaga nenhuma faixa', (
    tester,
  ) async {
    // Se o armazenamento dos contatos estiver indisponível, a rede fica vazia,
    // mas isso não é a usuária removendo todo mundo: as faixas têm que ficar.
    await tester.pumpWidget(
      _app(
        contacts: _BrokenContactsRepository(),
        coverage: InMemoryCoverageRepository([mariaRule, anaRule]),
      ),
    );
    await tester.pump(_short);

    expect(_read<ContactsController>(tester).contacts, isEmpty);
    expect(_read<CoverageController>(tester).rules.length, 2);
  });

  testWidgets('cadastrar um contato novo não apaga as faixas dos outros', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        contacts: InMemoryContactsRepository([maria, ana]),
        coverage: InMemoryCoverageRepository([mariaRule, anaRule]),
      ),
    );
    await tester.pump(_short);

    _read<ContactsController>(tester).add(name: 'Bia', phone: '51999990003');
    await tester.pump(_short);

    expect(_read<CoverageController>(tester).rules.length, 2);
  });
}
