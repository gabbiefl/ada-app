// Testa onde as mensagens editadas ficam guardadas e como o controlador usa isso.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

// Repositório que sempre falha, para testar o app diante de erro de leitura
// ou gravação.
class _BrokenRepository implements MessagesRepository {
  @override
  Future<Map<MessageKind, String>> load() async => throw Exception('ilegível');

  @override
  Future<void> save(Map<MessageKind, String> custom) async =>
      throw Exception('sem espaço');
}

// Deixa as gravações pendentes terminarem antes de conferir o resultado.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('SecureMessagesRepository', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('sem nada guardado, devolve mapa vazio', () async {
      expect(await SecureMessagesRepository().load(), isEmpty);
    });

    test('o que foi salvo volta igual ao carregar', () async {
      await SecureMessagesRepository().save({
        MessageKind.danger: 'Socorro!',
        MessageKind.arrived: 'Cheguei!',
      });

      // Outro repositório, como se o app tivesse sido fechado e reaberto.
      expect(await SecureMessagesRepository().load(), {
        MessageKind.danger: 'Socorro!',
        MessageKind.arrived: 'Cheguei!',
      });
    });

    test('ignora nomes de mensagem desconhecidos', () async {
      FlutterSecureStorage.setMockInitialValues({
        'ada_messages': '{"danger":"Oi","futura":"x"}',
      });

      expect(await SecureMessagesRepository().load(), {
        MessageKind.danger: 'Oi',
      });
    });
  });

  group('MessagesController com repositório', () {
    test('load mostra os textos guardados', () async {
      final controller = MessagesController(
        repository: InMemoryMessagesRepository({MessageKind.danger: 'Oi'}),
      );

      await controller.load();

      expect(controller.textOf(MessageKind.danger), 'Oi');
      expect(
        controller.textOf(MessageKind.attention),
        MessageKind.attention.defaultText,
      );
    });

    test('load avisa quem está ouvindo', () async {
      final controller = MessagesController(
        repository: InMemoryMessagesRepository({MessageKind.danger: 'Oi'}),
      );
      var avisos = 0;
      controller.addListener(() => avisos++);

      await controller.load();

      expect(avisos, 1);
    });

    test('salvar e resetar gravam no repositório', () async {
      final repository = InMemoryMessagesRepository();
      final controller = MessagesController(repository: repository);

      controller.save(MessageKind.danger, 'Socorro!');
      await settle();
      expect(await repository.load(), {MessageKind.danger: 'Socorro!'});

      controller.reset(MessageKind.danger);
      await settle();
      expect(await repository.load(), isEmpty);
    });

    test('um novo controlador recupera o que o anterior gravou', () async {
      final repository = InMemoryMessagesRepository();
      MessagesController(repository: repository)
          .save(MessageKind.attention, 'Estou insegura.');
      await settle();

      // "Fecha e reabre o app": outro controlador, o mesmo armazenamento.
      final second = MessagesController(repository: repository);
      await second.load();

      expect(second.textOf(MessageKind.attention), 'Estou insegura.');
    });

    test('recusa não grava nada', () async {
      final repository = InMemoryMessagesRepository({MessageKind.danger: 'Oi'});
      final controller = MessagesController(repository: repository);
      await controller.load();

      controller.save(MessageKind.danger, '   '); // vazio
      controller.save(MessageKind.danger, 'a' * 201); // longo demais
      await settle();

      expect(await repository.load(), {MessageKind.danger: 'Oi'});
    });

    test('load descarta dado guardado inválido', () async {
      final controller = MessagesController(
        repository: InMemoryMessagesRepository({
          MessageKind.danger: '   ',
          MessageKind.attention: 'a' * 201,
        }),
      );

      await controller.load();

      expect(controller.isCustomized(MessageKind.danger), isFalse);
      expect(controller.isCustomized(MessageKind.attention), isFalse);
    });

    test('se a leitura falhar, valem os textos padrão', () async {
      final controller = MessagesController(repository: _BrokenRepository());

      await controller.load();

      expect(
        controller.textOf(MessageKind.danger),
        MessageKind.danger.defaultText,
      );
    });

    test('se a gravação falhar, o texto na tela continua certo', () async {
      final controller = MessagesController(repository: _BrokenRepository());

      final error = controller.save(MessageKind.danger, 'Socorro!');
      await settle();

      expect(error, isNull);
      expect(controller.textOf(MessageKind.danger), 'Socorro!');
    });
  });
}
