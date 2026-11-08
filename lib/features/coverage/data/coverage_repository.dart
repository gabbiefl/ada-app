// Onde as faixas do horário de cobertura ficam guardadas.
//
// Mesmo desenho do ContactsRepository e do MessagesRepository: um contrato
// abstrato, uma versão para o aparelho e uma em memória para os testes. O
// controlador não sabe onde os dados ficam.
//
// As faixas guardam só o id do contato e as horas, nunca o telefone.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ada_app/features/coverage/models/coverage_rule.dart';

abstract class CoverageRepository {
  Future<List<CoverageRule>> load();
  Future<void> save(List<CoverageRule> rules);
}

// Armazenamento seguro do aparelho (o mesmo dos contatos).
class SecureCoverageRepository implements CoverageRepository {
  SecureCoverageRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Todas as faixas em UMA entrada: uma lista JSON gravada como texto.
  static const _key = 'ada_coverage';

  @override
  Future<List<CoverageRule>> load() async {
    final text = await _storage.read(key: _key);
    if (text == null || text.isEmpty) return [];

    final items = jsonDecode(text) as List<dynamic>;
    return [
      for (final item in items)
        CoverageRule.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<CoverageRule> rules) {
    final text = jsonEncode([for (final r in rules) r.toJson()]);
    return _storage.write(key: _key, value: text);
  }
}

// Só na memória: some ao fechar o app. Usado nos testes.
class InMemoryCoverageRepository implements CoverageRepository {
  InMemoryCoverageRepository([List<CoverageRule> initial = const []])
    : _rules = List.of(initial);

  List<CoverageRule> _rules;

  @override
  Future<List<CoverageRule>> load() async => List.of(_rules);

  @override
  Future<void> save(List<CoverageRule> rules) async {
    _rules = List.of(rules);
  }
}
