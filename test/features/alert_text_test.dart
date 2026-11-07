// Testa a montagem do texto do alerta (mensagem + link da localização).

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';
import 'package:ada_app/features/messages/utils/alert_text.dart';

void main() {
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

  test('com localização: mensagem, linha em branco e o link', () {
    final text = buildAlertText(message: 'Preciso de ajuda.', location: porto);

    expect(
      text,
      'Preciso de ajuda.\n\n'
      'Minha localização: https://maps.google.com/?q=-30.034600,-51.217700',
    );
  });

  test('sem localização: avisa que ela não veio e não leva link', () {
    final text = buildAlertText(message: 'Preciso de ajuda.');

    expect(
      text,
      'Preciso de ajuda.\n\nNão consegui compartilhar a minha localização.',
    );
    expect(text, isNot(contains('http')));
  });

  test('espaços nas pontas da mensagem não viram linhas soltas', () {
    final text = buildAlertText(message: '  Oi.  \n', location: porto);

    expect(text.startsWith('Oi.\n\n'), isTrue);
  });

  test('o texto de cada mensagem padrão leva o link', () {
    for (final kind in MessageKind.values) {
      final text = buildAlertText(message: kind.defaultText, location: porto);

      expect(text, startsWith(kind.defaultText));
      expect(text, contains('maps.google.com'));
    }
  });

  test('usa a mensagem editada pela usuária, não a padrão', () {
    final messages = MessagesController()
      ..save(MessageKind.danger, 'Socorro, estou na rua.');

    final text = buildAlertText(
      message: messages.textOf(MessageKind.danger),
      location: porto,
    );

    expect(text, startsWith('Socorro, estou na rua.'));
    expect(text, isNot(contains(MessageKind.danger.defaultText)));
  });

  test('o link não muda a mensagem guardada (ela é só um modelo)', () {
    final messages = MessagesController();

    buildAlertText(
      message: messages.textOf(MessageKind.danger),
      location: porto,
    );

    expect(messages.textOf(MessageKind.danger), MessageKind.danger.defaultText);
  });
}
