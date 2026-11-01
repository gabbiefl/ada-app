// Testa a máscara do telefone: lógica pura, sem tela.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/formatters/phone_input_formatter.dart';

void main() {
  final formatter = PhoneInputFormatter();

  // Simula uma tecla: o campo tinha `before`, ficou `after` com o cursor no fim
  // (ou em `cursor`, se informado).
  TextEditingValue type(String before, String after, {int? cursor}) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: before),
      TextEditingValue(
        text: after,
        selection: TextSelection.collapsed(offset: cursor ?? after.length),
      ),
    );
  }

  group('formatPhone', () {
    test('monta a máscara aos poucos', () {
      expect(formatPhone(''), '');
      expect(formatPhone('5'), '(5');
      expect(formatPhone('51'), '(51');
      expect(formatPhone('519'), '(51) 9');
      expect(formatPhone('51999'), '(51) 999');
    });

    test('fixo (10 dígitos) e celular (11 dígitos)', () {
      expect(formatPhone('5133330003'), '(51) 3333-0003');
      expect(formatPhone('51999990001'), '(51) 99999-0001');
    });
  });

  group('PhoneInputFormatter', () {
    test('digitando um dígito por vez', () {
      expect(type('', '5').text, '(5');
      expect(type('(5', '(51').text, '(51');
      expect(type('(51', '(519').text, '(51) 9');
    });

    test('colar um número sem máscara', () {
      expect(type('', '51999990001').text, '(51) 99999-0001');
    });

    test('ignora letras e símbolos', () {
      expect(type('', '51abc99').text, '(51) 99');
    });

    test('limita a 11 dígitos', () {
      expect(type('', '519999900019999').text, '(51) 99999-0001');
    });

    test('o cursor fica depois do último dígito digitado', () {
      final result = type('(51) 9', '(51) 99');

      expect(result.text, '(51) 99');
      expect(result.selection.baseOffset, 7);
    });

    test('backspace apaga um dígito normalmente', () {
      expect(type('(51) 99', '(51) 9').text, '(51) 9');
    });

    test('backspace sobre a máscara apaga o dígito anterior', () {
      // '(51) 3333-0': o cursor está depois do hífen e a usuária o apaga.
      // Sem o tratamento, o texto voltaria igual e o campo travaria.
      final result = type('(51) 3333-0', '(51) 33330', cursor: 9);

      expect(result.text, '(51) 3330'); // saiu o último "3" antes do hífen
    });
  });
}
