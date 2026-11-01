// Testa as regras de validação do contato: funções puras, sem tela.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/validators/contact_validators.dart';

void main() {
  group('nome', () {
    test('aceita um nome normal', () {
      expect(ContactValidators.name('Maria Silva'), isNull);
    });

    test('recusa vazio, só espaços e null', () {
      expect(ContactValidators.name(''), isNotNull);
      expect(ContactValidators.name('   '), isNotNull);
      expect(ContactValidators.name(null), isNotNull);
    });

    test('recusa nome com 1 letra', () {
      expect(ContactValidators.name('A'), isNotNull);
    });

    test('recusa nome muito longo', () {
      expect(ContactValidators.name('a' * 51), isNotNull);
      expect(ContactValidators.name('a' * 50), isNull);
    });
  });

  group('telefone', () {
    test('aceita celular com e sem máscara', () {
      expect(ContactValidators.phone('51999990001'), isNull);
      expect(ContactValidators.phone('(51) 99999-0001'), isNull);
    });

    test('aceita fixo com 10 dígitos', () {
      expect(ContactValidators.phone('(51) 3333-0001'), isNull);
    });

    test('recusa vazio e null', () {
      expect(ContactValidators.phone(''), isNotNull);
      expect(ContactValidators.phone(null), isNotNull);
    });

    test('recusa tamanho errado', () {
      expect(ContactValidators.phone('999990001'), isNotNull); // sem DDD
      expect(ContactValidators.phone('519999900012'), isNotNull); // 12 dígitos
    });

    test('recusa DDD inválido', () {
      expect(ContactValidators.phone('01999990001'), isNotNull);
      expect(ContactValidators.phone('10999990001'), isNotNull);
    });

    test('recusa celular de 11 dígitos que não começa com 9', () {
      expect(ContactValidators.phone('51899990001'), isNotNull);
    });
  });

  test('digitsOnly tira tudo que não é dígito', () {
    expect(ContactValidators.digitsOnly('(51) 99999-0001'), '51999990001');
  });
}
