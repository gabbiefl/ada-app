// Testa o model Contact: lógica pura, sem tela.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/models/contact.dart';

void main() {
  const contact = Contact(id: '1', name: 'Maria Silva', phone: '51999990001');

  test('copyWith troca só o que foi informado', () {
    final edited = contact.copyWith(name: 'Maria Souza');

    expect(edited.name, 'Maria Souza');
    expect(edited.phone, contact.phone);
    expect(edited.id, contact.id);
  });

  test('o original não muda depois do copyWith', () {
    contact.copyWith(phone: '51988880000');

    expect(contact.phone, '51999990001');
  });

  test('toJson e fromJson fazem a viagem de ida e volta', () {
    final json = contact.toJson();

    expect(json, {'id': '1', 'name': 'Maria Silva', 'phone': '51999990001'});
    expect(Contact.fromJson(json), contact);
  });

  test('contatos com os mesmos dados são iguais', () {
    const same = Contact(id: '1', name: 'Maria Silva', phone: '51999990001');
    const other = Contact(id: '2', name: 'Maria Silva', phone: '51999990001');

    expect(same, contact);
    expect(other, isNot(contact));
  });

  test('formattedPhone formata celular e fixo', () {
    expect(contact.formattedPhone, '(51) 99999-0001');
    expect(
      const Contact(id: '2', name: 'Ana', phone: '5133330003').formattedPhone,
      '(51) 3333-0003',
    );
  });

  test('toString não mostra o telefone nem o nome', () {
    expect(contact.toString(), isNot(contains('51999990001')));
    expect(contact.toString(), isNot(contains('Maria')));
  });
}
