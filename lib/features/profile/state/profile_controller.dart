// O nome da usuária e a saudação da Home ("Olá, Ana").
//
// Um ChangeNotifier como os outros: as telas assinam, e a Home se atualiza quando
// o nome muda. As regras ficam aqui, testáveis sem tela:
//   - o nome é opcional;
//   - tem de 1 a 30 letras (sem espaços sobrando nas pontas);
//   - "pular" é lembrado (a pergunta não volta toda vez).
//
// O nome é dado pessoal: nunca é impresso em registros (logs).

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/profile/data/profile_repository.dart';

enum ProfileError { empty, tooLong }

class ProfileController extends ChangeNotifier {
  static const maxNameLength = 30;

  ProfileController({this.repository});

  final ProfileRepository? repository;

  // null = ainda não perguntou; '' = perguntou e a usuária pulou.
  String? _name;
  bool _loadFailed = false;
  bool _disposed = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future.value();

  // Completa quando o nome guardado já foi lido. Quem decide a próxima tela (a
  // splash) espera por isto em vez de ler um valor ainda vazio.
  Future<void> get ready => _loading ?? Future.value();

  Future<void> load() => _loading = _load();

  Future<void> _load() async {
    final repository = this.repository;
    if (repository == null) return;

    try {
      final saved = await repository.loadName();
      if (_disposed) return;
      _name = saved;
      notifyListeners();
    } catch (_) {
      // Armazenamento indisponível: o app segue sem nome e NÃO volta a perguntar
      // (ver `asked`), em vez de travar na tela do nome.
      _loadFailed = true;
    }
  }

  // O ADA já perguntou o nome? (A leitura que falha conta como "sim": a pergunta
  // nunca pode atrapalhar o uso do app.)
  bool get asked => _name != null || _loadFailed;

  String get name => _name ?? '';
  bool get hasName => name.isNotEmpty;

  // "Olá, Ana" ou, sem nome, só "Olá!".
  String get greeting => hasName ? 'Olá, $name' : 'Olá!';

  // Padrão do projeto: null = deu certo; senão, o motivo da recusa.
  ProfileError? save(String raw) {
    // Junta espaços repetidos: "  Ana   Maria " -> "Ana Maria".
    final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return ProfileError.empty;
    if (name.length > maxNameLength) return ProfileError.tooLong;

    _set(name);
    return null;
  }

  // A usuária prefere não informar (ou quer tirar o nome): fica "já perguntei".
  void skip() => _set('');

  void _set(String value) {
    _name = value;
    notifyListeners();

    final repository = this.repository;
    if (repository == null) return;
    _pendingSave = _pendingSave
        .then((_) => repository.saveName(value))
        .catchError((_) {}); // falha ao gravar não derruba o app
  }

  // "Apagar meus dados": esquece o nome e o "já perguntei", na memória e no
  // armazenamento. Espera as gravações pendentes para a mais antiga não vencer.
  Future<void> clear() async {
    _name = null;
    _loadFailed = false;
    notifyListeners();

    final repository = this.repository;
    if (repository == null) return;
    await _pendingSave;
    await repository.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
