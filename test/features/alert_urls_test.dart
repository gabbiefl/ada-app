// Testa as URLs do alerta e a versão falsa das ações (sem abrir app nenhum).

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/utils/alert_urls.dart';

void main() {
  group('telefone internacional', () {
    test('celular com DDD ganha o código do Brasil', () {
      expect(internationalDigits('51999990001'), '5551999990001');
      expect(internationalPhone('51999990001'), '+5551999990001');
    });

    test('fixo com DDD (10 dígitos) também', () {
      expect(internationalPhone('5133330003'), '+555133330003');
    });

    test('ignora máscara e símbolos', () {
      expect(internationalPhone('(51) 99999-0001'), '+5551999990001');
    });

    test('não repete o 55 quando já vem com o código', () {
      expect(internationalPhone('5551999990001'), '+5551999990001');
      expect(internationalPhone('+55 51 99999-0001'), '+5551999990001');
    });
  });

  group('números de serviço (190, 180)', () {
    test('não levam código do país nem o +', () {
      expect(internationalPhone('190'), '190');
      expect(internationalPhone('180'), '180');
      expect(internationalDigits('190'), '190');
    });

    test('o discador abre com o número puro', () {
      expect(dialerUri('190').toString(), 'tel:190');
      expect(dialerUri('180').toString(), 'tel:180');
    });

    test('telefones comuns seguem com o +55', () {
      expect(internationalPhone('51999990001'), '+5551999990001');
      expect(isServiceNumber('190'), isTrue);
      expect(isServiceNumber('51999990001'), isFalse);
    });
  });

  group('WhatsApp', () {
    test('monta o link wa.me com o número e o texto codificado', () {
      final uri = whatsAppUri('51999990001', 'Preciso de ajuda.');

      expect(
        uri.toString(),
        'https://wa.me/5551999990001?text=Preciso%20de%20ajuda.',
      );
    });

    test('o texto volta igual depois de decodificado (acentos e linhas)', () {
      const text =
          'Estou em perigo!\n\nMinha localização: https://x.test/?q=1,2';

      final uri = whatsAppUri('51999990001', text);

      expect(uri.queryParameters['text'], text);
    });

    test('não leva o sinal + no número (o wa.me não aceita)', () {
      expect(whatsAppUri('51999990001', 'Oi').path, '/5551999990001');
    });
  });

  group('discador e SMS', () {
    test('tel: leva o número internacional', () {
      expect(dialerUri('51999990001').toString(), 'tel:+5551999990001');
    });

    test('sms: leva o número e o texto no parâmetro body', () {
      final uri = smsComposerUri('51999990001', 'Oi, tudo bem?');

      expect(uri.scheme, 'sms');
      expect(uri.toString(), startsWith('sms:+5551999990001?body='));
      expect(uri.queryParameters['body'], 'Oi, tudo bem?');
    });
  });

  group('FakeAlertActions', () {
    test('registra cada pedido e devolve sucesso por padrão', () async {
      final actions = FakeAlertActions();

      final sms = await actions.sendSms('51999990001', 'Oi');
      final call = await actions.call('51999990002');

      expect(sms.isSuccess, isTrue);
      expect(call.isSuccess, isTrue);
      expect(actions.calls.map((c) => c.kind), [
        AlertActionKind.sendSms,
        AlertActionKind.call,
      ]);
      expect(actions.calls.first.phone, '51999990001');
      expect(actions.calls.first.text, 'Oi');
      expect(actions.calls.last.text, isNull);
    });

    test('devolve a falha combinada para aquele tipo de ação', () async {
      final actions = FakeAlertActions()
        ..results[AlertActionKind.call] = const ActionResult.failure(
          ActionFailure.permissionDenied,
        );

      final call = await actions.call('51999990001');
      final sms = await actions.sendSms('51999990001', 'Oi');

      expect(call.failure, ActionFailure.permissionDenied);
      expect(sms.isSuccess, isTrue); // só a ligação foi combinada para falhar
    });

    test('conta os pedidos por tipo', () async {
      final actions = FakeAlertActions();

      await actions.sendSms('51999990001', 'a');
      await actions.sendSms('51999990002', 'b');
      await actions.openDialer('51999990003');

      expect(actions.count(AlertActionKind.sendSms), 2);
      expect(actions.count(AlertActionKind.openDialer), 1);
      expect(actions.count(AlertActionKind.call), 0);
    });

    test('toString não revela telefone nem texto', () {
      const call = AlertActionCall(
        AlertActionKind.sendSms,
        '51999990001',
        'Preciso de ajuda',
      );

      expect(call.toString(), isNot(contains('51999')));
      expect(call.toString(), isNot(contains('ajuda')));
    });
  });
}
