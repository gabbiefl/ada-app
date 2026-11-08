// Guarda se a usuária já viu o onboarding (as 3 telas de apresentação).
//
// É um "sim ou não" sem nenhum dado pessoal. Usa o mesmo padrão dos outros
// repositórios (contrato + armazenamento seguro + memória para testes), então não
// precisa de pacote novo.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class OnboardingRepository {
  Future<bool> hasSeen();
  Future<void> markSeen();

  // Volta ao estado de "recém-instalado": o onboarding aparece de novo.
  Future<void> reset();
}

class SecureOnboardingRepository implements OnboardingRepository {
  SecureOnboardingRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'ada_onboarding_seen';

  @override
  Future<bool> hasSeen() async => await _storage.read(key: _key) == 'true';

  @override
  Future<void> markSeen() => _storage.write(key: _key, value: 'true');

  @override
  Future<void> reset() => _storage.delete(key: _key);
}

// Guarda só na memória: some ao fechar o app. Usado nos testes.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository([this._seen = false]);

  bool _seen;

  @override
  Future<bool> hasSeen() async => _seen;

  @override
  Future<void> markSeen() async => _seen = true;

  @override
  Future<void> reset() async => _seen = false;
}
