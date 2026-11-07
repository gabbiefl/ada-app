// Guarda a rede de contatos de confiança e aplica as regras dela.
//
// Mesmo padrão do ModeController (Fase 4): um ChangeNotifier que as telas
// assinam. Aqui as regras de negócio ficam juntas e testáveis sem tela:
//   - no máximo 5 contatos;
//   - nome e telefone válidos;
//   - o mesmo telefone não entra duas vezes.
//
// A lista é carregada de um ContactsRepository ao abrir o app (load) e gravada
// de novo a cada mudança. Sem repositório, ela vive só na memória.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/validators/contact_validators.dart';

// Motivos pelos quais uma operação pode ser recusada. Um enum deixa claro que
// só existem estes casos, e a tela escolhe a mensagem de cada um.
enum ContactsError { limitReached, duplicatePhone, invalidData, notFound }

class ContactsController extends ChangeNotifier {
  static const maxContacts = 5;

  // O repositório é recebido de fora (injeção de dependência): no app é o
  // armazenamento seguro; nos testes, um repositório em memória.
  ContactsController({this.repository});

  final ContactsRepository? repository;
  final List<Contact> _contacts = [];

  // Fila de gravações: cada uma só começa quando a anterior termina, para a
  // última lista gravada ser sempre a mais nova.
  Future<void> _pendingSave = Future.value();
  bool _disposed = false;

  // O carregamento em andamento (ou já feito). Quem precisa dos dados prontos,
  // como o alerta, espera por `ready` em vez de ler uma lista ainda vazia.
  Future<void>? _loading;

  // Completa quando os contatos guardados já foram lidos. Sem repositório, ou
  // antes de load() ser chamado, já está pronto.
  Future<void> get ready => _loading ?? Future.value();

  // Lê os contatos guardados e mostra na tela. Chamado uma vez, ao abrir o app.
  // async/await: "espera" o armazenamento responder sem travar a tela.
  Future<void> load() => _loading = _load();

  Future<void> _load() async {
    final repository = this.repository;
    if (repository == null) return;

    try {
      final saved = await repository.load();
      if (_disposed) return;
      _contacts
        ..clear()
        ..addAll(saved.take(maxContacts));
      notifyListeners();
    } catch (_) {
      // Dado ilegível ou armazenamento indisponível: a rede começa vazia, em
      // vez de o app fechar. Nada é impresso: telefone é dado pessoal.
    }
  }

  // Avisa as telas e grava a lista nova. Chamado depois de toda mudança.
  void _changed() {
    notifyListeners();

    final repository = this.repository;
    if (repository == null) return;

    // Cópia da lista neste instante: se ela mudar de novo antes de gravar,
    // esta gravação continua com os dados certos.
    final snapshot = List<Contact>.of(_contacts);
    _pendingSave = _pendingSave
        .then((_) => repository.save(snapshot))
        .catchError((_) {}); // falha ao gravar não derruba o app
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Visão só de leitura: quem está de fora não consegue dar .add() na lista
  // (isso pularia as regras e o notifyListeners).
  UnmodifiableListView<Contact> get contacts => UnmodifiableListView(_contacts);

  int get count => _contacts.length;
  bool get isFull => count >= maxContacts;
  int get freeSlots => maxContacts - count;

  // Padrão de retorno: null = deu certo; senão, o motivo da recusa.
  // (o mesmo desenho dos validators do formulário).
  ContactsError? add({required String name, required String phone}) {
    if (_isInvalid(name, phone)) return ContactsError.invalidData;
    if (isFull) return ContactsError.limitReached;

    final digits = ContactValidators.digitsOnly(phone);
    if (_phoneInUse(digits)) return ContactsError.duplicatePhone;

    _contacts.add(Contact(id: _newId(), name: name.trim(), phone: digits));
    _changed();
    return null;
  }

  ContactsError? update(
    String id, {
    required String name,
    required String phone,
  }) {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index == -1) return ContactsError.notFound;
    if (_isInvalid(name, phone)) return ContactsError.invalidData;

    final digits = ContactValidators.digitsOnly(phone);
    // ignoreId: o contato pode manter o próprio telefone ao ser editado.
    if (_phoneInUse(digits, ignoreId: id)) return ContactsError.duplicatePhone;

    _contacts[index] = _contacts[index].copyWith(
      name: name.trim(),
      phone: digits,
    );
    _changed();
    return null;
  }

  ContactsError? remove(String id) {
    final before = _contacts.length;
    _contacts.removeWhere((c) => c.id == id);
    if (_contacts.length == before) return ContactsError.notFound;
    _changed();
    return null;
  }

  Contact? byId(String id) {
    for (final contact in _contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  // Confere de novo as regras de nome e telefone: o controlador não deve
  // confiar que a tela já validou.
  bool _isInvalid(String name, String phone) =>
      ContactValidators.name(name) != null ||
      ContactValidators.phone(phone) != null;

  bool _phoneInUse(String digits, {String? ignoreId}) =>
      _contacts.any((c) => c.phone == digits && c.id != ignoreId);

  // Id baseado no relógio. O laço garante que não repete, mesmo se dois
  // contatos forem criados no mesmo instante.
  String _newId() {
    var id = DateTime.now().microsecondsSinceEpoch;
    while (_contacts.any((c) => c.id == '$id')) {
      id++;
    }
    return '$id';
  }
}
