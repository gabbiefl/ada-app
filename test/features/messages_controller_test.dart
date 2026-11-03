// Testa as regras das mensagens, sem desenhar nenhuma tela.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

void main() {
  late MessagesController controller;

  setUp(() => controller = MessagesController());

  test('sem edição, vale o texto padrão de cada mensagem', () {
    for (final kind in MessageKind.values) {
      expect(controller.textOf(kind), kind.defaultText);
      expect(controller.isCustomized(kind), isFalse);
    }
  });

  test('os textos padrão cabem no limite de 200 letras', () {
    for (final kind in MessageKind.values) {
      expect(kind.defaultText.length, lessThanOrEqualTo(MessageKind.maxLength));
    }
  });

  test('save guarda o texto sem espaços nas pontas', () {
    final error = controller.save(MessageKind.danger, '  Socorro!  ');

    expect(error, isNull);
    expect(controller.textOf(MessageKind.danger), 'Socorro!');
    expect(controller.isCustomized(MessageKind.danger), isTrue);
  });

  test('editar uma mensagem não muda as outras', () {
    controller.save(MessageKind.danger, 'Socorro!');

    expect(
      controller.textOf(MessageKind.attention),
      MessageKind.attention.defaultText,
    );
    expect(
      controller.textOf(MessageKind.arrived),
      MessageKind.arrived.defaultText,
    );
  });

  test('recusa texto vazio ou só com espaços', () {
    expect(controller.save(MessageKind.danger, ''), MessagesError.empty);
    expect(controller.save(MessageKind.danger, '   '), MessagesError.empty);
    expect(
      controller.textOf(MessageKind.danger),
      MessageKind.danger.defaultText,
    );
  });

  test('recusa texto acima de 200 letras e aceita exatamente 200', () {
    expect(
      controller.save(MessageKind.danger, 'a' * 201),
      MessagesError.tooLong,
    );
    expect(controller.save(MessageKind.danger, 'a' * 200), isNull);
  });

  test('reset volta ao texto padrão', () {
    controller.save(MessageKind.danger, 'Socorro!');

    controller.reset(MessageKind.danger);

    expect(
      controller.textOf(MessageKind.danger),
      MessageKind.danger.defaultText,
    );
    expect(controller.isCustomized(MessageKind.danger), isFalse);
  });

  test('salvar o texto igual ao padrão não conta como edição', () {
    controller.save(MessageKind.danger, 'Socorro!');

    controller.save(MessageKind.danger, MessageKind.danger.defaultText);

    expect(controller.isCustomized(MessageKind.danger), isFalse);
  });

  test('avisa quem ouve só quando algo muda de verdade', () {
    var avisos = 0;
    controller.addListener(() => avisos++);

    controller.save(MessageKind.danger, 'Socorro!'); // muda: avisa
    controller.save(MessageKind.danger, 'Socorro!'); // igual: não avisa
    controller.save(MessageKind.danger, ''); // recusado: não avisa
    controller.reset(MessageKind.attention); // nada a resetar: não avisa
    controller.reset(MessageKind.danger); // muda: avisa

    expect(avisos, 2);
  });
}
