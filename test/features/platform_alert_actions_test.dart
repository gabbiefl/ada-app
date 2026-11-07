// Testa a versão real das ações trocando o mundo de fora por falsos: um canal
// nativo de mentira, permissões combinadas e um "abridor de URL" que só anota.
// Nada aqui envia SMS, liga ou abre app de verdade.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/data/platform_alert_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformAlertActions.channelName);

  // O que o "Kotlin de mentira" recebeu, e como ele responde.
  late List<MethodCall> received;
  PlatformException? nativeError;
  bool nativeMissing = false;

  // Permissões que a "usuária" aceita, e quantas vezes perguntamos.
  late Set<Permission> granted;
  late List<Permission> asked;

  // URLs que o abridor recebeu, e se "conseguiu" abrir.
  late List<Uri> opened;
  bool canOpen = true;

  late PlatformAlertActions actions;

  setUp(() {
    received = [];
    nativeError = null;
    nativeMissing = false;
    granted = {Permission.sms, Permission.phone};
    asked = [];
    opened = [];
    canOpen = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received.add(call);
          if (nativeMissing) throw MissingPluginException();
          if (nativeError != null) throw nativeError!;
          return true;
        });

    actions = PlatformAlertActions(
      channel: channel,
      askPermission: (permission) async {
        asked.add(permission);
        return granted.contains(permission);
      },
      openUrl: (uri) async {
        opened.add(uri);
        return canOpen;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SMS direto', () {
    test('com permissão, chama o nativo com o número internacional', () async {
      final result = await actions.sendSms('51999990001', 'Preciso de ajuda.');

      expect(result.isSuccess, isTrue);
      expect(received.single.method, 'sendSms');
      expect(received.single.arguments, {
        'phone': '+5551999990001',
        'text': 'Preciso de ajuda.',
      });
      expect(asked, [Permission.sms]);
    });

    test('sem permissão, nem chama o nativo', () async {
      granted = {};

      final result = await actions.sendSms('51999990001', 'Oi');

      expect(result.failure, ActionFailure.permissionDenied);
      expect(received, isEmpty);
    });

    test('traduz os códigos de erro do nativo', () async {
      final cases = {
        'permission_denied': ActionFailure.permissionDenied,
        'not_available': ActionFailure.notAvailable,
        'failed': ActionFailure.failed,
        'qualquer_outro': ActionFailure.failed,
      };

      for (final entry in cases.entries) {
        nativeError = PlatformException(code: entry.key);

        final result = await actions.sendSms('51999990001', 'Oi');

        expect(result.failure, entry.value, reason: entry.key);
      }
    });

    test(
      'sem o lado nativo (ex.: Chrome), fica indisponível sem quebrar',
      () async {
        nativeMissing = true;

        final result = await actions.sendSms('51999990001', 'Oi');

        expect(result.failure, ActionFailure.notAvailable);
      },
    );
  });

  group('Ligação direta', () {
    test('com permissão, chama o nativo com o número internacional', () async {
      final result = await actions.call('51999990001');

      expect(result.isSuccess, isTrue);
      expect(received.single.method, 'call');
      expect(received.single.arguments, {'phone': '+5551999990001'});
      expect(asked, [Permission.phone]);
    });

    test('sem permissão, nem chama o nativo', () async {
      granted = {};

      final result = await actions.call('51999990001');

      expect(result.failure, ActionFailure.permissionDenied);
      expect(received, isEmpty);
    });

    test('falha do nativo vira falha da ação', () async {
      nativeError = PlatformException(code: 'not_available');

      final result = await actions.call('51999990001');

      expect(result.failure, ActionFailure.notAvailable);
    });
  });

  group('Pedir as permissões de antemão', () {
    test('devolve true quando SMS e ligação foram dados', () async {
      expect(await actions.requestPermissions(), isTrue);
      expect(asked, [Permission.sms, Permission.phone]);
    });

    test('devolve false se qualquer uma for negada', () async {
      granted = {Permission.sms};
      expect(await actions.requestPermissions(), isFalse);

      granted = {Permission.phone};
      expect(await actions.requestPermissions(), isFalse);
    });

    test('pergunta as duas mesmo que a primeira seja negada', () async {
      granted = {};

      await actions.requestPermissions();

      expect(asked, [Permission.sms, Permission.phone]);
    });
  });

  group('Plano B e WhatsApp (abrem outro app)', () {
    test('compositor de SMS abre o endereço sms: com o texto', () async {
      final result = await actions.openSmsComposer('51999990001', 'Oi!');

      expect(result.isSuccess, isTrue);
      expect(opened.single.toString(), startsWith('sms:+5551999990001?body='));
      expect(opened.single.queryParameters['body'], 'Oi!');
    });

    test('discador abre o endereço tel:', () async {
      await actions.openDialer('51999990001');

      expect(opened.single.toString(), 'tel:+5551999990001');
    });

    test('WhatsApp abre o link wa.me com o texto', () async {
      await actions.openWhatsApp('51999990001', 'Oi!');

      expect(opened.single.host, 'wa.me');
      expect(opened.single.path, '/5551999990001');
      expect(opened.single.queryParameters['text'], 'Oi!');
    });

    test('se nenhum app abrir o endereço, fica indisponível', () async {
      canOpen = false;

      expect(
        (await actions.openWhatsApp('51999990001', 'Oi')).failure,
        ActionFailure.notAvailable,
      );
    });

    test('se o abridor lançar erro, vira indisponível, sem quebrar', () async {
      final throwing = PlatformAlertActions(
        channel: channel,
        askPermission: (_) async => true,
        openUrl: (_) async => throw PlatformException(code: 'sem_app'),
      );

      final result = await throwing.openDialer('51999990001');

      expect(result.failure, ActionFailure.notAvailable);
    });

    test('abrir outro app não pede permissão nem chama o nativo', () async {
      await actions.openSmsComposer('51999990001', 'Oi');
      await actions.openDialer('51999990001');
      await actions.openWhatsApp('51999990001', 'Oi');

      expect(asked, isEmpty);
      expect(received, isEmpty);
    });
  });

  group('FakeAlertActions (permissões)', () {
    test('requestPermissions devolve o combinado e conta os pedidos', () async {
      final fake = FakeAlertActions();

      expect(await fake.requestPermissions(), isTrue);
      fake.permissionsGranted = false;
      expect(await fake.requestPermissions(), isFalse);
      expect(fake.permissionRequests, 2);
    });
  });
}
