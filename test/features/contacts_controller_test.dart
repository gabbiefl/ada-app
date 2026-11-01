// Testa as regras da rede de contatos, sem desenhar nenhuma tela.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/state/contacts_controller.dart';

void main() {
  late ContactsController controller;

  // Telefones válidos e diferentes entre si: 51999990001, ...0002, etc.
  String phone(int n) => '5199999000$n';

  void fill(int quantity) {
    for (var i = 1; i <= quantity; i++) {
      controller.add(name: 'Contato $i', phone: phone(i));
    }
  }

  setUp(() => controller = ContactsController());

  test('começa vazio, com 5 espaços livres', () {
    expect(controller.contacts, isEmpty);
    expect(controller.freeSlots, 5);
    expect(controller.isFull, isFalse);
  });

  test(
    'add guarda o contato com nome sem espaços e telefone só com dígitos',
    () {
      final error = controller.add(
        name: '  Maria Silva ',
        phone: '(51) 99999-0001',
      );

      expect(error, isNull);
      expect(controller.contacts.single.name, 'Maria Silva');
      expect(controller.contacts.single.phone, '51999990001');
    },
  );

  test('recusa o sexto contato', () {
    fill(5);

    expect(controller.isFull, isTrue);
    expect(
      controller.add(name: 'Sexta', phone: '51988880000'),
      ContactsError.limitReached,
    );
    expect(controller.count, 5);
  });

  test('recusa telefone repetido, mesmo com máscara diferente', () {
    controller.add(name: 'Maria', phone: '51999990001');

    expect(
      controller.add(name: 'Outra', phone: '(51) 99999-0001'),
      ContactsError.duplicatePhone,
    );
    expect(controller.count, 1);
  });

  test('recusa dados inválidos', () {
    expect(
      controller.add(name: '', phone: '51999990001'),
      ContactsError.invalidData,
    );
    expect(
      controller.add(name: 'Maria', phone: '123'),
      ContactsError.invalidData,
    );
    expect(controller.contacts, isEmpty);
  });

  test('update troca nome e telefone e aceita manter o próprio telefone', () {
    controller.add(name: 'Maria', phone: '51999990001');
    final id = controller.contacts.single.id;

    expect(
      controller.update(id, name: 'Maria Souza', phone: '51999990001'),
      isNull,
    );
    expect(controller.byId(id)?.name, 'Maria Souza');

    expect(controller.update(id, name: 'Maria', phone: '51999990009'), isNull);
    expect(controller.byId(id)?.phone, '51999990009');
  });

  test('update recusa o telefone de outro contato', () {
    fill(2);
    final second = controller.contacts[1].id;

    expect(
      controller.update(second, name: 'Contato 2', phone: phone(1)),
      ContactsError.duplicatePhone,
    );
  });

  test('update de um id que não existe', () {
    expect(
      controller.update('x', name: 'Maria', phone: '51999990001'),
      ContactsError.notFound,
    );
  });

  test('remove libera espaço e permite cadastrar de novo', () {
    fill(5);
    final id = controller.contacts.first.id;

    expect(controller.remove(id), isNull);
    expect(controller.isFull, isFalse);
    expect(controller.freeSlots, 1);
    expect(controller.add(name: 'Nova', phone: '51988880000'), isNull);
  });

  test('remove de um id que não existe', () {
    expect(controller.remove('x'), ContactsError.notFound);
  });

  test('avisa quem ouve só quando algo muda de verdade', () {
    var avisos = 0;
    controller.addListener(() => avisos++);

    controller.add(name: 'Maria', phone: '51999990001'); // muda: avisa
    controller.add(name: '', phone: '51999990002'); // recusado: não avisa
    controller.remove('x'); // não existe: não avisa
    controller.remove(controller.contacts.single.id); // muda: avisa

    expect(avisos, 2);
  });

  test('a lista exposta não pode ser alterada por fora', () {
    controller.add(name: 'Maria', phone: '51999990001');

    expect(() => controller.contacts.clear(), throwsUnsupportedError);
  });

  test('ids não se repetem', () {
    fill(5);
    final ids = controller.contacts.map((c) => c.id).toSet();

    expect(ids.length, 5);
  });
}
