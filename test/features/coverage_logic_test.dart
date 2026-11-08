// Testa as regras do horário de cobertura, sem tela e sem relógio de verdade.
// A hora entra como "minutos desde a meia-noite": 8:00 = 480, 23:00 = 1380.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

// '8:30' -> 510. Deixa os testes legíveis.
int at(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

CoverageRule rule(
  String id,
  String contactId,
  String start,
  String end, {
  bool enabled = true,
}) => CoverageRule(
  id: id,
  contactId: contactId,
  start: at(start),
  end: at(end),
  enabled: enabled,
);

void main() {
  const gabriela = Contact(id: 'g', name: 'Gabriela', phone: '51999990001');
  const yasmin = Contact(id: 'y', name: 'Yasmin', phone: '51999990002');
  const milena = Contact(id: 'm', name: 'Milena', phone: '51999990003');
  const taina = Contact(id: 't', name: 'Tainá', phone: '51999990004');
  const arthur = Contact(id: 'a', name: 'Arthur', phone: '51999990005');
  const contacts = [gabriela, yasmin, milena, taina, arthur];

  // O exemplo do Figma: 5 faixas coladas que cobrem as 24 horas.
  final figma = [
    rule('1', 'g', '8:00', '13:00'),
    rule('2', 'y', '13:00', '18:00'),
    rule('3', 'm', '18:00', '23:00'),
    rule('4', 't', '23:00', '4:00'),
    rule('5', 'a', '4:00', '8:00'),
  ];

  group('trechos da faixa', () {
    test('faixa comum é um trecho só', () {
      expect(rule('1', 'g', '8:00', '13:00').spans, [(start: 480, end: 780)]);
    });

    test('faixa que atravessa a meia-noite vira dois trechos', () {
      expect(rule('1', 'g', '23:00', '4:00').spans, [
        (start: 1380, end: 1440),
        (start: 0, end: 240),
      ]);
    });

    test('fim às 0:00 é a própria meia-noite: um trecho só', () {
      expect(rule('1', 'g', '18:00', '0:00').spans, [(start: 1080, end: 1440)]);
    });
  });

  group('ruleCovers: início conta, fim não', () {
    final day = rule('1', 'g', '8:00', '13:00');

    test('bordas da faixa comum', () {
      expect(ruleCovers(day, at('7:59')), isFalse);
      expect(ruleCovers(day, at('8:00')), isTrue);
      expect(ruleCovers(day, at('12:59')), isTrue);
      expect(ruleCovers(day, at('13:00')), isFalse);
    });

    test('bordas da faixa que atravessa a meia-noite (23:00 às 4:00)', () {
      final night = rule('1', 't', '23:00', '4:00');

      expect(ruleCovers(night, at('22:59')), isFalse);
      expect(ruleCovers(night, at('23:00')), isTrue);
      expect(ruleCovers(night, at('23:59')), isTrue);
      expect(ruleCovers(night, at('0:00')), isTrue);
      expect(ruleCovers(night, at('3:59')), isTrue);
      expect(ruleCovers(night, at('4:00')), isFalse);
      expect(ruleCovers(night, at('12:00')), isFalse);
    });

    test('faixa até a meia-noite cobre 23:59 e não cobre 0:00', () {
      final evening = rule('1', 'm', '18:00', '0:00');

      expect(ruleCovers(evening, at('23:59')), isTrue);
      expect(ruleCovers(evening, at('0:00')), isFalse);
    });

    test('faixa desligada não cobre nada', () {
      expect(
        ruleCovers(
          rule('1', 'g', '8:00', '13:00', enabled: false),
          at('10:00'),
        ),
        isFalse,
      );
    });
  });

  group('contactForTime: quem seria ligado', () {
    Contact? who(String hhmm, [List<CoverageRule>? rules]) => contactForTime(
      rules: rules ?? figma,
      contacts: contacts,
      minute: at(hhmm),
    );

    test('escolhe o contato da faixa de cada hora (exemplo do Figma)', () {
      expect(who('10:00'), gabriela);
      expect(who('15:30'), yasmin);
      expect(who('20:00'), milena);
      expect(who('1:00'), taina);
      expect(who('5:00'), arthur);
    });

    test('nas bordas entre faixas coladas, a hora pertence à seguinte', () {
      expect(who('7:59'), arthur);
      expect(who('8:00'), gabriela);
      expect(who('12:59'), gabriela);
      expect(who('13:00'), yasmin);
      expect(who('17:59'), yasmin);
      expect(who('18:00'), milena);
      expect(who('22:59'), milena);
      expect(who('23:00'), taina);
      expect(who('3:59'), taina);
      expect(who('4:00'), arthur);
    });

    test('meia-noite e 23:59 caem na faixa que atravessa a madrugada', () {
      expect(who('0:00'), taina);
      expect(who('23:59'), taina);
    });

    test('sem nenhuma faixa, liga para o primeiro da lista', () {
      expect(who('10:00', const []), gabriela);
    });

    test('fora das faixas, liga para o primeiro da lista', () {
      final onlyMorning = [rule('1', 'y', '8:00', '13:00')];

      expect(who('9:00', onlyMorning), yasmin);
      expect(who('20:00', onlyMorning), gabriela); // buraco: o primeiro
    });

    test('faixa desligada é ignorada', () {
      final off = [rule('1', 'y', '8:00', '13:00', enabled: false)];

      expect(who('9:00', off), gabriela);
    });

    test('faixa de contato removido é ignorada', () {
      final orphan = [
        rule('1', 'removido', '8:00', '13:00'),
        rule('2', 'y', '8:00', '13:00'),
      ];

      // A faixa órfã não "rouba" a hora: vale a seguinte.
      expect(who('9:00', orphan), yasmin);
    });

    test('só com faixa órfã, volta ao primeiro da lista', () {
      expect(who('9:00', [rule('1', 'removido', '8:00', '13:00')]), gabriela);
    });

    test('sem contatos, ninguém', () {
      expect(
        contactForTime(rules: figma, contacts: const [], minute: at('10:00')),
        isNull,
      );
    });

    test('o mesmo contato pode ter duas faixas', () {
      final twice = [
        rule('1', 'y', '8:00', '10:00'),
        rule('2', 'y', '20:00', '22:00'),
      ];

      expect(who('9:00', twice), yasmin);
      expect(who('21:00', twice), yasmin);
      expect(who('15:00', twice), gabriela);
    });
  });

  group('findOverlap: cruzamento entre faixas ligadas', () {
    test('faixas coladas não se cruzam', () {
      expect(
        findOverlap(rule('x', 'g', '13:00', '18:00'), [
          rule('1', 'y', '8:00', '13:00'),
        ]),
        isNull,
      );
      expect(
        findOverlap(rule('x', 'g', '4:00', '8:00'), [
          rule('1', 'y', '23:00', '4:00'),
        ]),
        isNull,
      );
    });

    test('devolve a faixa com a qual cruza', () {
      final other = rule('1', 'y', '8:00', '13:00');

      expect(findOverlap(rule('x', 'g', '12:00', '14:00'), [other]), other);
      expect(findOverlap(rule('x', 'g', '9:00', '10:00'), [other]), other);
      expect(findOverlap(rule('x', 'g', '7:00', '14:00'), [other]), other);
    });

    test('cruza também quando uma delas atravessa a meia-noite', () {
      final night = rule('1', 't', '23:00', '4:00');

      expect(findOverlap(rule('x', 'g', '3:00', '5:00'), [night]), night);
      expect(findOverlap(rule('x', 'g', '22:00', '23:30'), [night]), night);
      expect(findOverlap(rule('x', 'g', '0:30', '1:00'), [night]), night);
    });

    test('duas faixas que atravessam a meia-noite se cruzam', () {
      final a = rule('1', 'g', '22:00', '2:00');

      expect(findOverlap(rule('x', 'y', '23:00', '5:00'), [a]), a);
    });

    test(
      'faixa desligada nunca conflita (nem como candidata nem como outra)',
      () {
        expect(
          findOverlap(rule('x', 'g', '9:00', '10:00', enabled: false), [
            rule('1', 'y', '8:00', '13:00'),
          ]),
          isNull,
        );
        expect(
          findOverlap(rule('x', 'g', '9:00', '10:00'), [
            rule('1', 'y', '8:00', '13:00', enabled: false),
          ]),
          isNull,
        );
      },
    );

    test('ao editar, a própria faixa (mesmo id) é ignorada', () {
      final self = rule('1', 'y', '8:00', '13:00');

      expect(findOverlap(self.copyWith(end: at('14:00')), [self]), isNull);
    });
  });

  group('cobertura e buracos', () {
    test('as 5 faixas do Figma cobrem as 24 horas, sem buracos', () {
      expect(coveredMinutes(figma), minutesPerDay);
      expect(gaps(figma), isEmpty);
      expect(coveredSpans(figma), [(start: 0, end: minutesPerDay)]);
    });

    test('sem faixas, o dia inteiro é um buraco', () {
      expect(coveredMinutes(const []), 0);
      expect(gaps(const []), [(start: 0, end: minutesPerDay)]);
    });

    test('desligar uma faixa abre um buraco do tamanho dela', () {
      final off = [
        for (final r in figma)
          r.id == '2' ? r.copyWith(enabled: false) : r, // 13:00 às 18:00
      ];

      expect(gaps(off), [(start: at('13:00'), end: at('18:00'))]);
      expect(coveredMinutes(off), minutesPerDay - 5 * 60);
    });

    test('os buracos incluem o começo e o fim do dia', () {
      final middle = [rule('1', 'g', '8:00', '18:00')];

      expect(gaps(middle), [
        (start: 0, end: at('8:00')),
        (start: at('18:00'), end: minutesPerDay),
      ]);
    });

    test('faixas coladas viram um trecho coberto só', () {
      final rules = [
        rule('1', 'g', '8:00', '13:00'),
        rule('2', 'y', '13:00', '18:00'),
      ];

      expect(coveredSpans(rules), [(start: at('8:00'), end: at('18:00'))]);
    });

    test(
      'uma faixa que atravessa a meia-noite cobre as duas pontas do dia',
      () {
        final night = [rule('1', 't', '23:00', '4:00')];

        expect(coveredSpans(night), [
          (start: 0, end: at('4:00')),
          (start: at('23:00'), end: minutesPerDay),
        ]);
        expect(gaps(night), [(start: at('4:00'), end: at('23:00'))]);
        expect(coveredMinutes(night), 5 * 60);
      },
    );

    test('faixa desligada não entra na cobertura', () {
      expect(
        coveredMinutes([rule('1', 'g', '8:00', '13:00', enabled: false)]),
        0,
      );
    });
  });

  group('validateRange', () {
    test('aceita faixas comuns e as que atravessam a meia-noite', () {
      expect(validateRange(at('8:00'), at('13:00')), isNull);
      expect(validateRange(at('23:00'), at('4:00')), isNull);
      expect(validateRange(at('18:00'), at('0:00')), isNull);
    });

    test('recusa início igual ao fim', () {
      expect(validateRange(at('8:00'), at('8:00')), CoverageError.sameStartEnd);
    });

    test('recusa hora fora do dia', () {
      expect(validateRange(-1, 100), CoverageError.invalidTime);
      expect(validateRange(100, minutesPerDay), CoverageError.invalidTime);
      expect(validateRange(minutesPerDay, 100), CoverageError.invalidTime);
    });
  });

  group('periodOf: ícone pelo início da faixa', () {
    test('reproduz o Figma', () {
      expect(periodOf(at('8:00')), CoveragePeriod.day);
      expect(periodOf(at('13:00')), CoveragePeriod.day);
      expect(periodOf(at('18:00')), CoveragePeriod.sunset);
      expect(periodOf(at('23:00')), CoveragePeriod.night);
      expect(periodOf(at('4:00')), CoveragePeriod.night);
    });

    test('bordas entre os períodos', () {
      expect(periodOf(at('5:59')), CoveragePeriod.night);
      expect(periodOf(at('6:00')), CoveragePeriod.day);
      expect(periodOf(at('17:59')), CoveragePeriod.day);
      expect(periodOf(at('18:00')), CoveragePeriod.sunset);
      expect(periodOf(at('22:59')), CoveragePeriod.sunset);
      expect(periodOf(at('23:00')), CoveragePeriod.night);
      expect(periodOf(at('0:00')), CoveragePeriod.night);
    });
  });

  group('texto da hora', () {
    test('hora sem zero à esquerda e minutos com dois dígitos', () {
      expect(formatMinutes(at('8:00')), '8:00');
      expect(formatMinutes(at('0:00')), '0:00');
      expect(formatMinutes(at('23:00')), '23:00');
      expect(formatMinutes(at('8:05')), '8:05');
      expect(formatMinutes(at('13:45')), '13:45');
    });

    test('faixa como no Figma', () {
      expect(formatRange(rule('1', 'g', '8:00', '13:00')), '8:00 - 13:00');
      expect(formatRange(rule('1', 't', '23:00', '4:00')), '23:00 - 4:00');
    });

    test('minuteOfDay converte um instante', () {
      expect(minuteOfDay(DateTime(2026, 11, 7, 14, 32)), at('14:32'));
      expect(minuteOfDay(DateTime(2026, 11, 7, 0, 0)), 0);
      expect(minuteOfDay(DateTime(2026, 11, 7, 23, 59)), at('23:59'));
    });
  });

  group('CoverageRule', () {
    test('vai e volta do JSON', () {
      final original = rule('1', 'g', '23:00', '4:00', enabled: false);

      expect(CoverageRule.fromJson(original.toJson()), original);
    });

    test('faixa gravada sem o campo "enabled" vale como ligada', () {
      final loaded = CoverageRule.fromJson({
        'id': '1',
        'contactId': 'g',
        'start': 480,
        'end': 780,
      });

      expect(loaded.enabled, isTrue);
    });

    test('copyWith troca só o que for informado', () {
      final original = rule('1', 'g', '8:00', '13:00');
      final changed = original.copyWith(contactId: 'y', enabled: false);

      expect(changed.id, '1');
      expect(changed.contactId, 'y');
      expect(changed.start, original.start);
      expect(changed.enabled, isFalse);
    });

    test('toString não revela contato nem horário', () {
      expect(rule('abc', 'g', '8:00', '13:00').toString(), 'CoverageRule(abc)');
    });
  });
}
