// Testa onde os contatos ficam guardados e como o controlador usa isso.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';

// Repositório que sempre falha, para testar o app diante de um erro de leitura
// ou gravação.
class _BrokenRepository implements ContactsRepository {
  @override
  Future<List<Contact>> load() async => throw Exception('ilegível');

  @override
  Future<void> save(List<Contact> contacts) async =>
      throw Exception('sem espaço');
}

// Deixa as gravações pendentes terminarem antes de conferir o resultado.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  const maria = Contact(id: '1', name: 'Maria Silva', phone: '51999990001');
  const ana = Contact(id: '2', name: 'Ana Souza', phone: '5133330003');

  group('SecureContactsRepository', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('sem nada guardado, devolve lista vazia', () async {
      expect(await SecureContactsRepository().load(), isEmpty);
    });

    test('o que foi salvo volta igual ao carregar', () async {
      final repository = SecureContactsRepository();

      await repository.save([maria, ana]);

      // Outro repositório, como se o app tivesse sido fechado e reaberto.
      expect(await SecureContactsRepository().load(), [maria, ana]);
    });
  });

  group('ContactsController com repositório', () {
    test('load mostra os contatos guardados', () async {
      final controller = ContactsController(
        repository: InMemoryContactsRepository([maria, ana]),
      );

      await controller.load();

      expect(controller.contacts, [maria, ana]);
      expect(controller.count, 2);
    });

    test('load avisa quem está ouvindo', () async {
      final controller = ContactsController(
        repository: InMemoryContactsRepository([maria]),
      );
      var avisos = 0;
      controller.addListener(() => avisos++);

      await controller.load();

      expect(avisos, 1);
    });

    test('cadastrar, editar e remover gravam no repositório', () async {
      final repository = InMemoryContactsRepository();
      final controller = ContactsController(repository: repository);

      controller.add(name: 'Maria Silva', phone: '51999990001');
      await settle();
      expect((await repository.load()).single.name, 'Maria Silva');

      final id = controller.contacts.single.id;
      controller.update(id, name: 'Maria Souza', phone: '51999990001');
      await settle();
      expect((await repository.load()).single.name, 'Maria Souza');

      controller.remove(id);
      await settle();
      expect(await repository.load(), isEmpty);
    });

    test('um novo controlador recupera o que o anterior gravou', () async {
      final repository = InMemoryContactsRepository();
      final first = ContactsController(repository: repository);
      first.add(name: 'Maria Silva', phone: '51999990001');
      await settle();

      // "Fecha e reabre o app": outro controlador, o mesmo armazenamento.
      final second = ContactsController(repository: repository);
      await second.load();

      expect(second.contacts.single.name, 'Maria Silva');
    });

    test('recusa não grava nada', () async {
      final repository = InMemoryContactsRepository([maria]);
      final controller = ContactsController(repository: repository);
      await controller.load();

      controller.add(name: '', phone: '51999990002'); // inválido
      controller.add(name: 'Outra', phone: '51999990001'); // telefone repetido
      await settle();

      expect(await repository.load(), [maria]);
    });

    test(
      'se a leitura falhar, a rede começa vazia e o app não quebra',
      () async {
        final controller = ContactsController(repository: _BrokenRepository());

        await controller.load();

        expect(controller.contacts, isEmpty);
      },
    );

    test('se a gravação falhar, a lista na tela continua certa', () async {
      final controller = ContactsController(repository: _BrokenRepository());

      final error = controller.add(name: 'Maria', phone: '51999990001');
      await settle();

      expect(error, isNull);
      expect(controller.count, 1);
    });

    test('load respeita o limite de 5 mesmo com dados a mais', () async {
      final many = [
        for (var i = 1; i <= 7; i++)
          Contact(id: '$i', name: 'Contato $i', phone: '5199999000$i'),
      ];
      final controller = ContactsController(
        repository: InMemoryContactsRepository(many),
      );

      await controller.load();

      expect(controller.count, 5);
    });
  });
}
