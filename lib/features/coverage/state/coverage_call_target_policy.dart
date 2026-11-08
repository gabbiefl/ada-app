// A regra de "quem ligar" do Perigo, agora pelo HORÁRIO DE COBERTURA.
//
// O alerta (Fase 9) já pergunta a uma CallTargetPolicy "para quem ligo?". Até a
// Fase 10 a resposta era "o primeiro da lista". Esta política responde com o
// contato da faixa que cobre a hora atual, e cai no primeiro da lista quando
// nenhuma faixa ligada cobre a hora. O alerta não mudou nada: só trocamos a regra
// que ele recebe (é para isso que serve uma interface).
//
// O RELÓGIO é recebido de fora (uma função que devolve "agora"). No app é o
// DateTime.now; nos testes, uma hora fixa. Sem isso, não dá para testar "às 23h"
// sem esperar as 23h.
//
// A política lê as faixas NA HORA de perguntar (não guarda uma cópia): se a
// usuária mudar o horário, a próxima ligação já usa a regra nova.

import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

class CoverageCallTargetPolicy implements CallTargetPolicy {
  CoverageCallTargetPolicy({required this.coverage, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CoverageController coverage;
  final DateTime Function() _now;

  @override
  Contact? pick(List<Contact> contacts) => contactForTime(
    rules: coverage.rules,
    contacts: contacts,
    minute: minuteOfDay(_now()),
  );
}
