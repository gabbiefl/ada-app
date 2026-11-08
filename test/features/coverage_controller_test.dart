// Testa o controlador das faixas de cobertura e onde elas ficam guardadas.
// A hora entra como "minutos desde a meia-noite": 8:00 = 480, 23:00 = 1380.

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

// '8:30' -> 510.
int at(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

// Repositório que sempre falha, para testar o app diante de erro de leitura ou
// de gravação.
class _BrokenRepository implements CoverageRepository {
  @override
  Future<List<CoverageRule>> load() async => throw Exception('ilegível');

  @override
  Future<void> save(List<CoverageRule> rules) async =>
      throw Exception('sem espaço');
}

// Repositório que só entrega as faixas quando o teste mandar.
class _SlowRepository implements CoverageRepository {
  final _completer = Completer<List<CoverageRule>>();

  void finish(List<CoverageRule> rules) => _completer.complete(rules);

  @override
  Future<List<CoverageRule>> load() => _completer.future;

  @override
  Future<void> save(List<CoverageRule> rules) async {}
}

// Deixa as gravações pendentes terminarem antes de conferir o resultado.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late CoverageController controller;

  setUp(() => controller = CoverageController());

  CoverageError? addRule(
    String contactId,
    String start,
    String end, {
    bool enabled = true,
  }) => controller.add(
    contactId: contactId,
    start: at(start),
    end: at(end),
    enabled: enabled,
  );

  group('adicionar', () {
    test('guarda a faixa ligada, na ordem em que foi criada', () {
      expect(addRule('g', '8:00', '13:00'), isNull);
      expect(addRule('y', '13:00', '18:00'), isNull);

      expect(controller.rules.length, 2);
      expect(controller.rules.first.contactId, 'g');
      expect(controller.rules.first.enabled, isTrue);
      expect(controller.rules.last.contactId, 'y');
    });

    test(
      'dá um id diferente a cada faixa, mesmo criadas no mesmo instante',
      () {
        addRule('g', '8:00', '9:00');
        addRule('y', '9:00', '10:00');
        addRule('m', '10:00', '11:00');

        expect(controller.rules.map((r) => r.id).toSet().length, 3);
      },
    );

    test('recusa início igual ao fim', () {
      expect(addRule('g', '8:00', '8:00'), CoverageError.sameStartEnd);
      expect(controller.rules, isEmpty);
    });

    test('recusa hora fora do dia', () {
      expect(
        controller.add(contactId: 'g', start: -1, end: 100),
        CoverageError.invalidTime,
      );
      expect(
        controller.add(contactId: 'g', start: 100, end: minutesPerDay),
        CoverageError.invalidTime,
      );
      expect(controller.rules, isEmpty);
    });

    test('recusa contato que não existe', () {
      controller = CoverageController(contactExists: (id) => id == 'g');

      expect(
        addRule('fantasma', '8:00', '13:00'),
        CoverageError.contactMissing,
      );
      expect(addRule('g', '8:00', '13:00'), isNull);
    });

    test('aceita a faixa que atravessa a meia-noite', () {
      expect(addRule('t', '23:00', '4:00'), isNull);
    });

    test('avisa quem ouve só quando guarda de verdade', () {
      var avisos = 0;
      controller.addListener(() => avisos++);

      addRule('g', '8:00', '13:00'); // guarda: avisa
      addRule('g', '8:00', '8:00'); // recusada: não avisa

      expect(avisos, 1);
    });
  });

  group('cruzamento entre faixas ligadas', () {
    test('recusa faixa que cruza com outra ligada', () {
      addRule('g', '8:00', '13:00');

      expect(addRule('y', '12:00', '14:00'), CoverageError.overlaps);
      expect(controller.rules.length, 1);
    });

    test('faixas coladas são aceitas', () {
      addRule('g', '8:00', '13:00');

      expect(addRule('y', '13:00', '18:00'), isNull);
    });

    test('recusa cruzamento com a faixa que atravessa a meia-noite', () {
      addRule('t', '23:00', '4:00');

      expect(addRule('a', '3:00', '8:00'), CoverageError.overlaps);
      expect(addRule('a', '4:00', '8:00'), isNull); // colada: ok
    });

    test('faixa desligada não conflita: pode entrar por cima', () {
      addRule('g', '8:00', '13:00', enabled: false);

      expect(addRule('y', '9:00', '12:00'), isNull);
    });

    test('faixa nova DESLIGADA pode cruzar com uma ligada', () {
      addRule('g', '8:00', '13:00');

      expect(addRule('y', '9:00', '12:00', enabled: false), isNull);
      expect(controller.rules.length, 2);
    });

    test('findConflict diz com qual faixa cruza', () {
      addRule('g', '8:00', '13:00');
      final first = controller.rules.first;

      expect(
        controller.findConflict(start: at('12:00'), end: at('14:00')),
        first,
      );
      expect(
        controller.findConflict(start: at('13:00'), end: at('14:00')),
        isNull,
      );
    });

    test('findConflict ignora a faixa que está sendo editada', () {
      addRule('g', '8:00', '13:00');
      final rule = controller.rules.first;

      expect(
        controller.findConflict(
          ignoreId: rule.id,
          start: at('9:00'),
          end: at('14:00'),
        ),
        isNull,
      );
    });
  });

  group('editar', () {
    late String id;

    setUp(() {
      addRule('g', '8:00', '13:00');
      addRule('y', '13:00', '18:00');
      id = controller.rules.first.id;
    });

    test('troca o contato e o horário', () {
      final error = controller.update(
        id,
        contactId: 'm',
        start: at('7:00'),
        end: at('12:00'),
      );

      expect(error, isNull);
      expect(controller.byId(id)!.contactId, 'm');
      expect(controller.byId(id)!.start, at('7:00'));
      expect(controller.byId(id)!.end, at('12:00'));
    });

    test('mantém o id e se a faixa está ligada', () {
      controller.setEnabled(id, false);

      controller.update(
        id,
        contactId: 'm',
        start: at('8:00'),
        end: at('12:00'),
      );

      expect(controller.byId(id)!.id, id);
      expect(controller.byId(id)!.enabled, isFalse);
    });

    test('a faixa pode manter o próprio horário (não cruza consigo mesma)', () {
      expect(
        controller.update(
          id,
          contactId: 'm',
          start: at('8:00'),
          end: at('13:00'),
        ),
        isNull,
      );
    });

    test('recusa mudar para um horário que cruza com outra faixa', () {
      final error = controller.update(
        id,
        contactId: 'g',
        start: at('8:00'),
        end: at('14:00'), // invade a faixa das 13:00 às 18:00
      );

      expect(error, CoverageError.overlaps);
      expect(controller.byId(id)!.end, at('13:00')); // não mudou
    });

    test('recusa horário inválido', () {
      expect(
        controller.update(
          id,
          contactId: 'g',
          start: at('9:00'),
          end: at('9:00'),
        ),
        CoverageError.sameStartEnd,
      );
    });

    test('recusa trocar para um contato que não existe mais', () {
      // O contato existia ao criar a faixa e sumiu da rede depois.
      var exists = true;
      controller = CoverageController(contactExists: (_) => exists);
      controller.add(contactId: 'g', start: at('8:00'), end: at('13:00'));
      final created = controller.rules.single.id;
      exists = false;

      expect(
        controller.update(
          created,
          contactId: 'fantasma',
          start: at('8:00'),
          end: at('13:00'),
        ),
        CoverageError.contactMissing,
      );
    });

    test('faixa que não existe', () {
      expect(
        controller.update(
          'nada',
          contactId: 'g',
          start: at('8:00'),
          end: at('9:00'),
        ),
        CoverageError.notFound,
      );
    });
  });

  group('ligar e desligar', () {
    test('desligar sempre pode, e a faixa continua salva', () {
      addRule('g', '8:00', '13:00');
      final id = controller.rules.first.id;

      expect(controller.setEnabled(id, false), isNull);

      expect(controller.byId(id)!.enabled, isFalse);
      expect(controller.rules.length, 1);
    });

    test('religar uma faixa que não cruza com ninguém funciona', () {
      addRule('g', '8:00', '13:00', enabled: false);
      final id = controller.rules.first.id;

      expect(controller.setEnabled(id, true), isNull);
      expect(controller.byId(id)!.enabled, isTrue);
    });

    test('recusa religar uma faixa que agora cruzaria com outra ligada', () {
      addRule('g', '8:00', '13:00', enabled: false);
      final off = controller.rules.first.id;
      addRule('y', '9:00', '12:00'); // entra por cima da desligada

      expect(controller.setEnabled(off, true), CoverageError.overlaps);
      expect(controller.byId(off)!.enabled, isFalse);
    });

    test('não avisa se nada mudou', () {
      addRule('g', '8:00', '13:00');
      final id = controller.rules.first.id;
      var avisos = 0;
      controller.addListener(() => avisos++);

      controller.setEnabled(id, true); // já estava ligada

      expect(avisos, 0);
    });

    test('faixa que não existe', () {
      expect(controller.setEnabled('nada', false), CoverageError.notFound);
    });
  });

  group('remover', () {
    test('tira a faixa e libera o horário', () {
      addRule('g', '8:00', '13:00');
      final id = controller.rules.first.id;

      expect(controller.remove(id), isNull);

      expect(controller.rules, isEmpty);
      expect(addRule('y', '9:00', '12:00'), isNull);
    });

    test('faixa que não existe', () {
      expect(controller.remove('nada'), CoverageError.notFound);
    });
  });

  group('pruneFor: faixas de contatos que não existem mais', () {
    test('apaga só as faixas órfãs e diz quantas', () {
      addRule('g', '8:00', '13:00');
      addRule('removido', '13:00', '18:00');
      addRule('y', '18:00', '23:00');

      final removed = controller.pruneFor(['g', 'y']);

      expect(removed, 1);
      expect(controller.rules.map((r) => r.contactId), ['g', 'y']);
    });

    test('sem órfãs, não faz nada e não avisa', () {
      addRule('g', '8:00', '13:00');
      var avisos = 0;
      controller.addListener(() => avisos++);

      expect(controller.pruneFor(['g']), 0);
      expect(avisos, 0);
    });
  });

  group('SecureCoverageRepository', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('sem nada guardado, devolve lista vazia', () async {
      expect(await SecureCoverageRepository().load(), isEmpty);
    });

    test('o que foi salvo volta igual ao carregar', () async {
      const rules = [
        CoverageRule(id: '1', contactId: 'g', start: 480, end: 780),
        CoverageRule(
          id: '2',
          contactId: 't',
          start: 1380,
          end: 240,
          enabled: false,
        ),
      ];

      await SecureCoverageRepository().save(rules);

      // Outro repositório, como se o app tivesse sido fechado e reaberto.
      expect(await SecureCoverageRepository().load(), rules);
    });
  });

  group('com repositório', () {
    test('load mostra as faixas guardadas e avisa quem ouve', () async {
      final repository = InMemoryCoverageRepository([
        const CoverageRule(id: '1', contactId: 'g', start: 480, end: 780),
      ]);
      controller = CoverageController(repository: repository);
      var avisos = 0;
      controller.addListener(() => avisos++);

      await controller.load();

      expect(controller.rules.single.contactId, 'g');
      expect(avisos, 1);
    });

    test('adicionar, editar, ligar e remover gravam no repositório', () async {
      final repository = InMemoryCoverageRepository();
      controller = CoverageController(repository: repository);

      addRule('g', '8:00', '13:00');
      await settle();
      expect((await repository.load()).single.contactId, 'g');

      final id = controller.rules.single.id;
      controller.update(
        id,
        contactId: 'y',
        start: at('9:00'),
        end: at('12:00'),
      );
      await settle();
      expect((await repository.load()).single.contactId, 'y');

      controller.setEnabled(id, false);
      await settle();
      expect((await repository.load()).single.enabled, isFalse);

      controller.remove(id);
      await settle();
      expect(await repository.load(), isEmpty);
    });

    test('um novo controlador recupera o que o anterior gravou', () async {
      final repository = InMemoryCoverageRepository();
      CoverageController(repository: repository)
          .add(contactId: 'g', start: at('8:00'), end: at('13:00'));
      await settle();

      final second = CoverageController(repository: repository);
      await second.load();

      expect(second.rules.single.contactId, 'g');
    });

    test('recusa não grava nada', () async {
      final repository = InMemoryCoverageRepository();
      controller = CoverageController(repository: repository);
      addRule('g', '8:00', '13:00');
      await settle();

      addRule('y', '12:00', '14:00'); // cruza: recusada
      addRule('y', '9:00', '9:00'); // início = fim: recusada
      await settle();

      expect((await repository.load()).length, 1);
    });

    test('load descarta faixas guardadas com horário inválido', () async {
      controller = CoverageController(
        repository: InMemoryCoverageRepository([
          const CoverageRule(id: '1', contactId: 'g', start: 480, end: 780),
          const CoverageRule(id: '2', contactId: 'g', start: 500, end: 500),
          const CoverageRule(id: '3', contactId: 'g', start: 100, end: 5000),
        ]),
      );

      await controller.load();

      expect(controller.rules.map((r) => r.id), ['1']);
    });

    test('se a leitura falhar, começa sem faixas e o app não quebra', () async {
      controller = CoverageController(repository: _BrokenRepository());

      await controller.load();

      expect(controller.rules, isEmpty);
    });

    test('se a gravação falhar, a lista na tela continua certa', () async {
      controller = CoverageController(repository: _BrokenRepository());

      final error = addRule('g', '8:00', '13:00');
      await settle();

      expect(error, isNull);
      expect(controller.rules.length, 1);
    });
  });

  group('ready: esperar o carregamento', () {
    test('sem repositório, já está pronto', () async {
      await controller.ready; // não pode ficar esperando
    });

    test('antes de load(), já está pronto', () async {
      controller = CoverageController(repository: InMemoryCoverageRepository());

      await controller.ready;
    });

    test('depois de load(), só completa quando a leitura termina', () async {
      final slow = _SlowRepository();
      controller = CoverageController(repository: slow)..load();

      var pronto = false;
      unawaited(controller.ready.then((_) => pronto = true));
      await settle();
      expect(pronto, isFalse); // ainda lendo

      slow.finish([
        const CoverageRule(id: '1', contactId: 'g', start: 480, end: 780),
      ]);
      await settle();

      expect(pronto, isTrue);
      expect(controller.rules.length, 1);
    });

    test('se a leitura falhar, ready também completa', () async {
      controller = CoverageController(repository: _BrokenRepository())..load();

      await controller.ready;

      expect(controller.rules, isEmpty);
    });
  });

  test('fechar a tela durante o carregamento não quebra', () async {
    final slow = _SlowRepository();
    controller = CoverageController(repository: slow)..load();

    controller.dispose();
    slow.finish([
      const CoverageRule(id: '1', contactId: 'g', start: 480, end: 780),
    ]);

    await settle(); // não pode lançar erro por notificar um controlador morto
  });
}
