// Máscara do telefone: enquanto a usuária digita, o texto vira (51) 9999-9999
// (fixo) ou (51) 99999-9999 (celular).
//
// Um TextInputFormatter recebe o texto ANTES (old) e DEPOIS (new) de cada
// tecla e devolve o texto que de fato fica no campo. Fazemos à mão, sem pacote.

import 'package:flutter/services.dart';

import 'package:ada_app/features/contacts/validators/contact_validators.dart';

// Monta o texto com máscara a partir de até 11 dígitos. Aceita números
// incompletos, para a máscara aparecer aos poucos: '5' -> '(5', '51999' -> '(51) 999'.
String formatPhone(String digits) {
  if (digits.isEmpty) return '';
  if (digits.length <= 2) return '($digits';
  // Com 11 dígitos (celular) o hífen vem depois do 7º; senão, depois do 6º.
  final dash = digits.length > 10 ? 7 : 6;
  if (digits.length <= dash) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
  }
  return '(${digits.substring(0, 2)}) ${digits.substring(2, dash)}'
      '-${digits.substring(dash)}';
}

class PhoneInputFormatter extends TextInputFormatter {
  static const _maxDigits = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = ContactValidators.digitsOnly(newValue.text);

    // Quantos dígitos existem antes do cursor: é a posição que queremos manter.
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsBeforeCursor = ContactValidators.digitsOnly(
      newValue.text.substring(0, cursor),
    ).length;

    // Se a usuária apagou só um símbolo da máscara (")", "-" ou espaço), os
    // dígitos não mudaram e o texto voltaria igual, travando o backspace.
    // Nesse caso apagamos o dígito que vem antes do cursor.
    final erasedOnlyMask =
        newValue.text.length < oldValue.text.length &&
        digits.length == ContactValidators.digitsOnly(oldValue.text).length;
    if (erasedOnlyMask && digitsBeforeCursor > 0) {
      digits =
          digits.substring(0, digitsBeforeCursor - 1) +
          digits.substring(digitsBeforeCursor);
      digitsBeforeCursor--;
    }

    if (digits.length > _maxDigits) {
      digits = digits.substring(0, _maxDigits);
    }
    if (digitsBeforeCursor > digits.length) digitsBeforeCursor = digits.length;

    final text = formatPhone(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(text, digitsBeforeCursor),
      ),
    );
  }

  // Posição no texto formatado logo depois do n-ésimo dígito.
  int _offsetAfterDigits(String text, int digitCount) {
    if (digitCount == 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) seen++;
      if (seen == digitCount) return i + 1;
    }
    return text.length;
  }
}
