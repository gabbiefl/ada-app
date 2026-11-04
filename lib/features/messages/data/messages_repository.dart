// Onde os textos editados das mensagens ficam guardados.
//
// Mesmo desenho do ContactsRepository (Fase 5): um contrato abstrato, uma
// versão para o aparelho e uma em memória para os testes. Só os textos EDITADOS
// são guardados; o que não foi editado vale o padrão do MessageKind.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ada_app/features/messages/models/message_kind.dart';

abstract class MessagesRepository {
  Future<Map<MessageKind, String>> load();
  Future<void> save(Map<MessageKind, String> custom);
}

// Armazenamento seguro: o texto pode ter dado pessoal (ex.: "estou na casa da…").
class SecureMessagesRepository implements MessagesRepository {
  SecureMessagesRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Tudo em UMA entrada: um JSON do tipo {"danger": "texto", ...}.
  static const _key = 'ada_messages';

  @override
  Future<Map<MessageKind, String>> load() async {
    final text = await _storage.read(key: _key);
    if (text == null || text.isEmpty) return {};

    final json = jsonDecode(text) as Map<String, dynamic>;
    final byName = MessageKind.values.asNameMap();
    return {
      for (final entry in json.entries)
        // Nome desconhecido (ex.: de uma versão futura) é ignorado.
        if (byName[entry.key] != null && entry.value is String)
          byName[entry.key]!: entry.value as String,
    };
  }

  @override
  Future<void> save(Map<MessageKind, String> custom) {
    final json = {for (final e in custom.entries) e.key.name: e.value};
    return _storage.write(key: _key, value: jsonEncode(json));
  }
}

// Só na memória: some ao fechar o app. Usado nos testes.
class InMemoryMessagesRepository implements MessagesRepository {
  InMemoryMessagesRepository([Map<MessageKind, String> initial = const {}])
    : _custom = Map.of(initial);

  Map<MessageKind, String> _custom;

  @override
  Future<Map<MessageKind, String>> load() async => Map.of(_custom);

  @override
  Future<void> save(Map<MessageKind, String> custom) async {
    _custom = Map.of(custom);
  }
}
