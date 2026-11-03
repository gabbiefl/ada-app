// Onde os contatos ficam guardados.
//
// ContactsRepository é um "contrato" (classe abstrata): diz O QUE se pode fazer
// (carregar e salvar), sem dizer COMO. Assim o ContactsController não sabe se os
// dados vão para o armazenamento seguro, para a memória (nos testes) ou para
// outro lugar no futuro. Trocar o armazenamento não mexe nas regras da rede.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ada_app/features/contacts/models/contact.dart';

abstract class ContactsRepository {
  // Future: o resultado chega "depois", porque ler e gravar levam tempo.
  Future<List<Contact>> load();
  Future<void> save(List<Contact> contacts);
}

// Guarda no armazenamento seguro do aparelho. No Android, a chave de
// criptografia fica no Keystore, então os telefones não ficam em texto aberto.
// (No Chrome o navegador não oferece essa proteção: serve só para testar o fluxo.)
class SecureContactsRepository implements ContactsRepository {
  SecureContactsRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Todos os contatos ficam em UMA entrada: uma lista JSON gravada como texto.
  static const _key = 'ada_contacts';

  @override
  Future<List<Contact>> load() async {
    final text = await _storage.read(key: _key);
    if (text == null || text.isEmpty) return [];

    final items = jsonDecode(text) as List<dynamic>;
    return [
      for (final item in items) Contact.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<Contact> contacts) {
    final text = jsonEncode([for (final c in contacts) c.toJson()]);
    return _storage.write(key: _key, value: text);
  }
}

// Guarda só na memória: some ao fechar o app. Usado nos testes.
class InMemoryContactsRepository implements ContactsRepository {
  InMemoryContactsRepository([List<Contact> initial = const []])
    : _contacts = List.of(initial);

  List<Contact> _contacts;

  @override
  Future<List<Contact>> load() async => List.of(_contacts);

  @override
  Future<void> save(List<Contact> contacts) async {
    _contacts = List.of(contacts);
  }
}
