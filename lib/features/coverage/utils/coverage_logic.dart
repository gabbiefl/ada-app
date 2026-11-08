// As regras do horário de cobertura, como funções PURAS.
//
// "Pura" = só recebe dados e devolve um resultado: sem tela, sem relógio escondido
// e sem armazenamento. Por isso dá para testar cada borda (22:59, 23:00, 3:59,
// 4:00...) sem esperar a hora chegar. A hora atual entra como parâmetro.
//
// Tudo aqui trabalha com os TRECHOS do dia (Span) de cada faixa. Uma faixa que
// atravessa a meia-noite já vem repartida em dois trechos, então a mesma regra
// simples serve para escolher o contato, achar cruzamentos e achar buracos.

import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';

// Motivos pelos quais uma faixa pode ser recusada.
enum CoverageError {
  invalidTime, // hora fora de 0:00 a 23:59
  sameStartEnd, // início igual ao fim (ambíguo)
  overlaps, // cruza com outra faixa ligada
  contactMissing, // o contato escolhido não existe mais
  notFound, // a faixa não existe
}

// Minutos desde a meia-noite de um instante: 14:32 -> 872.
int minuteOfDay(DateTime time) => time.hour * 60 + time.minute;

// O horário da faixa é aceitável? null = sim; senão, o motivo.
CoverageError? validateRange(int start, int end) {
  if (start < 0 || start >= minutesPerDay) return CoverageError.invalidTime;
  if (end < 0 || end >= minutesPerDay) return CoverageError.invalidTime;
  if (start == end) return CoverageError.sameStartEnd;
  return null;
}

// A faixa cobre este minuto do dia? (Só vale se estiver ligada.)
bool ruleCovers(CoverageRule rule, int minute) {
  if (!rule.enabled) return false;
  return rule.spans.any((s) => minute >= s.start && minute < s.end);
}

// Quem seria ligado neste minuto: o contato da faixa ligada que o cobre. Sem
// nenhuma faixa para este minuto, vale o PRIMEIRO da lista (como era antes da
// Fase 10). Sem contatos, ninguém.
//
// Faixas de contatos que não existem mais são ignoradas: a regra nunca liga para
// quem foi removido da rede.
Contact? contactForTime({
  required List<CoverageRule> rules,
  required List<Contact> contacts,
  required int minute,
}) {
  if (contacts.isEmpty) return null;

  for (final rule in rules) {
    if (!ruleCovers(rule, minute)) continue;
    for (final contact in contacts) {
      if (contact.id == rule.contactId) return contact;
    }
  }
  return contacts.first;
}

// Dois conjuntos de trechos se cruzam? Trechos colados (até 13:00 e a partir de
// 13:00) NÃO se cruzam, porque o fim não conta.
bool _spansIntersect(List<Span> a, List<Span> b) {
  for (final x in a) {
    for (final y in b) {
      if (x.start < y.end && y.start < x.end) return true;
    }
  }
  return false;
}

// A faixa [candidate] cruza com alguma das [others] ligadas? Devolve a primeira
// que cruza, ou null. Uma faixa desligada nunca conflita (nem como candidata,
// nem como já existente), e a própria faixa (mesmo id) é ignorada ao editar.
CoverageRule? findOverlap(
  CoverageRule candidate,
  Iterable<CoverageRule> others,
) {
  if (!candidate.enabled) return null;
  for (final other in others) {
    if (other.id == candidate.id || !other.enabled) continue;
    if (_spansIntersect(candidate.spans, other.spans)) return other;
  }
  return null;
}

// Os trechos do dia cobertos por alguma faixa ligada, já juntados e em ordem
// (8:00-13:00 e 13:00-18:00 viram 8:00-18:00).
List<Span> coveredSpans(Iterable<CoverageRule> rules) {
  final spans = <Span>[
    for (final rule in rules)
      if (rule.enabled) ...rule.spans,
  ]..sort((a, b) => a.start.compareTo(b.start));

  final merged = <Span>[];
  for (final span in spans) {
    if (merged.isNotEmpty && span.start <= merged.last.end) {
      final last = merged.removeLast();
      merged.add((
        start: last.start,
        end: span.end > last.end ? span.end : last.end,
      ));
    } else {
      merged.add(span);
    }
  }
  return merged;
}

// Os BURACOS: trechos do dia que nenhuma faixa ligada cobre.
List<Span> gaps(Iterable<CoverageRule> rules) {
  final holes = <Span>[];
  var cursor = 0;
  for (final span in coveredSpans(rules)) {
    if (span.start > cursor) holes.add((start: cursor, end: span.start));
    cursor = span.end;
  }
  if (cursor < minutesPerDay) holes.add((start: cursor, end: minutesPerDay));
  return holes;
}

// Quantos minutos do dia estão cobertos.
int coveredMinutes(Iterable<CoverageRule> rules) =>
    coveredSpans(rules).fold(0, (sum, s) => sum + (s.end - s.start));

// O período do dia, só para escolher o ícone da faixa.
enum CoveragePeriod { day, sunset, night }

// Pelo INÍCIO da faixa: sol das 6h às 17h, pôr do sol das 18h às 22h e lua das
// 23h às 5h (como no Figma: 8h e 13h sol, 18h pôr do sol, 23h e 4h lua).
CoveragePeriod periodOf(int startMinute) {
  final hour = startMinute ~/ 60;
  if (hour >= 6 && hour < 18) return CoveragePeriod.day;
  if (hour >= 18 && hour < 23) return CoveragePeriod.sunset;
  return CoveragePeriod.night;
}

// 480 -> '8:00' (a hora sem zero à esquerda, como no Figma).
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

// '8:00 - 13:00'
String formatRange(CoverageRule rule) =>
    '${formatMinutes(rule.start)} - ${formatMinutes(rule.end)}';
