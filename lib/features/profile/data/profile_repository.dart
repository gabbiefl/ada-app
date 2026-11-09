// Onde o nome da usuária fica guardado.
//
// Mesmo padrão dos outros repositórios (contrato + armazenamento seguro + memória
// para os testes). O nome é um dado pessoal, então vai para o cofre cifrado.
//
// Três estados com UMA chave só:
//   - sem a chave (null): o ADA ainda não perguntou o nome;
//   - texto vazio: perguntou, e a usuária preferiu não informar (pulou);
//   - texto: o nome (ou apelido).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ProfileRepository {
  Future<String?> loadName();
  Future<void> saveName(String name);

  // Apaga o nome e o "já perguntei": a pergunta volta a aparecer.
  Future<void> clear();
}

class SecureProfileRepository implements ProfileRepository {
  SecureProfileRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'ada_profile_name';

  @override
  Future<String?> loadName() => _storage.read(key: _key);

  @override
  Future<void> saveName(String name) => _storage.write(key: _key, value: name);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

// Guarda só na memória: some ao fechar o app. Usado nos testes.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([this._name]);

  String? _name;

  @override
  Future<String?> loadName() async => _name;

  @override
  Future<void> saveName(String name) async => _name = name;

  @override
  Future<void> clear() async => _name = null;
}
