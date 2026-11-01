// Guarda a rede de contatos de confiança e aplica as regras dela.
//
// Mesmo padrão do ModeController (Fase 4): um ChangeNotifier que as telas
// assinam. Aqui as regras de negócio ficam juntas e testáveis sem tela:
//   - no máximo 5 contatos;
//   - nome e telefone válidos;
//   - o mesmo telefone não entra duas vezes.
//
// Por enquanto a lista vive só na memória. Gravar no aparelho entra no passo 8.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/validators/contact_validators.dart';

// Motivos pelos quais uma operação pode ser recusada. Um enum deixa claro que
// só existem estes casos, e a tela escolhe a mensagem de cada um.
enum ContactsError { limitReached, duplicatePhone, invalidData, notFound }

class ContactsController extends ChangeNotifier {
  static const maxContacts = 5;

  final List<Contact> _contacts = [];

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
    notifyListeners();
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
    notifyListeners();
    return null;
  }

  ContactsError? remove(String id) {
    final before = _contacts.length;
    _contacts.removeWhere((c) => c.id == id);
    if (_contacts.length == before) return ContactsError.notFound;
    notifyListeners();
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
