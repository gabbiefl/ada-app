// Guarda as faixas do horário de cobertura e aplica as regras delas.
//
// Mesmo padrão dos outros controladores (contatos, mensagens): um ChangeNotifier
// que as telas assinam, com o retorno "null = deu certo, senão o motivo da
// recusa". As contas de horário ficam nas funções puras de coverage_logic.dart;
// aqui ficam a lista, a validação e a gravação.
//
// Regras:
//   - o horário precisa ser válido (início diferente do fim);
//   - o contato escolhido precisa existir;
//   - duas faixas LIGADAS não podem se cruzar (uma pessoa por hora). Faixas
//     desligadas ficam salvas e não conflitam com nada;
//   - para ligar de volta uma faixa desligada, ela também não pode cruzar.
//
// As faixas são carregadas de um CoverageRepository ao abrir o app (load) e
// gravadas de novo a cada mudança. Sem repositório, vivem só na memória.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

class CoverageController extends ChangeNotifier {
  // `contactExists` é recebido de fora (injeção de dependência): o controlador
  // não conhece a rede de contatos, só pergunta "este id existe?". No app, quem
  // responde é o ContactsController; nos testes, uma função simples.
  CoverageController({this.repository, bool Function(String id)? contactExists})
    : _contactExists = contactExists ?? ((_) => true);

  final CoverageRepository? repository;
  final bool Function(String id) _contactExists;
  final List<CoverageRule> _rules = [];

  // Fila de gravações: cada uma só começa quando a anterior termina.
  Future<void> _pendingSave = Future.value();
  bool _disposed = false;

  // O carregamento em andamento (ou já feito). Quem precisa das faixas prontas,
  // como o alerta, espera por `ready` em vez de ler uma lista ainda vazia.
  Future<void>? _loading;

  // Completa quando as faixas guardadas já foram lidas. Sem repositório, ou
  // antes de load() ser chamado, já está pronto.
  Future<void> get ready => _loading ?? Future.value();

  // Lê as faixas guardadas. Chamado uma vez, ao abrir o app.
  Future<void> load() => _loading = _load();

  Future<void> _load() async {
    final repository = this.repository;
    if (repository == null) return;

    try {
      final saved = await repository.load();
      if (_disposed) return;
      _rules
        ..clear()
        // Dado guardado não é garantido válido: descarta faixa com horário ruim.
        ..addAll(saved.where((r) => validateRange(r.start, r.end) == null));
      notifyListeners();
    } catch (_) {
      // Dado ilegível ou armazenamento indisponível: começa sem faixas (liga
      // para o primeiro da lista). Nada é impresso.
    }
  }

  // Avisa as telas e grava as faixas. Chamado depois de toda mudança.
  void _changed() {
    notifyListeners();

    final repository = this.repository;
    if (repository == null) return;

    // Cópia neste instante: se mudar de novo antes de gravar, esta gravação
    // continua com os dados certos.
    final snapshot = List<CoverageRule>.of(_rules);
    _pendingSave = _pendingSave
        .then((_) => repository.save(snapshot))
        .catchError((_) {}); // falha ao gravar não derruba o app
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Visão só de leitura, na ordem em que as faixas foram criadas.
  UnmodifiableListView<CoverageRule> get rules => UnmodifiableListView(_rules);

  CoverageRule? byId(String id) {
    for (final rule in _rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  // A faixa LIGADA com a qual este horário cruzaria, ou null. A tela usa para
  // dizer "cruza com 8:00 - 13:00 (Gabriela)". [ignoreId] é a faixa que está
  // sendo editada (ela não conflita consigo mesma).
  CoverageRule? findConflict({
    String? ignoreId,
    required int start,
    required int end,
  }) {
    final candidate = CoverageRule(
      id: ignoreId ?? '',
      contactId: '',
      start: start,
      end: end,
    );
    return findOverlap(candidate, _rules);
  }

  // Padrão de retorno: null = deu certo; senão, o motivo da recusa.
  CoverageError? add({
    required String contactId,
    required int start,
    required int end,
    bool enabled = true,
  }) {
    final error = _check(contactId: contactId, start: start, end: end);
    if (error != null) return error;

    final rule = CoverageRule(
      id: _newId(),
      contactId: contactId,
      start: start,
      end: end,
      enabled: enabled,
    );
    // Faixa nova já ligada não pode cruzar; desligada entra sempre.
    if (findOverlap(rule, _rules) != null) return CoverageError.overlaps;

    _rules.add(rule);
    _changed();
    return null;
  }

  CoverageError? update(
    String id, {
    required String contactId,
    required int start,
    required int end,
  }) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index == -1) return CoverageError.notFound;

    final error = _check(contactId: contactId, start: start, end: end);
    if (error != null) return error;

    final updated = _rules[index].copyWith(
      contactId: contactId,
      start: start,
      end: end,
    );
    // findOverlap ignora a própria faixa (mesmo id).
    if (findOverlap(updated, _rules) != null) return CoverageError.overlaps;

    _rules[index] = updated;
    _changed();
    return null;
  }

  // Liga ou desliga uma faixa. Desligar sempre pode; ligar só se não cruzar com
  // outra faixa ligada.
  CoverageError? setEnabled(String id, bool enabled) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index == -1) return CoverageError.notFound;
    if (_rules[index].enabled == enabled) return null; // nada a mudar

    final updated = _rules[index].copyWith(enabled: enabled);
    if (findOverlap(updated, _rules) != null) return CoverageError.overlaps;

    _rules[index] = updated;
    _changed();
    return null;
  }

  CoverageError? remove(String id) {
    final before = _rules.length;
    _rules.removeWhere((r) => r.id == id);
    if (_rules.length == before) return CoverageError.notFound;
    _changed();
    return null;
  }

  // Apaga as faixas de contatos que não existem mais (a tela chama ao abrir).
  // Só avisa e grava se algo foi apagado. Devolve quantas foram.
  int pruneFor(Iterable<String> contactIds) {
    final valid = contactIds.toSet();
    final before = _rules.length;
    _rules.removeWhere((r) => !valid.contains(r.contactId));
    final removed = before - _rules.length;
    if (removed > 0) _changed();
    return removed;
  }

  // Confere de novo as regras de horário e de contato: o controlador não deve
  // confiar que a tela já validou.
  CoverageError? _check({
    required String contactId,
    required int start,
    required int end,
  }) {
    final range = validateRange(start, end);
    if (range != null) return range;
    if (!_contactExists(contactId)) return CoverageError.contactMissing;
    return null;
  }

  // Id baseado no relógio. O laço garante que não repete.
  String _newId() {
    var id = DateTime.now().microsecondsSinceEpoch;
    while (_rules.any((r) => r.id == '$id')) {
      id++;
    }
    return '$id';
  }
}
